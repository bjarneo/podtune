#include "audio.h"

#include <QDataStream>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QtEndian>
#include <algorithm>
#include <cmath>
#include <cstring>

namespace {
double db(double amplitude) { return std::max(-90.0, 20.0 * std::log10(std::max(amplitude, 0.000001))); }
bool isPodMic(const QAudioDevice &device) {
    return device.description().contains("PodMic", Qt::CaseInsensitive)
        || device.id().contains("PodMic");
}
}

void SignalStats::add(float sample) {
    if (!std::isfinite(sample)) return;
    peak = std::max(peak, std::abs(double(sample)));
    sumSquares += double(sample) * sample;
    ++samples;
    if (std::abs(sample) >= 0.999f) ++clipped;
}
double SignalStats::peakDb() const { return db(peak); }
double SignalStats::rmsDb() const { return samples ? db(std::sqrt(sumSquares / samples)) : -90; }

Audio::Audio(QObject *parent, const QString &recordingsDirectory)
    : QObject(parent), m_recordingsDirectory(recordingsDirectory) {
    m_player.setAudioOutput(&m_output);
    m_output.setVolume(0.5);
    connect(&m_player, &QMediaPlayer::playbackStateChanged, this, [this] { emit changed(); emit progressChanged(); });
    connect(&m_player, &QMediaPlayer::positionChanged, this, &Audio::progressChanged);
    connect(&m_player, &QMediaPlayer::errorOccurred, this, [this](auto, const QString &message) {
        m_error = "Cannot play this voice test: " + message; emit changed();
    });
    connect(&m_devices, &QMediaDevices::audioInputsChanged, this, [this] {
        if (!active()) return;
        bool found = false;
        for (const auto &device : QMediaDevices::audioInputs()) if (isPodMic(device)) found = true;
        if (!found) {
            stopRecord(); stopMeter(); m_error = "The PodMic USB disconnected. Reconnect it to start another voice test.";
            emit changed();
        }
    });
    connect(&m_devices, &QMediaDevices::audioOutputsChanged, this, [this] {
        if (!playing()) return;
        bool found = false;
        for (const auto &device : QMediaDevices::audioOutputs()) {
            if (isPodMic(device) && device.id() == m_output.device().id()) found = true;
        }
        if (!found) {
            stopPlayback(); m_error = "The PodMic USB headphone output disconnected. Reconnect it before playback.";
            emit changed();
        }
    });
    connect(&m_output, &QAudioOutput::deviceChanged, this, [this] {
        if (playing() && !isPodMic(m_output.device())) {
            stopPlayback(); m_error = "The PodMic USB headphone output is unavailable. Playback stopped.";
            emit changed();
        }
    });
    m_meterTimer.setInterval(50);
    connect(&m_meterTimer, &QTimer::timeout, this, [this] {
        m_peakDb = m_interval.peakDb(); m_rmsDb = m_interval.rmsDb();
        m_waveform.append(std::min(1.0, m_interval.peak));
        while (m_waveform.size() > 100) m_waveform.removeFirst();
        m_interval = {};
        emit levelsChanged();
        if (recording() && m_recordClock.elapsed() >= 60000) stopRecord();
    });
    loadTakes();
}

Audio::~Audio() { stopRecord(); stopMeter(); }

QString Audio::recordingsPath() const {
    if (!m_recordingsDirectory.isEmpty()) return m_recordingsDirectory;
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/podtune/recordings";
}

bool Audio::startMeter() {
    if (active()) return true;
    m_error.clear();
    QAudioDevice selected;
    for (const auto &device : QMediaDevices::audioInputs()) {
        if (isPodMic(device) && !device.description().contains("Monitor", Qt::CaseInsensitive)) {
            selected = device; break;
        }
    }
    if (selected.isNull()) { m_error = "No PodMic USB audio input is available."; emit changed(); return false; }
    m_format.setSampleRate(48000); m_format.setChannelCount(1); m_format.setSampleFormat(QAudioFormat::Float);
    if (!selected.isFormatSupported(m_format)) m_format = selected.preferredFormat();
    m_source = std::make_unique<QAudioSource>(selected, m_format);
    // PipeWire delivers 1024-frame blocks. A buffer shorter than one block drops audio on each cycle.
    // 200 ms also absorbs interface stalls. Data still arrives every block, so the meter stays smooth.
    m_source->setBufferSize(m_format.bytesForDuration(200000));
    connect(m_source.get(), &QAudioSource::stateChanged, this, [this](QAudio::State state) {
        if (state == QAudio::StoppedState && m_source && m_source->error() != QAudio::NoError) {
            m_error = "The microphone audio stream stopped. Stop the level check, then start it again.";
            if (recording()) stopRecord();
            emit changed();
        }
    });
    m_input = m_source->start();
    if (!m_input) { m_source.reset(); m_error = "Cannot open the PodMic USB audio stream."; emit changed(); return false; }
    connect(m_input, &QIODevice::readyRead, this, &Audio::consume);
    m_remainder.clear(); m_waveform.clear(); m_interval = {}; m_capturedSamples = 0;
    m_meterTimer.start(); emit changed(); return true;
}

void Audio::stopMeter() {
    if (recording()) stopRecord();
    m_meterTimer.stop();
    if (m_input) disconnect(m_input, nullptr, this, nullptr);
    m_input = nullptr;
    if (m_source) m_source->stop();
    m_source.reset(); m_remainder.clear(); m_peakDb = m_rmsDb = -90;
    emit changed(); emit levelsChanged();
}

void Audio::toggleMeter() { if (active()) stopMeter(); else startMeter(); }

void Audio::consume() {
    if (!m_input) return;
    m_remainder += m_input->readAll();
    const int bytesPerSample = m_format.bytesPerSample();
    const int frameSize = m_format.bytesPerFrame();
    if (frameSize <= 0) return;
    const int frames = m_remainder.size() / frameSize;
    QByteArray pcm;
    if (recording()) pcm.reserve(frames * 2);
    for (int i = 0; i < frames; ++i) {
        double sum = 0;
        for (int channel = 0; channel < m_format.channelCount(); ++channel) {
            const char *p = m_remainder.constData() + i * frameSize + channel * bytesPerSample;
            switch (m_format.sampleFormat()) {
            case QAudioFormat::Float: { float value; std::memcpy(&value, p, 4); sum += value; break; }
            case QAudioFormat::Int16: sum += qFromLittleEndian<qint16>(p) / 32768.0; break;
            case QAudioFormat::Int32: sum += qFromLittleEndian<qint32>(p) / 2147483648.0; break;
            case QAudioFormat::UInt8: sum += (quint8(*p) - 128) / 128.0; break;
            default: break;
            }
        }
        const float value = float(sum / m_format.channelCount());
        ++m_capturedSamples;
        m_interval.add(value);
        if (recording()) {
            m_takeStats.add(value);
            char packed[2];
            qToLittleEndian<qint16>(qint16(std::lround(std::clamp(std::isfinite(value) ? value : 0.0f, -1.0f, 1.0f) * 32767)), packed);
            pcm.append(packed, 2);
        }
    }
    m_remainder.remove(0, frames * frameSize);
    if (recording() && !pcm.isEmpty()) {
        if (m_file->write(pcm) != pcm.size()) {
            m_error = "Cannot save the voice test: " + m_file->errorString();
            m_file->cancelWriting(); m_file.reset(); emit changed();
        } else m_written += pcm.size();
    }
}

QByteArray Audio::wavHeader(quint32 size, quint32 rate) {
    QByteArray header;
    QDataStream out(&header, QIODevice::WriteOnly);
    out.setByteOrder(QDataStream::LittleEndian);
    out.writeRawData("RIFF", 4); out << quint32(36 + size);
    out.writeRawData("WAVEfmt ", 8); out << quint32(16) << quint16(1) << quint16(1);
    out << rate << quint32(rate * 2) << quint16(2) << quint16(16);
    out.writeRawData("data", 4); out << size;
    return header;
}

void Audio::toggleRecord() {
    if (recording()) { stopRecord(); return; }
    stopPlayback();
    if (!startMeter()) return;
    QDir().mkpath(recordingsPath());
    m_currentPath = recordingsPath() + "/" + QDateTime::currentDateTime().toString("yyyyMMdd-HHmmss-zzz") + ".wav";
    m_file = std::make_unique<QSaveFile>(m_currentPath);
    if (!m_file->open(QIODevice::WriteOnly) || m_file->write(wavHeader(0, m_format.sampleRate())) != 44) {
        m_error = "Cannot create the voice test file: " + m_file->errorString(); m_file.reset(); emit changed(); return;
    }
    m_error.clear(); m_written = 0; m_takeStats = {}; m_currentLabel = m_takeLabel; m_recordClock.start();
    emit changed(); emit levelsChanged();
}

void Audio::stopRecord() {
    if (!recording()) return;
    consume();
    if (!recording()) return;
    if (!m_file->seek(0) || m_file->write(wavHeader(quint32(m_written), m_format.sampleRate())) != 44 || !m_file->commit()) {
        m_error = "Cannot finish the voice test: " + m_file->errorString(); m_file.reset(); emit changed(); return;
    }
    m_file.reset();
    const QVariantMap metadata{
        {"name", QDateTime::currentDateTime().toString("ddd HH:mm:ss")},
        {"path", m_currentPath}, {"duration", m_written / (2.0 * m_format.sampleRate())},
        {"peak", m_takeStats.peakDb()}, {"rms", m_takeStats.rmsDb()}, {"clipped", m_takeStats.clipped},
        {"preset", m_currentLabel}
    };
    QSaveFile meta(m_currentPath + ".json");
    if (!meta.open(QIODevice::WriteOnly)
        || meta.write(QJsonDocument(QJsonObject::fromVariantMap(metadata)).toJson()) < 0 || !meta.commit()) {
        m_error = "The audio file is saved, but the app cannot save its measurements.";
    }
    loadTakes(); emit changed(); emit levelsChanged();
}

double Audio::duration() const { return recording() ? m_recordClock.elapsed() / 1000.0 : 0; }

double Audio::playProgress() const {
    if (!playing() || m_player.duration() <= 0) return 0;
    return std::clamp(double(m_player.position()) / m_player.duration(), 0.0, 1.0);
}

void Audio::setTakeLabel(const QString &label) {
    if (label == m_takeLabel) return;
    m_takeLabel = label; emit takeLabelChanged();
}

QString Audio::guidance() const {
    if (!active()) return "Start a level check, then speak at your normal volume.";
    if (m_peakDb > -3) return "Too high. Reduce the input gain to leave headroom.";
    if (m_peakDb < -45) return "No speech or a low signal. Speak closer to the microphone.";
    if (m_peakDb < -18) return "Low signal level. For speech, move closer or increase the input gain.";
    if (m_peakDb > -6) return "High signal level. Reduce the input gain to leave more headroom.";
    return "The signal is within the target range of −18 to −6 dBFS.";
}

void Audio::loadTakes() {
    m_takes.clear();
    const auto names = QDir(recordingsPath()).entryList({"*.wav"}, QDir::Files, QDir::Name | QDir::Reversed);
    for (const auto &name : names) {
        const QString path = recordingsPath() + "/" + name;
        QFile meta(path + ".json");
        QVariantMap entry;
        if (meta.open(QIODevice::ReadOnly)) entry = QJsonDocument::fromJson(meta.readAll()).object().toVariantMap();
        entry["path"] = path;
        if (!entry.contains("name")) entry["name"] = name;
        m_takes.append(entry);
    }
    emit takesChanged();
}

void Audio::playTake(int index) {
    if (index < 0 || index >= m_takes.size() || recording()) return;
    if (playing() && index == m_playingTake) { stopPlayback(); return; }
    QAudioDevice selected;
    for (const auto &device : QMediaDevices::audioOutputs()) if (isPodMic(device)) { selected = device; break; }
    if (selected.isNull()) {
        m_error = "Connect headphones to the PodMic USB. Its headphone audio output is unavailable.";
        emit changed(); return;
    }
    m_output.setDevice(selected); m_error.clear(); m_playingTake = index;
    m_player.setSource(QUrl::fromLocalFile(m_takes.at(index).toMap().value("path").toString()));
    m_player.play(); emit changed();
}

void Audio::stopPlayback() { m_player.stop(); m_playingTake = -1; emit changed(); }

void Audio::deleteTake(int index) {
    if (index < 0 || index >= m_takes.size() || recording()) return;
    stopPlayback();
    const QString path = m_takes.at(index).toMap().value("path").toString();
    if (!QFile::moveToTrash(path)) { m_error = "Cannot move the voice test to the trash."; emit changed(); return; }
    if (QFile::exists(path + ".json")) QFile::moveToTrash(path + ".json");
    loadTakes();
}

void Audio::openRecordings() { QDir().mkpath(recordingsPath()); QDesktopServices::openUrl(QUrl::fromLocalFile(recordingsPath())); }

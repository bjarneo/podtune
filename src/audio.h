#pragma once

#include <QAudioOutput>
#include <QAudioSource>
#include <QElapsedTimer>
#include <QMediaDevices>
#include <QMediaPlayer>
#include <QObject>
#include <QSaveFile>
#include <QTimer>
#include <QVariantList>
#include <memory>

struct SignalStats {
    double peak = 0;
    double sumSquares = 0;
    qint64 samples = 0;
    qint64 clipped = 0;
    void add(float sample);
    double peakDb() const;
    double rmsDb() const;
};

class Audio : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(bool recording READ recording NOTIFY changed)
    Q_PROPERTY(bool playing READ playing NOTIFY changed)
    Q_PROPERTY(double peakDb READ peakDb NOTIFY levelsChanged)
    Q_PROPERTY(double rmsDb READ rmsDb NOTIFY levelsChanged)
    Q_PROPERTY(QVariantList waveform READ waveform NOTIFY levelsChanged)
    Q_PROPERTY(QString guidance READ guidance NOTIFY levelsChanged)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(QVariantList takes READ takes NOTIFY takesChanged)
    Q_PROPERTY(int playingTake READ playingTake NOTIFY changed)
    Q_PROPERTY(double duration READ duration NOTIFY levelsChanged)
    Q_PROPERTY(double playProgress READ playProgress NOTIFY progressChanged)
    Q_PROPERTY(QString takeLabel READ takeLabel WRITE setTakeLabel NOTIFY takeLabelChanged)
public:
    explicit Audio(QObject *parent = nullptr, const QString &recordingsDirectory = {});
    ~Audio() override;
    bool active() const { return bool(m_source); }
    bool recording() const { return bool(m_file); }
    bool playing() const { return m_player.playbackState() == QMediaPlayer::PlayingState; }
    double peakDb() const { return m_peakDb; }
    double rmsDb() const { return m_rmsDb; }
    QVariantList waveform() const { return m_waveform; }
    QString guidance() const;
    QString error() const { return m_error; }
    QVariantList takes() const { return m_takes; }
    int playingTake() const { return m_playingTake; }
    double duration() const;
    double playProgress() const;
    QString takeLabel() const { return m_takeLabel; }
    void setTakeLabel(const QString &label);
    qint64 capturedSamples() const { return m_capturedSamples; }
    Q_INVOKABLE void toggleMeter();
    Q_INVOKABLE void toggleRecord();
    Q_INVOKABLE void playTake(int index);
    Q_INVOKABLE void deleteTake(int index);
    Q_INVOKABLE void stopPlayback();
    Q_INVOKABLE void openRecordings();
    static QByteArray wavHeader(quint32 dataBytes, quint32 rate);
signals:
    void changed();
    void levelsChanged();
    void takesChanged();
    void progressChanged();
    void takeLabelChanged();
private:
    bool startMeter();
    void stopMeter();
    void consume();
    void stopRecord();
    void loadTakes();
    QString recordingsPath() const;
    QMediaDevices m_devices;
    std::unique_ptr<QAudioSource> m_source;
    QIODevice *m_input = nullptr;
    QAudioFormat m_format;
    QMediaPlayer m_player;
    QAudioOutput m_output;
    std::unique_ptr<QSaveFile> m_file;
    QString m_currentPath, m_currentLabel, m_takeLabel, m_error, m_recordingsDirectory;
    QByteArray m_remainder;
    SignalStats m_interval, m_takeStats;
    QVariantList m_waveform, m_takes;
    QTimer m_meterTimer;
    QElapsedTimer m_recordClock;
    qint64 m_written = 0;
    qint64 m_capturedSamples = 0;
    int m_playingTake = -1;
    double m_peakDb = -90, m_rmsDb = -90;
};

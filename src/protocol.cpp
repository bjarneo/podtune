#include "protocol.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QtEndian>
#include <alsa/asoundlib.h>
#include <algorithm>
#include <cmath>
#include <fcntl.h>
#include <poll.h>
#include <unistd.h>

namespace {
constexpr double q31 = 2147483648.0;
QString readText(const QString &path) {
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()).trimmed() : QString();
}
double normalized(const Control &c, double v) {
    if (c.key == "compAttack") return std::log10(v / 0.1) / 2.0;
    if (c.key == "compRelease") return std::log(v / 5.0) / std::log(40.0);
    if (c.key == "compThreshold") return -v / 60.0;
    return (v - c.minimum) / (c.maximum - c.minimum);
}
double denormalized(const Control &c, double n) {
    if (c.key == "compAttack") return 0.1 * std::pow(10.0, 2.0 * n);
    if (c.key == "compRelease") return 5.0 * std::pow(40.0, n);
    if (c.key == "compThreshold") return -n * 60.0;
    return c.minimum + n * (c.maximum - c.minimum);
}
}

Codec::Codec() {
    QFile file(":/dsp_luts.json");
    if (file.open(QIODevice::ReadOnly)) m_tables = QJsonDocument::fromJson(file.readAll()).object();
}

const QList<Control> &Codec::controls() {
    static const QList<Control> controls{
        {"gain", -2, 0, 22, 63},
        {"headphones", -2, 1, -60, 0},
        {"hpf", -1, 1, 0, 1, true},
        {"directMonitor", -1, 3, 0, 1, true},
        {"monitorMix", -1, 4, 0, 255},
        {"mute", -1, 8, 0, 1, true},
        {"compressor", 0, 0, 0, 1, true},
        {"compThreshold", 0, 1, -60, 0, false, "CompThreshold"},
        {"compRatio", 0, 2, 1.5, 4.5},
        {"compAttack", 0, 3, 0.1, 10, false, "CompAttack"},
        {"compRelease", 0, 4, 5, 200, false, "CompRelease"},
        {"compGain", 0, 5, 0, 9, false, "CompGain"},
        {"gateThreshold", 1, 1, -100, 0},
        {"gateAttack", 1, 3, 1, 2000},
        {"gateRelease", 1, 4, 1, 4000},
        {"exciter", 2, 0, 0, 1, true},
        {"exciterMix", 2, 1, 0, 100, false, "AEMix"},
        {"exciterTune", 2, 2, 600, 5000, false, "AETune_a"},
        {"bottom", 3, 0, 0, 1, true},
        {"bottomDrive", 3, 1, 0, 100, false, "AEMix"}
    };
    return controls;
}

const Control *Codec::find(const QString &key) {
    for (const auto &c : controls()) if (c.key == key) return &c;
    return nullptr;
}

bool Codec::ready() const {
    for (const auto &c : controls()) {
        if (!c.table.isEmpty() && m_tables.value(c.table).toArray().size() != 256) return false;
    }
    return true;
}

QByteArray Codec::encode(const Control &c, double value) const {
    value = std::clamp(value, c.minimum, c.maximum);
    if (c.boolean || c.effect == -1) return QByteArray(1, char(std::lround(value)));
    qint32 raw = 0;
    if (!c.table.isEmpty()) {
        int index = std::clamp(int(std::lround(normalized(c, value) * 255)), 0, 255);
        raw = qint32(m_tables.value(c.table).toArray().at(index).toDouble());
    } else if (c.key == "compRatio") {
        raw = qint32(std::lround(normalized(c, value) * 255));
    } else if (c.key == "gateThreshold") {
        raw = qint32(std::clamp(std::round(std::pow(10.0, value / 20.0) * q31), 0.0, q31 - 1));
    } else {
        raw = qint32(std::clamp(std::round(-std::expm1(-1.0 / (value * 48.0)) * q31), 0.0, q31 - 1));
    }
    QByteArray result(4, '\0');
    qToLittleEndian<qint32>(raw, result.data());
    return result;
}

double Codec::decode(const Control &c, const QByteArray &bytes) const {
    if (c.boolean || c.effect == -1) return quint8(bytes.at(0));
    const qint32 raw = qFromLittleEndian<qint32>(bytes.constData());
    if (!c.table.isEmpty()) {
        const auto table = m_tables.value(c.table).toArray();
        int closest = 0;
        double distance = std::numeric_limits<double>::max();
        for (int i = 0; i < table.size(); ++i) {
            double d = std::abs(table.at(i).toDouble() - raw);
            if (d < distance) { distance = d; closest = i; }
        }
        return denormalized(c, closest / 255.0);
    }
    if (c.key == "compRatio") return denormalized(c, raw / 255.0);
    if (c.key == "gateThreshold") return 20.0 * std::log10(std::max(1.0, double(raw)) / q31);
    return raw > 0 && raw < q31 ? -1.0 / (48.0 * std::log1p(-raw / q31)) : 0;
}

bool Codec::validReply(const QByteArray &r, int report, int selector, int dataSize) {
    return r.size() >= 3 + dataSize && quint8(r[0]) == report
        && quint8(r[1]) == selector && quint8(r[2]) == 0x41;
}

QVariantMap Codec::matchingTargets(const QVariantMap &actual, const QVariantMap &requested) const {
    QVariantMap completed;
    for (auto it = actual.begin(); it != actual.end(); ++it) {
        const auto *c = find(it.key());
        if (!c || !requested.contains(it.key())) continue;
        const double value = it.value().toDouble();
        const double target = requested.value(it.key()).toDouble();
        if (!std::isfinite(value) || !std::isfinite(target)) continue;
        const bool matches = c->effect == -2 ? std::abs(value - target) < 0.51
            : encode(*c, value) == encode(*c, target);
        if (matches) completed[it.key()] = it.value();
    }
    return completed;
}

Hardware::Hardware(QObject *parent) : QObject(parent) {}
Hardware::~Hardware() { shutdown(); }
void Hardware::shutdown() { if (m_fd >= 0) ::close(m_fd); m_fd = -1; }

bool Hardware::connectDevice() {
    shutdown();
    m_error.clear();
    m_card.clear();
    m_identity = "RØDE PodMic USB is not connected";
    for (const auto &entry : QDir("/proc/asound").entryList({"card*"}, QDir::Dirs)) {
        const QString mixer = readText("/proc/asound/" + entry + "/usbmixer");
        if (mixer.contains("usb_id=0x19f7004a")) { m_card = entry.mid(4); break; }
    }
    for (const auto &entry : QDir("/sys/class/hidraw").entryList({"hidraw*"}, QDir::Dirs)) {
        const QString device = "/sys/class/hidraw/" + entry + "/device";
        if (!readText(device + "/uevent").contains("000019F7:0000004A", Qt::CaseInsensitive)) continue;
        QString parent = QFileInfo(device).canonicalFilePath();
        QString firmware;
        while (!parent.isEmpty() && parent != "/") {
            firmware = readText(parent + "/bcdDevice");
            if (!firmware.isEmpty()) break;
            parent = QFileInfo(parent).absolutePath();
        }
        const QString version = firmware == "0119" ? "1.19" : firmware;
        m_identity = "RØDE PodMic USB · firmware " + version + " · 48 kHz";
        if (firmware != "0119") {
            m_error = "This firmware has no verified DSP map. Standard gain and headphone controls remain available.";
            return false;
        }
        const QString path = "/dev/" + entry;
        m_fd = ::open(path.toLocal8Bit().constData(), O_RDWR | O_NONBLOCK | O_CLOEXEC);
        if (m_fd < 0) {
            m_error = "Cannot access " + path + ". Run bin/enable-device-access, then select Refresh.";
            return false;
        }
        if (!m_codec.ready()) { m_error = "The DSP coefficient tables are missing."; shutdown(); return false; }
        return true;
    }
    m_error = "Connect the RØDE PodMic USB, then select Refresh.";
    return false;
}

QByteArray Hardware::exchange(int report, int size, int selector, int op, int parameter,
                             const QByteArray &value, int replyReport, int dataSize) {
    if (m_fd < 0) return {};
    char incoming[64];
    while (::read(m_fd, incoming, sizeof(incoming)) > 0) {}
    QByteArray frame(size + 1, '\0');
    frame[0] = char(report);
    frame[1] = char(selector);
    frame[2] = char(op);
    if (report == 4) {
        frame[3] = char(parameter);
        frame.replace(4, value.size(), value);
    } else {
        frame.replace(3, value.size(), value);
    }
    if (::write(m_fd, frame.constData(), size_t(frame.size())) != frame.size()) {
        m_error = "The microphone disconnected or rejected the USB transfer.";
        shutdown();
        return {};
    }
    QElapsedTimer deadline;
    deadline.start();
    const int timeout = report == 8 ? 2000 : 500;
    while (deadline.elapsed() < timeout) {
        pollfd poller{m_fd, POLLIN, 0};
        const int result = ::poll(&poller, 1, timeout - int(deadline.elapsed()));
        if (result < 0 && errno == EINTR) continue;
        if (result <= 0) break;
        if (poller.revents & (POLLERR | POLLHUP | POLLNVAL)) { shutdown(); break; }
        const auto n = ::read(m_fd, incoming, sizeof(incoming));
        if (n <= 0) continue;
        const QByteArray reply(incoming, n);
        if (Codec::validReply(reply, replyReport, selector, dataSize)) {
            return dataSize == 0 ? QByteArray(1, '\0') : reply.mid(3);
        }
        if (reply.size() >= 3 && quint8(reply[0]) == replyReport && quint8(reply[1]) == selector) {
            m_error = "The microphone rejected a control command.";
            return {};
        }
    }
    m_error = "The microphone did not reply. Select Refresh to reconnect.";
    return {};
}

bool Hardware::mixer(const Control &c, double &value, bool write) {
    if (m_card.isEmpty()) return false;
    snd_ctl_t *handle = nullptr;
    if (snd_ctl_open(&handle, ("hw:" + m_card).toLocal8Bit().constData(), 0) < 0) return false;
    snd_ctl_elem_id_t *id;
    snd_ctl_elem_id_alloca(&id);
    snd_ctl_elem_id_set_interface(id, SND_CTL_ELEM_IFACE_MIXER);
    snd_ctl_elem_id_set_name(id, c.key == "gain" ? "Mic Capture Volume" : "PCM Playback Volume");
    snd_ctl_elem_value_t *data;
    snd_ctl_elem_value_alloca(&data);
    snd_ctl_elem_value_set_id(data, id);
    bool ok = snd_ctl_elem_read(handle, data) >= 0;
    if (ok && write) {
        long raw = 0;
        ok = snd_ctl_convert_from_dB(handle, id, long(std::lround(value * 100)), &raw, 0) >= 0;
        if (ok) {
            snd_ctl_elem_value_set_integer(data, 0, raw);
            ok = snd_ctl_elem_write(handle, data) >= 0;
        }
    }
    if (ok) {
        ok = snd_ctl_elem_read(handle, data) >= 0;
        long db = 0;
        if (ok) ok = snd_ctl_convert_to_dB(handle, id, snd_ctl_elem_value_get_integer(data, 0), &db) >= 0;
        if (ok) value = db / 100.0;
    }
    snd_ctl_close(handle);
    return ok;
}

bool Hardware::readControl(const Control &c, double &value) {
    if (c.effect == -2) return mixer(c, value, false);
    const auto data = c.effect == -1
        ? exchange(8, 27, c.parameter, 1, 0, {}, 7, 1)
        : exchange(4, 28, c.effect, 3, c.parameter, {}, 3, c.boolean ? 1 : 4);
    if (data.isEmpty()) return false;
    value = m_codec.decode(c, data);
    return std::isfinite(value) && value >= c.minimum - 0.5 && value <= c.maximum + 0.5;
}

bool Hardware::writeControl(const Control &c, double value) {
    if (c.effect == -2) return mixer(c, value, true);
    const auto bytes = m_codec.encode(c, value);
    return !(c.effect == -1 ? exchange(8, 27, c.parameter, 0, 0, bytes, 7, 0)
                           : exchange(4, 28, c.effect, 2, c.parameter, bytes, 3, 0)).isNull();
}

void Hardware::refresh() {
    connectDevice();
    QVariantMap values, supported;
    for (const auto &c : Codec::controls()) {
        double value = 0;
        const bool ok = (c.effect == -2 || m_fd >= 0) && readControl(c, value);
        supported[c.key] = ok;
        if (ok) values[c.key] = c.boolean ? QVariant(bool(value)) : QVariant(value);
    }
    emit stateRead(values, supported, m_identity, m_error);
}

void Hardware::apply(const QVariantMap &requested) {
    QVariantMap before, after, actualValues, supported;
    QStringList failures;
    // Parameter changes precede effect switches to avoid a transient level change.
    QList<Control> order = Codec::controls();
    std::stable_sort(order.begin(), order.end(), [](const Control &a, const Control &b) {
        return !a.boolean && b.boolean;
    });
    for (const auto &c : order) {
        if (!requested.contains(c.key)) continue;
        const double target = requested[c.key].toDouble();
        if (!std::isfinite(target) || target < c.minimum || target > c.maximum) {
            failures << c.key + ": invalid value";
            continue;
        }
        double old = 0;
        if (!readControl(c, old)) {
            supported[c.key] = false;
            failures << c.key + ": cannot read the current value"; continue;
        }
        const bool acknowledged = writeControl(c, target);
        double actual = 0;
        if (!readControl(c, actual)) {
            supported[c.key] = false;
            failures << c.key + ": cannot verify the write. Select Refresh to read the hardware state."; continue;
        }
        supported[c.key] = true;
        actualValues[c.key] = c.boolean ? QVariant(bool(actual)) : QVariant(actual);
        before[c.key] = c.boolean ? QVariant(bool(old)) : QVariant(old);
        after[c.key] = actualValues[c.key];
        if (!acknowledged) failures << c.key + ": no write ACK. The app shows the current read-back value.";
        if (c.effect != -2 && m_codec.encode(c, actual) != m_codec.encode(c, target)) {
            failures << c.key + ": read-back differs";
        }
    }
    emit reconciled(actualValues, supported);
    emit applied(before, after, failures.join("\n"));
}

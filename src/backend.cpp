#include "backend.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <cmath>

Backend::Backend(QObject *parent) : QObject(parent), m_hardware(new Hardware) {
    m_hardware->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, m_hardware, &QObject::deleteLater);
    connect(m_hardware, &Hardware::stateRead, this, [this](QVariantMap v, QVariantMap s, QString id, QString error) {
        m_values = v; m_supported = s; m_identity = id; m_error = error; m_connectionError = error; m_busy = false;
        m_inFlight.clear();
        m_undo.clear(); m_redo.clear();
        m_notice = error.isEmpty() ? "Hardware state loaded. Changes apply to the microphone." : QString();
        emit changed();
    });
    connect(m_hardware, &Hardware::reconciled, this, [this](QVariantMap values, QVariantMap supported) {
        for (auto it = supported.begin(); it != supported.end(); ++it) {
            m_supported[it.key()] = it.value();
            if (it.value().toBool()) m_values[it.key()] = values.value(it.key());
            else m_values.remove(it.key());
        }
        emit changed();
    });
    connect(m_hardware, &Hardware::applied, this, [this](QVariantMap before, QVariantMap after, QString error) {
        for (auto it = after.begin(); it != after.end(); ++it) m_values[it.key()] = it.value();
        const auto completed = m_codec.matchingTargets(after, m_inFlight);
        QVariantMap completedBefore;
        for (auto it = completed.begin(); it != completed.end(); ++it) completedBefore[it.key()] = before.value(it.key());
        if (!after.isEmpty()) {
            if (m_historyMode == 1) {
                if (!m_undo.isEmpty()) {
                    for (auto it = completed.begin(); it != completed.end(); ++it) {
                        m_undo.last().before.remove(it.key()); m_undo.last().after.remove(it.key());
                    }
                    if (m_undo.last().before.isEmpty()) m_undo.removeLast();
                }
                if (!completed.isEmpty()) m_redo.append({completed, completedBefore});
            } else if (m_historyMode == 2) {
                if (!m_redo.isEmpty()) {
                    for (auto it = completed.begin(); it != completed.end(); ++it) {
                        m_redo.last().before.remove(it.key()); m_redo.last().after.remove(it.key());
                    }
                    if (m_redo.last().after.isEmpty()) m_redo.removeLast();
                }
                if (!completed.isEmpty()) m_undo.append({completedBefore, completed});
            } else { m_undo.append({before, after}); m_redo.clear(); }
        }
        m_historyMode = 0;
        m_inFlight.clear();
        m_error = error.isEmpty() ? m_connectionError : error; m_busy = false;
        m_notice = error.isEmpty() ? "The microphone confirms the new settings." : "The app reports each failed control below.";
        emit changed();
        if (!m_pending.isEmpty()) m_debounce.start();
    });
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(160);
    connect(&m_debounce, &QTimer::timeout, this, [this] {
        if (m_busy) { m_debounce.start(); return; }
        const auto pending = m_pending;
        m_pending.clear();
        send(pending);
    });
    loadPresets();
    m_thread.start();
    QTimer::singleShot(0, this, &Backend::refresh);
}

Backend::~Backend() {
    m_debounce.stop();
    const auto pending = m_pending;
    QMetaObject::invokeMethod(m_hardware, [this, pending] {
        if (!pending.isEmpty()) m_hardware->apply(pending);
        m_hardware->shutdown();
    }, Qt::BlockingQueuedConnection);
    m_thread.quit();
    m_thread.wait();
}

void Backend::refresh() {
    if (m_busy) return;
    m_pending.clear(); m_debounce.stop();
    m_busy = true; m_error.clear(); emit changed();
    QMetaObject::invokeMethod(m_hardware, [this] { m_hardware->refresh(); }, Qt::QueuedConnection);
}

void Backend::setControl(const QString &key, double value) {
    const auto *c = Codec::find(key);
    if (!c || !m_supported.value(key).toBool() || !std::isfinite(value)) return;
    m_pending[key] = std::clamp(value, c->minimum, c->maximum);
    m_debounce.start();
    emit changed();
}

QVariantMap Backend::previewValues() const {
    auto result = m_values;
    for (auto it = m_inFlight.begin(); it != m_inFlight.end(); ++it) result[it.key()] = it.value();
    for (auto it = m_pending.begin(); it != m_pending.end(); ++it) result[it.key()] = it.value();
    return result;
}

QVariantList Backend::presetMatches() const {
    const auto current = previewValues();
    QVariantList result;
    for (const auto &entry : m_presets) {
        const auto values = entry.toMap().value("values").toMap();
        result.append(!values.isEmpty() && m_codec.matchingTargets(current, values).size() == values.size());
    }
    return result;
}

void Backend::send(const QVariantMap &values, int mode) {
    if (values.isEmpty() || m_busy) return;
    m_busy = true; m_historyMode = mode; m_inFlight = values; m_error = m_connectionError; emit changed();
    QMetaObject::invokeMethod(m_hardware, [this, values] { m_hardware->apply(values); }, Qt::QueuedConnection);
}

QString Backend::presetsPath() const {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/podtune/presets.json";
}

void Backend::loadPresets() {
    QFile factory(":/presets.json");
    if (factory.open(QIODevice::ReadOnly)) m_presets = QJsonDocument::fromJson(factory.readAll()).array().toVariantList();
    QFile user(presetsPath());
    if (user.open(QIODevice::ReadOnly)) m_presets += QJsonDocument::fromJson(user.readAll()).array().toVariantList();
    emit presetsChanged();
}

void Backend::applyPreset(int index) {
    if (m_busy || index < 0 || index >= m_presets.size()) return;
    const auto values = m_presets.at(index).toMap().value("values").toMap();
    QVariantMap validated;
    for (auto it = values.begin(); it != values.end(); ++it) {
        const auto *c = Codec::find(it.key());
        bool numeric = false;
        const double number = it.value().toDouble(&numeric);
        if (!c || !numeric || !std::isfinite(number) || number < c->minimum || number > c->maximum) {
            m_error = "The preset contains an invalid control: " + it.key(); emit changed(); return;
        }
        if (!m_supported.value(it.key()).toBool()) {
            m_error = "The preset requires unavailable hardware controls. Enable device access, then select Refresh.";
            emit changed(); return;
        }
        validated[it.key()] = number;
    }
    m_pending.clear(); m_debounce.stop();
    send(validated);
}

void Backend::savePreset(const QString &name) {
    if (m_busy || m_values.isEmpty() || name.trimmed().isEmpty()) return;
    if (!m_pending.isEmpty()) { m_error = "Wait for the last hardware change before you save a preset."; emit changed(); return; }
    const QString title = name.trimmed().left(64);
    for (const auto &entry : m_presets) {
        if (entry.toMap().value("name").toString().compare(title, Qt::CaseInsensitive) == 0) {
            m_error = "This preset name already exists. Choose another name."; emit changed(); return;
        }
    }
    QVariantList saved;
    for (const auto &entry : m_presets) if (!entry.toMap().value("factory").toBool()) saved.append(entry);
    saved.append(QVariantMap{{"name", title}, {"description", "Your saved hardware settings"}, {"factory", false}, {"values", m_values}});
    QDir().mkpath(QFileInfo(presetsPath()).absolutePath());
    QSaveFile file(presetsPath());
    if (!file.open(QIODevice::WriteOnly)
        || file.write(QJsonDocument(QJsonArray::fromVariantList(saved)).toJson()) < 0 || !file.commit()) {
        m_error = "Cannot save the preset: " + file.errorString(); emit changed(); return;
    }
    loadPresets(); m_error = m_connectionError; m_notice = "Preset saved: " + title; emit changed();
}

void Backend::undo() { if (!busy() && !m_undo.isEmpty()) send(m_undo.last().before, 1); }
void Backend::redo() { if (!busy() && !m_redo.isEmpty()) send(m_redo.last().after, 2); }

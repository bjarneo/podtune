#pragma once

#include <QObject>
#include <QThread>
#include <QTimer>
#include <QVariantList>
#include "protocol.h"

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QVariantMap previewValues READ previewValues NOTIFY changed)
    Q_PROPERTY(QVariantMap supported READ supported NOTIFY changed)
    Q_PROPERTY(QVariantList presets READ presets NOTIFY presetsChanged)
    Q_PROPERTY(QVariantList presetMatches READ presetMatches NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString identity READ identity NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(QString notice READ notice NOTIFY changed)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY changed)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY changed)
public:
    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;
    QVariantMap values() const { return m_values; }
    QVariantMap previewValues() const;
    QVariantMap supported() const { return m_supported; }
    QVariantList presets() const { return m_presets; }
    QVariantList presetMatches() const;
    bool busy() const { return m_busy || !m_pending.isEmpty(); }
    QString identity() const { return m_identity; }
    QString error() const { return m_error; }
    QString notice() const { return m_notice; }
    bool canUndo() const { return !m_undo.isEmpty(); }
    bool canRedo() const { return !m_redo.isEmpty(); }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setControl(const QString &key, double value);
    Q_INVOKABLE void applyPreset(int index);
    Q_INVOKABLE void savePreset(const QString &name);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void redo();
signals:
    void changed();
    void presetsChanged();
private:
    void send(const QVariantMap &values, int historyMode = 0);
    void loadPresets();
    QString presetsPath() const;
    Hardware *m_hardware;
    Codec m_codec;
    QThread m_thread;
    QVariantMap m_values, m_supported, m_pending, m_inFlight;
    QVariantList m_presets;
    struct Edit { QVariantMap before; QVariantMap after; };
    QList<Edit> m_undo, m_redo;
    QTimer m_debounce;
    int m_historyMode = 0;
    bool m_busy = false;
    QString m_identity = "Check the microphone connection";
    QString m_error, m_notice, m_connectionError;
};

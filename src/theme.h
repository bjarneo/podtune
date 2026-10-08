#pragma once
#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>

class Theme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString background READ background NOTIFY changed)
    Q_PROPERTY(QString surface READ surface NOTIFY changed)
    Q_PROPERTY(QString foreground READ foreground NOTIFY changed)
    Q_PROPERTY(QString secondary READ secondary NOTIFY changed)
    Q_PROPERTY(QString border READ border NOTIFY changed)
    Q_PROPERTY(QString accent READ accent NOTIFY changed)
    Q_PROPERTY(QString accentForeground READ accentForeground NOTIFY changed)
    Q_PROPERTY(QString line READ line NOTIFY changed)
    Q_PROPERTY(QString tint READ tint NOTIFY changed)
    Q_PROPERTY(QString high READ high NOTIFY changed)
    Q_PROPERTY(QString scrim READ scrim NOTIFY changed)
    Q_PROPERTY(bool dark READ dark NOTIFY changed)
public:
    explicit Theme(QObject *parent = nullptr);
    QString mode() const { return m_mode; }
    void setMode(const QString &mode);
    QString background() const;
    QString surface() const;
    QString foreground() const;
    QString secondary() const;
    QString border() const;
    QString accent() const;
    QString accentForeground() const;
    QString line() const;
    QString tint() const;
    QString high() const;
    QString scrim() const;
    bool dark() const;
signals:
    void changed();
private:
    void reload();
    QString m_mode, m_bg = "#17191c", m_fg = "#f0f1f3", m_accent = "#d0b675";
    QFileSystemWatcher m_watch;
    QTimer m_debounce;
};

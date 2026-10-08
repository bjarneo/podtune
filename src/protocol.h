#pragma once

#include <QString>
#include <QByteArray>
#include <QJsonObject>
#include <QObject>
#include <QVariantMap>
#include <functional>

struct Control {
    QString key;
    int effect;
    int parameter;
    double minimum;
    double maximum;
    bool boolean = false;
    QString table = {};
};

class Codec {
public:
    Codec();
    static const QList<Control> &controls();
    static const Control *find(const QString &key);
    QByteArray encode(const Control &control, double value) const;
    double decode(const Control &control, const QByteArray &bytes) const;
    QVariantMap matchingTargets(const QVariantMap &actual, const QVariantMap &requested) const;
    static bool validReply(const QByteArray &reply, int report, int selector, int dataSize);
    bool ready() const;
private:
    QJsonObject m_tables;
};

class Hardware : public QObject {
    Q_OBJECT
public:
    explicit Hardware(QObject *parent = nullptr);
    ~Hardware() override;
    void refresh();
    void apply(const QVariantMap &requested);
    void shutdown();
signals:
    void stateRead(QVariantMap values, QVariantMap supported, QString identity, QString error);
    void reconciled(QVariantMap values, QVariantMap supported);
    void applied(QVariantMap before, QVariantMap after, QString error);
private:
    bool connectDevice();
    QByteArray exchange(int report, int payloadSize, int selector, int operation,
                        int parameter, const QByteArray &value, int replyReport, int dataSize);
    bool readControl(const Control &control, double &value);
    bool writeControl(const Control &control, double value);
    bool mixer(const Control &control, double &value, bool write);
    int m_fd = -1;
    QString m_card;
    QString m_identity;
    QString m_error;
    Codec m_codec;
};

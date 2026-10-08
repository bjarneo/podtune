#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QtEndian>
#include <QtTest>
#include <cmath>
#include "audio.h"
#include "protocol.h"

class PodtuneTests : public QObject {
    Q_OBJECT
private slots:
    void initTestCase() { QStandardPaths::setTestModeEnabled(true); }

    void coefficientsAreComplete() {
        Codec codec;
        QVERIFY(codec.ready());
    }

    void rejectUnrelatedAndMalformedReplies() {
        QVERIFY(Codec::validReply(QByteArray::fromHex("03004101000000"), 3, 0, 4));
        QVERIFY(!Codec::validReply(QByteArray::fromHex("05004101000000"), 3, 0, 4));
        QVERIFY(!Codec::validReply(QByteArray::fromHex("03014101000000"), 3, 0, 4));
        QVERIFY(!Codec::validReply(QByteArray::fromHex("03004e01000000"), 3, 0, 4));
        QVERIFY(!Codec::validReply(QByteArray::fromHex("0300410100"), 3, 0, 4));
        QVERIFY(!Codec::validReply({}, 3, 0, 4));
    }

    void encodeKnownProtocolValues() {
        Codec codec;
        QCOMPARE(codec.encode(*Codec::find("hpf"), 1), QByteArray::fromHex("01"));
        QCOMPARE(codec.encode(*Codec::find("monitorMix"), 255), QByteArray::fromHex("ff"));
        QCOMPARE(codec.encode(*Codec::find("compRatio"), 1.5), QByteArray::fromHex("00000000"));
        QCOMPARE(codec.encode(*Codec::find("compRatio"), 4.5), QByteArray::fromHex("ff000000"));
        const auto threshold = codec.encode(*Codec::find("gateThreshold"), -20);
        QCOMPARE(qFromLittleEndian<qint32>(threshold.constData()), qint32(214748365));
        const auto attack = codec.encode(*Codec::find("gateAttack"), 10);
        QCOMPARE(qFromLittleEndian<qint32>(attack.constData()), qint32(std::round((1.0 - std::exp(-1.0 / 480.0)) * 2147483648.0)));
    }

    void preserveQuantizedValuesAcrossAllControlRanges() {
        Codec codec;
        for (const auto &c : Codec::controls()) {
            if (c.effect < -1) continue;
            for (int i = 0; i <= 20; ++i) {
                const double value = c.minimum + (c.maximum - c.minimum) * i / 20;
                const auto encoded = codec.encode(c, value);
                const double decoded = codec.decode(c, encoded);
                QVERIFY2(std::isfinite(decoded), qPrintable(c.key));
                QCOMPARE(codec.encode(c, decoded), encoded);
            }
        }
    }

    void clampControlsAtTheProtocolBoundary() {
        Codec codec;
        for (const auto &c : Codec::controls()) {
            if (c.effect < -1) continue;
            QCOMPARE(codec.encode(c, c.minimum - 100), codec.encode(c, c.minimum));
            QCOMPARE(codec.encode(c, c.maximum + 100), codec.encode(c, c.maximum));
        }
    }

    void failedAndPartialHistoryActionsRetainUnmetTargets() {
        Codec codec;
        const QVariantMap requested{{"gain", 45.0}, {"hpf", true}, {"compRatio", 2.5}};
        QVERIFY(codec.matchingTargets({{"gain", 46.0}, {"hpf", false}, {"compRatio", 3.0}}, requested).isEmpty());
        const auto partial = codec.matchingTargets({{"gain", 45.0}, {"hpf", false}, {"compRatio", 3.0}}, requested);
        QCOMPARE(partial.size(), 1);
        QVERIFY(partial.contains("gain"));
        const auto *ratio = Codec::find("compRatio");
        const double quantizedRatio = codec.decode(*ratio, codec.encode(*ratio, 2.5));
        const auto complete = codec.matchingTargets({{"gain", 45.0}, {"hpf", true}, {"compRatio", quantizedRatio}}, requested);
        QCOMPARE(complete.size(), 3);
        QVERIFY(codec.matchingTargets({{"gain", 45.0}}, {}).isEmpty());
    }

    void presetsContainOnlyVerifiedControls() {
        QFile file(":/presets.json");
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto presets = QJsonDocument::fromJson(file.readAll()).array();
        QCOMPARE(presets.size(), 4);
        for (const auto &entry : presets) {
            const auto values = entry.toObject().value("values").toObject();
            QVERIFY(!values.contains("gain"));
            QVERIFY(!values.contains("headphones"));
            for (auto it = values.begin(); it != values.end(); ++it) {
                const auto *c = Codec::find(it.key());
                QVERIFY2(c, qPrintable(it.key()));
                QVERIFY(it.value().toDouble() >= c->minimum);
                QVERIFY(it.value().toDouble() <= c->maximum);
            }
        }
    }

    void calculateSignalLevelsAndClipping() {
        SignalStats stats;
        for (int i = 0; i < 48000; ++i) stats.add(float(0.5 * std::sin(2 * 3.141592653589793 * 1000 * i / 48000.0)));
        QVERIFY(std::abs(stats.peakDb() + 6.0206) < .001);
        QVERIFY(std::abs(stats.rmsDb() + 9.0309) < .001);
        QCOMPARE(stats.clipped, qint64(0));
        stats.add(1.0); stats.add(-1.0);
        QCOMPARE(stats.clipped, qint64(2));
        QCOMPARE(stats.peakDb(), 0.0);
        const qint64 count = stats.samples;
        stats.add(std::numeric_limits<float>::quiet_NaN());
        QCOMPARE(stats.samples, count);
    }

    void silenceHasFiniteLevels() {
        SignalStats stats;
        QCOMPARE(stats.peakDb(), -90.0);
        QCOMPARE(stats.rmsDb(), -90.0);
        stats.add(0);
        QCOMPARE(stats.rmsDb(), -90.0);
    }

    void writeAStandardMonoPcmWavHeader() {
        const auto header = Audio::wavHeader(96000, 48000);
        QCOMPARE(header.size(), 44);
        QCOMPARE(header.left(4), QByteArray("RIFF"));
        QCOMPARE(qFromLittleEndian<quint32>(header.constData() + 4), quint32(96036));
        QCOMPARE(header.mid(8, 8), QByteArray("WAVEfmt "));
        QCOMPARE(qFromLittleEndian<quint16>(header.constData() + 20), quint16(1));
        QCOMPARE(qFromLittleEndian<quint16>(header.constData() + 22), quint16(1));
        QCOMPARE(qFromLittleEndian<quint32>(header.constData() + 24), quint32(48000));
        QCOMPARE(qFromLittleEndian<quint16>(header.constData() + 34), quint16(16));
        QCOMPARE(header.mid(36, 4), QByteArray("data"));
        QCOMPARE(qFromLittleEndian<quint32>(header.constData() + 40), quint32(96000));
    }

    void recordAndPlayOnTheRealMicrophone() {
        if (!qEnvironmentVariableIsSet("PODTUNE_HARDWARE_TEST")) QSKIP("Set PODTUNE_HARDWARE_TEST=1 to test the connected microphone.");
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        Audio audio(nullptr, directory.path());
        audio.toggleRecord();
        QVERIFY2(audio.recording(), qPrintable(audio.error()));
        QTest::qWait(1200);
        QVERIFY(audio.capturedSamples() > 0);
        audio.toggleRecord();
        QVERIFY(!audio.recording());
        QCOMPARE(audio.takes().size(), 1);
        const auto take = audio.takes().first().toMap();
        QVERIFY(take.value("duration").toDouble() > .5);
        QFile wav(take.value("path").toString());
        QVERIFY(wav.open(QIODevice::ReadOnly));
        const auto header = wav.read(44);
        QCOMPARE(qFromLittleEndian<quint32>(header.constData() + 40), quint32(wav.size() - 44));
        QVERIFY(wav.size() > 48000);
        audio.playTake(0);
        QTRY_VERIFY_WITH_TIMEOUT(audio.playing(), 5000);
        audio.stopPlayback();
        audio.toggleMeter();
        QVERIFY(!audio.active());
        QVERIFY2(audio.error().isEmpty(), qPrintable(audio.error()));
    }
};

QTEST_GUILESS_MAIN(PodtuneTests)
#include "podtune_tests.moc"

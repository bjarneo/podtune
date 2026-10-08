#include <QCommandLineParser>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTextStream>
#include <QTimer>
#include "audio.h"
#include "backend.h"
#include "theme.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("podtune");
    app.setOrganizationName("podtune");
    app.setApplicationVersion("0.1.0");
    app.setDesktopFileName("podtune");
    app.setWindowIcon(QIcon("qrc:/podtune.svg"));
    QCommandLineParser parser;
    parser.setApplicationDescription("Tune the RØDE PodMic USB and test your voice.");
    parser.addHelpOption(); parser.addVersionOption();
    parser.addOption({"screenshot", "Save a window screenshot and exit.", "path"});
    parser.addOption({"theme", "Use dark, light, or omarchy mode.", "mode"});
    parser.addOption({"diagnose", "Read the microphone controls and report device access."});
    parser.addOption({"audio-check", "Check microphone capture for two seconds without a saved test."});
    parser.addOption({"verify-control", "Test a control change, then restore its previous value.", "key"});
    parser.process(app);
    if (parser.isSet("diagnose") || parser.isSet("verify-control")) {
        Hardware hardware;
        QVariantMap values, supported;
        QString issue;
        QObject::connect(&hardware, &Hardware::stateRead, &app, [&](QVariantMap v, QVariantMap s, QString id, QString error) {
            values = v; supported = s; issue = error;
            QTextStream(stdout) << QJsonDocument(QJsonObject{{"device", id}, {"values", QJsonObject::fromVariantMap(v)},
                {"supported", QJsonObject::fromVariantMap(s)}, {"error", error}}).toJson();
        });
        hardware.refresh();
        if (!parser.isSet("verify-control")) return issue.isEmpty() ? 0 : 2;
        const QString key = parser.value("verify-control");
        const Control *c = Codec::find(key);
        if (!c || !supported.value(key).toBool()) { qCritical() << "The requested control is unavailable."; return 2; }
        const double old = values.value(key).toDouble();
        const double step = c->effect == -2 || c->effect == -1 ? 1.0 : (c->maximum - c->minimum) / 20;
        const double target = c->boolean ? !bool(old) : old >= c->maximum - step ? old - step : old + step;
        bool changed = false, restored = false;
        QObject::connect(&hardware, &Hardware::applied, &app, [&](QVariantMap, QVariantMap after, QString error) {
            changed = error.isEmpty() && after.contains(key);
            if (!error.isEmpty()) qCritical().noquote() << error;
        });
        hardware.apply({{key, target}});
        const bool firstSucceeded = changed;
        changed = false;
        hardware.apply({{key, old}});
        restored = changed;
        QTextStream(stdout) << "Control: " << key << "\nChange verified: " << firstSucceeded << "\nRestore verified: " << restored << "\n";
        return firstSucceeded && restored ? 0 : 2;
    }
    if (parser.isSet("audio-check")) {
        Audio audio;
        audio.toggleMeter();
        QTimer::singleShot(2000, &app, [&] {
            QTextStream(stdout) << "Captured samples: " << audio.capturedSamples() << "\nPeak dBFS: " << audio.peakDb() << "\nError: " << audio.error() << "\n";
            const bool ok = audio.active() && audio.capturedSamples() > 0 && audio.error().isEmpty();
            audio.toggleMeter(); app.exit(ok ? 0 : 2);
        });
        return app.exec();
    }
    QQuickStyle::setStyle("Material");
    for (const char *font : {"Geist-Regular", "Geist-Medium", "Geist-SemiBold", "GeistMono-Regular", "GeistMono-Medium"})
        QFontDatabase::addApplicationFont(QString(":/fonts/%1.ttf").arg(font));
    Theme theme;
    if (parser.isSet("theme")) theme.setMode(parser.value("theme"));
    Backend backend;
    Audio audio;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("audio", &audio);
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 1;
    if (parser.isSet("screenshot")) {
        QTimer::singleShot(2200, &app, [&] {
            auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            app.exit(window && window->grabWindow().save(parser.value("screenshot")) ? 0 : 2);
        });
    }
    return app.exec();
}

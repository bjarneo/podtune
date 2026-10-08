#include "theme.h"
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSettings>
#include <cmath>

namespace {
QString mix(const QString &a, const QString &b, double t) {
    QColor x(a), y(b);
    return QColor::fromRgbF(x.redF() * t + y.redF() * (1 - t), x.greenF() * t + y.greenF() * (1 - t),
                           x.blueF() * t + y.blueF() * (1 - t)).name();
}
}

Theme::Theme(QObject *parent) : QObject(parent) {
    m_mode = QSettings().value("theme", "dark").toString();
    m_debounce.setSingleShot(true); m_debounce.setInterval(80);
    connect(&m_watch, &QFileSystemWatcher::fileChanged, this, [this] { m_debounce.start(); });
    connect(&m_watch, &QFileSystemWatcher::directoryChanged, this, [this] { m_debounce.start(); });
    connect(&m_debounce, &QTimer::timeout, this, &Theme::reload);
    reload();
}
void Theme::setMode(const QString &mode) {
    if (mode != "dark" && mode != "light" && mode != "omarchy") return;
    m_mode = mode; QSettings().setValue("theme", mode); emit changed();
}
bool Theme::dark() const { return m_mode == "omarchy" ? QColor(m_bg).lightnessF() < 0.5 : m_mode != "light"; }
QString Theme::background() const { return m_mode == "omarchy" ? m_bg : dark() ? "#17191c" : "#f4f5f7"; }
QString Theme::foreground() const { return m_mode == "omarchy" ? m_fg : dark() ? "#f0f1f3" : "#20242a"; }
QString Theme::surface() const { return QColor(background()).lighter(dark() ? 124 : 103).name(); }
QString Theme::secondary() const { return mix(foreground(), background(), .74); }
QString Theme::border() const { return mix(foreground(), background(), .18); }
QString Theme::line() const {
    return m_mode == "omarchy" ? mix(foreground(), background(), .095) : dark() ? "#2c2e32" : "#e1e2e5";
}
QString Theme::tint() const {
    return m_mode == "omarchy" ? mix(accent(), background(), .12) : dark() ? "#2a2925" : "#e9e4d8";
}
QString Theme::high() const { return dark() ? "#e5a083" : "#a33815"; }
QString Theme::scrim() const {
    if (m_mode == "dark") return "#8c060708";
    if (m_mode == "light") return "#4720242a";
    QColor bg(background()), fg(foreground());
    return dark() ? QColor::fromRgbF(bg.redF() * .25, bg.greenF() * .25, bg.blueF() * .25, .6).name(QColor::HexArgb)
                  : QColor::fromRgbF(fg.redF(), fg.greenF(), fg.blueF(), .28).name(QColor::HexArgb);
}
QString Theme::accent() const { return m_mode == "omarchy" ? m_accent : dark() ? "#d0b675" : "#765b1f"; }
QString Theme::accentForeground() const {
    QColor c(accent());
    auto linear = [](double x) { return x <= .04045 ? x / 12.92 : std::pow((x + .055) / 1.055, 2.4); };
    double luminance = .2126 * linear(c.redF()) + .7152 * linear(c.greenF()) + .0722 * linear(c.blueF());
    return luminance > .179 ? "#101214" : "#ffffff";
}
void Theme::reload() {
    const auto old = m_watch.files() + m_watch.directories();
    if (!old.isEmpty()) m_watch.removePaths(old);
    const QString current = QDir::homePath() + "/.local/state/omarchy/current";
    QString nearest = current;
    while (!QFileInfo::exists(nearest) && nearest != "/") nearest = QFileInfo(nearest).absolutePath();
    QStringList paths{nearest, QFileInfo(nearest).absolutePath(), current, current + "/theme", current + "/theme/colors.toml"};
    paths.removeDuplicates();
    for (const auto &path : paths) if (QFileInfo::exists(path)) m_watch.addPath(path);
    QFile file(current + "/theme/colors.toml");
    if (file.open(QIODevice::ReadOnly)) {
        const QString content = QString::fromUtf8(file.readAll());
        auto color = [&content](const QString &key, const QString &fallback) {
            QRegularExpression pattern("^\\s*" + key + "\\s*=\\s*[\"'](#[0-9a-fA-F]{6})[\"']", QRegularExpression::MultilineOption);
            const auto match = pattern.match(content);
            return match.hasMatch() ? match.captured(1) : fallback;
        };
        m_bg = color("background", "#17191c"); m_fg = color("foreground", "#f0f1f3"); m_accent = color("accent", "#d0b675");
    }
    emit changed();
}

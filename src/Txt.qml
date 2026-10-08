import QtQuick

// A label with a CSS-style line box: the glyphs sit in the vertical center of each line.
// Qt rounds font sizes to whole pixels. A fractional size renders at double size and scales down by half.
Item {
    id: root
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property alias elide: label.elide
    property alias wrapMode: label.wrapMode
    property alias horizontalAlignment: label.horizontalAlignment
    property alias textFormat: label.textFormat
    property alias truncated: label.truncated
    property real size: 14
    property real lh: 1.4
    property real tracking: 0
    property bool mono: false
    property bool tnum: false
    readonly property real ratio: Number.isInteger(size) ? 1 : 0.5
    implicitWidth: label.implicitWidth * ratio
    implicitHeight: Math.max(1, label.lineCount) * size * lh
    baselineOffset: label.baselineOffset * ratio

    Text {
        id: label
        width: root.width / root.ratio
        scale: root.ratio
        transformOrigin: Item.TopLeft
        color: theme.foreground
        font.family: root.mono ? "Geist Mono" : "Geist"
        font.pixelSize: Math.round(root.size / root.ratio)
        font.letterSpacing: root.tracking / root.ratio
        font.features: root.tnum ? { "tnum": 1 } : ({})
        lineHeightMode: Text.FixedHeight
        lineHeight: root.size * root.lh / root.ratio
        topPadding: (lineHeight - metrics.height) / 2
        bottomPadding: -topPadding
        textFormat: Text.PlainText

        FontMetrics { id: metrics; font: label.font }
    }
}

import QtQuick

// The Set point mark, built from the tick fader: the filled range, the set point, and the remaining range.
Item {
    id: mark
    property color filled: theme.accent
    property color point: theme.foreground
    property color background: theme.background
    property color rest: Qt.rgba(point.r * 0.24 + background.r * 0.76, point.g * 0.24 + background.g * 0.76,
                                 point.b * 0.24 + background.b * 0.76, 1)
    readonly property real unit: width / 64
    implicitWidth: 28
    implicitHeight: 28

    Repeater {
        // x, y, and height of each bar in a 64-unit square. Each bar is 6 units wide.
        model: [[7, 23, 18, 0], [18, 23, 18, 0], [29, 23, 18, 0], [40, 11, 42, 1], [51, 28, 8, 2]]
        delegate: Rectangle {
            required property var modelData
            x: modelData[0] * mark.unit
            y: modelData[1] * mark.unit
            width: 6 * mark.unit
            height: modelData[2] * mark.unit
            radius: 3 * mark.unit
            antialiasing: true
            color: modelData[3] === 0 ? mark.filled : modelData[3] === 1 ? mark.point : mark.rest
        }
    }
}

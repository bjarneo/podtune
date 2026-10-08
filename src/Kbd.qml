import QtQuick

Rectangle {
    id: key
    property alias text: label.text
    property real size: 10.5
    property real lineSize: 16
    property real pad: 5
    property color textColor: theme.secondary
    implicitWidth: label.implicitWidth + 2 * pad + 2
    implicitHeight: lineSize + 2
    radius: 4
    color: "transparent"
    border.color: theme.border

    Txt {
        id: label
        x: key.pad + 1
        y: 1
        size: key.size
        lh: key.lineSize / key.size
        mono: true
        color: key.textColor
    }
}

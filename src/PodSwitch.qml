import QtQuick
import QtQuick.Templates as T

T.Switch {
    id: control
    implicitWidth: 36
    implicitHeight: 20
    padding: 0
    spacing: 0
    hoverEnabled: true
    Accessible.name: text
    contentItem: Item {}
    indicator: Rectangle {
        width: 36
        height: 20
        radius: 10
        color: control.checked ? theme.accent : "transparent"
        border.color: control.checked ? theme.accent : theme.border
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            x: control.checked ? 19 : 3
            y: 3
            width: 14
            height: 14
            radius: 7
            color: control.checked ? theme.accentForeground : theme.secondary
            Behavior on x { NumberAnimation { duration: 150 } }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 14
            color: "transparent"
            border.width: 2
            border.color: theme.accent
            visible: control.visualFocus
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}

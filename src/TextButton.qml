import QtQuick
import QtQuick.Templates as T

// A borderless text action. It changes from the secondary color to the foreground color on hover.
T.AbstractButton {
    id: control
    property real size: 12.5
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    padding: 0
    hoverEnabled: true
    Accessible.name: text
    contentItem: Txt {
        id: label
        text: control.text
        size: control.size
        color: control.hovered ? theme.foreground : theme.secondary
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}

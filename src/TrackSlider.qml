import QtQuick
import QtQuick.Templates as T

// A horizontal slider. The knob center moves between the two track ends.
// Send changes through commit() so that the value binding stays intact.
T.Slider {
    id: control
    property real inset: 7
    property real track: 2
    property real knob: 12
    property real trackTop: 9
    property real knobTop: 4
    property real ringOffset: 2
    signal commit(real value)
    implicitWidth: 200
    implicitHeight: 20
    leftPadding: inset - knob / 2
    rightPadding: inset - knob / 2
    topPadding: 0
    bottomPadding: 0
    focusPolicy: Qt.StrongFocus
    onMoved: commit(value)
    Keys.onPressed: function(event) {
        const next = event.key === Qt.Key_Home ? from : event.key === Qt.Key_End ? to
            : event.key === Qt.Key_PageUp ? value + 10 * stepSize
            : event.key === Qt.Key_PageDown ? value - 10 * stepSize : NaN
        if (isNaN(next)) return
        event.accepted = true
        commit(Math.min(to, Math.max(from, next)))
    }

    background: Item {
        Rectangle {
            x: control.inset
            y: control.trackTop
            width: control.width - 2 * control.inset
            height: control.track
            radius: Math.ceil(control.track / 2)
            color: theme.border
        }
        Rectangle {
            x: control.inset
            y: control.trackTop
            width: control.visualPosition * (control.width - 2 * control.inset)
            height: control.track
            radius: Math.ceil(control.track / 2)
            color: theme.accent
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -control.ringOffset - 2
            radius: 4 + control.ringOffset + 2
            color: "transparent"
            border.width: 2
            border.color: theme.accent
            visible: control.visualFocus
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.knobTop
        width: control.knob
        height: control.knob
        radius: control.knob / 2
        color: theme.foreground
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}

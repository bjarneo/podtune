import QtQuick
import "Controls.js" as C

Column {
    id: control
    required property string controlKey
    required property string label
    property string topic: ""
    readonly property var spec: C.CTRL[controlKey]
    readonly property bool available: backend.supported[controlKey] === true
    readonly property var current: backend.previewValues[controlKey]
    width: parent ? parent.width : 0
    topPadding: 6
    bottomPadding: 6
    spacing: 4
    opacity: available ? 1 : 0.45

    Item {
        width: parent.width
        height: name.height
        Txt { id: name; size: 13; text: control.label }
        InfoTip {
            visible: control.topic.length > 0
            x: name.implicitWidth + 6
            anchors.verticalCenter: name.verticalCenter
            topic: control.topic
        }
        Txt {
            anchors.right: parent.right
            anchors.baseline: name.baseline
            size: 12
            mono: true
            tnum: true
            color: theme.secondary
            text: control.available ? C.format(control.controlKey, C.num(control.current)) : "Unavailable"
        }
    }
    TrackSlider {
        width: parent.width
        from: control.spec.min
        to: control.spec.max
        stepSize: control.spec.step
        value: control.current === undefined ? control.spec.min : C.num(control.current)
        enabled: control.available
        Accessible.name: control.label
        onCommit: function(value) { backend.setControl(control.controlKey, value) }
    }
}

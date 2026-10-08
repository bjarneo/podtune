import QtQuick
import "Controls.js" as C

Item {
    id: control
    required property string controlKey
    required property string label
    property int weight: Font.Normal
    readonly property bool available: backend.supported[controlKey] === true
    width: parent ? parent.width : 0
    implicitHeight: 36
    opacity: available ? 1 : 0.45

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        size: 13
        font.weight: control.weight
        text: control.label
    }
    PodSwitch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: control.label
        checked: C.num(backend.previewValues[control.controlKey]) > 0
        enabled: control.available
        onToggled: backend.setControl(control.controlKey, checked ? 1 : 0)
    }
}

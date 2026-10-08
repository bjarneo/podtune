import QtQuick

Rectangle {
    property alias text: label.text
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 18
    radius: 9
    color: theme.tint

    Txt { id: label; x: 8; size: 11; lh: 18 / 11; color: theme.accent }
}

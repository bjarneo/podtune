import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "Controls.js" as C

T.AbstractButton {
    id: card
    required property var modelData
    required property int index
    property bool selected: false
    property bool edited: false
    readonly property var marks: C.macros(modelData.values || {})
    width: 139
    height: 128
    hoverEnabled: true
    Accessible.name: modelData.name
    Accessible.description: modelData.description
    ToolTip.visible: hovered && modelData.description !== undefined
    ToolTip.delay: 700
    ToolTip.text: modelData.description || ""

    background: Rectangle {
        radius: 8
        color: card.hovered ? theme.surface : card.selected ? theme.tint : "transparent"
        border.color: card.selected ? theme.accent : theme.border
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 11
            color: "transparent"
            border.width: 2
            border.color: theme.accent
            visible: card.visualFocus
        }
    }
    contentItem: Item {}

    Txt {
        x: 15
        y: 14
        width: card.width - 30
        size: 14
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        text: card.modelData.name
    }
    Txt {
        x: 15
        y: 35.6
        size: 11.5
        color: card.selected ? theme.accent : theme.secondary
        text: card.selected ? (card.edited ? "Edited" : "Active") : card.modelData.factory ? "Factory" : "Saved"
    }
    Repeater {
        model: ["W", "P", "L"]
        delegate: Item {
            id: bars
            required property string modelData
            required property int index
            readonly property int filled: Math.round(card.marks[modelData] / 100 * 18)
            x: 15
            y: 71 + index * 16
            width: card.width - 30
            height: 10

            Txt { size: 10; lh: 1; mono: true; color: theme.secondary; text: bars.modelData }
            Repeater {
                model: 18
                delegate: Rectangle {
                    required property int index
                    readonly property bool lit: index < bars.filled
                    x: 17 + index * (2 + (bars.width - 17 - 36) / 17)
                    y: 1 + (8 - height) / 2
                    width: 2
                    height: lit ? 8 : 3
                    radius: 1
                    color: lit ? (card.selected ? theme.accent : theme.secondary) : theme.border
                }
            }
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}

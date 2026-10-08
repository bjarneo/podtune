import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "Guide.js" as G

// A small info icon. Hover shows the topic summary. Select opens the guide at the topic.
// The icon takes 14 x 14 pixels in a layout. The click area is 22 x 22 pixels.
Item {
    id: info
    required property string topic
    implicitWidth: 14
    implicitHeight: 14

    T.AbstractButton {
        id: button
        x: -4
        y: -4
        width: 22
        height: 22
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: "About " + (G.TOPICS[info.topic] ? G.TOPICS[info.topic].title : info.topic)
        Accessible.description: G.summary(info.topic)
        onClicked: ApplicationWindow.window.openGuide(info.topic)
        contentItem: Item {}
        background: Item {
            Rectangle {
                x: 4
                y: 4
                width: 14
                height: 14
                radius: 7
                color: button.pressed ? theme.line : "transparent"
                border.color: button.hovered || button.visualFocus ? theme.secondary : theme.border
                Txt {
                    anchors.centerIn: parent
                    size: 9.5
                    lh: 1
                    font.weight: Font.DemiBold
                    color: button.hovered || button.visualFocus ? theme.foreground : theme.secondary
                    text: "i"
                }
            }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }

        ToolTip {
            id: tip
            visible: button.hovered || button.visualFocus
            delay: 250
            padding: 10
            topPadding: 8
            bottomPadding: 8
            enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 } }
            exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 } }
            contentItem: Column {
                spacing: 3
                Txt {
                    width: Math.min(implicitWidth, 260)
                    size: 12.5
                    wrapMode: Text.WordWrap
                    text: G.summary(info.topic)
                }
                Txt {
                    size: 11.5
                    color: theme.secondary
                    text: "Select to read more"
                }
            }
            background: Rectangle {
                radius: 7
                color: theme.surface
                border.color: theme.border
            }
        }
    }
}

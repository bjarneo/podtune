import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T

Popup {
    id: dialog
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(520, parent.width - 32)
    readonly property real inner: width - 54
    modal: true
    focus: true
    padding: 0
    enter: Transition {}
    exit: Transition {}
    Overlay.modal: Rectangle { color: theme.scrim }
    background: Rectangle { radius: 10; color: theme.surface; border.color: theme.border }

    contentItem: Column {
        topPadding: 25
        bottomPadding: 21
        leftPadding: 27
        rightPadding: 27

        Item {
            width: dialog.inner
            height: 30
            Txt { anchors.verticalCenter: parent.verticalCenter; size: 17; font.weight: Font.DemiBold; text: "Use Podtune" }
            T.AbstractButton {
                id: closeButton
                anchors.right: parent.right
                width: 30
                height: 30
                hoverEnabled: true
                Accessible.name: "Close help"
                onClicked: dialog.close()
                background: Rectangle { radius: 6; color: closeButton.hovered ? theme.background : "transparent" }
                contentItem: Item {}
                Txt {
                    anchors.centerIn: parent
                    size: 20
                    lh: 1
                    color: closeButton.hovered ? theme.foreground : theme.secondary
                    text: "×"
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
        Item { width: 1; height: 14 }
        Column {
            width: dialog.inner
            spacing: 6
            Repeater {
                model: [
                    "Select Check levels and speak normally.",
                    "Adjust Input gain for peaks near −18 to −6 dBFS, inside the shaded band.",
                    "Record a reference take.",
                    "Select a preset or adjust Warmth, Presence, and Leveling.",
                    "Record another take and compare through headphones."
                ]
                delegate: Item {
                    required property string modelData
                    required property int index
                    width: dialog.inner
                    height: step.height
                    Txt { width: 16.4; horizontalAlignment: Text.AlignRight; size: 13.5; text: (parent.index + 1) + "." }
                    Txt { id: step; x: 20; width: dialog.inner - 20; size: 13.5; wrapMode: Text.WordWrap; text: parent.modelData }
                }
            }
        }
        Item { width: 1; height: 18 }
        Column {
            spacing: 7
            TextMetrics { id: widestKey; font.family: "Geist Mono"; font.pixelSize: 11; text: "Ctrl Shift Z" }
            Repeater {
                model: [["Space", "Start or stop a test"], ["Ctrl Z", "Undo a verified change"],
                        ["Ctrl Shift Z", "Redo a change"], ["Ctrl R", "Refresh hardware state"],
                        ["?", "Show this help"], ["Q", "Quit"]]
                delegate: Item {
                    required property var modelData
                    width: dialog.inner
                    height: 20
                    Kbd { size: 11; lineSize: 18; pad: 6; textColor: theme.foreground; text: parent.modelData[0] }
                    Txt {
                        x: widestKey.advanceWidth + 14 + 14
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13
                        text: parent.modelData[1]
                    }
                }
            }
        }
        Item { width: 1; height: 16 }
        Txt {
            width: dialog.inner
            size: 12.5
            color: theme.secondary
            wrapMode: Text.WordWrap
            text: "The app changes onboard settings. It reads each value back after a write. The noise gate enable command is not verified, so the app exposes only its verified parameters."
        }
    }
}

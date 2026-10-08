import QtQuick
import QtQuick.Templates as T
import "Controls.js" as C

Item {
    id: take
    required property var modelData
    required property int index
    readonly property bool playing: audio.playing && audio.playingTake === index
    readonly property bool measured: modelData.duration !== undefined
    readonly property int clipped: C.num(modelData.clipped)
    width: ListView.view ? ListView.view.width : 0
    height: 58.28

    Rectangle { width: parent.width; height: 1; color: theme.line }

    T.AbstractButton {
        id: play
        y: 1 + (57.28 - 32) / 2
        width: 32
        height: 32
        enabled: !audio.recording
        opacity: audio.recording ? 0.4 : 1
        hoverEnabled: true
        Accessible.name: (take.playing ? "Stop" : "Play") + " voice test " + take.modelData.name
        onClicked: audio.playTake(take.index)
        background: Rectangle {
            radius: 16
            color: take.playing ? theme.accent : play.hovered ? theme.surface : "transparent"
            border.color: take.playing ? theme.accent : theme.border
        }
        contentItem: Item {
            Rectangle {
                visible: take.playing
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: 2
                color: theme.accentForeground
            }
            Canvas {
                id: triangle
                visible: !take.playing
                x: 13
                y: 11
                width: 8
                height: 10
                property color ink: theme.foreground
                onInkChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = ink
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(8, 5)
                    ctx.lineTo(0, 10)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    Item {
        id: details
        x: 44
        y: 11
        width: trash.x - 12 - x
        height: 37.28

        Item {
            width: parent.width
            height: 18.9
            Txt {
                id: name
                anchors.verticalCenter: parent.verticalCenter
                size: 13.5
                tnum: true
                font.weight: Font.Medium
                text: take.modelData.name
            }
            Rectangle {
                visible: (take.modelData.preset || "").length > 0
                x: name.implicitWidth + 8
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(pill.implicitWidth + 16, details.width - x)
                height: 18
                radius: 9
                color: "transparent"
                border.color: theme.border
                Txt {
                    id: pill
                    x: 8
                    y: 1
                    width: parent.width - 16
                    size: 11
                    lh: 16 / 11
                    color: theme.secondary
                    elide: Text.ElideRight
                    text: take.modelData.preset || ""
                }
            }
        }
        Txt {
            y: 21.89
            width: parent.width
            size: 11
            mono: true
            color: theme.secondary
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: take.measured
                ? Number(take.modelData.duration).toFixed(1) + " s · peak " + C.signed(C.num(take.modelData.peak), 1) + " dBFS · "
                  + "<font color=\"" + (take.clipped > 0 ? theme.high : theme.secondary) + "\">"
                  + (take.clipped > 0 ? take.clipped + " clipped samples" : "no clipped samples") + "</font>"
                : "WAV voice test"
        }
    }

    TextButton {
        id: trash
        anchors.right: parent.right
        anchors.verticalCenter: play.verticalCenter
        rightPadding: 2
        leftPadding: 2
        topPadding: 6
        bottomPadding: 6
        implicitWidth: contentItem.implicitWidth + 4
        implicitHeight: contentItem.implicitHeight + 12
        text: "Trash"
        enabled: !audio.recording
        Accessible.name: "Move voice test " + take.modelData.name + " to trash"
        onClicked: audio.deleteTake(take.index)
    }

    Rectangle {
        x: 44
        y: take.height - 1
        width: (take.width - 44) * (take.playing ? audio.playProgress : 0)
        height: 2
        color: theme.accent
    }
}

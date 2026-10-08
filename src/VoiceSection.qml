import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "Controls.js" as C

// The level meter, input gain, the test buttons, and the list of takes.
Item {
    id: section
    required property var app
    property var outerScroll: null
    readonly property var level: app.level
    readonly property real listTop: 489.18
    readonly property real footerHeight: 26.8
    readonly property real listNatural: takeList.count > 0 ? takeList.count * 58.28 : emptyState.height
    readonly property real minimumHeight: listTop + Math.min(listNatural, 117) + footerHeight
    implicitHeight: listTop + listNatural + footerHeight

    Item {
        width: parent.width
        height: 20
        SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "Voice test" }
        Row {
            readonly property var chip: audio.recording
                ? { dot: theme.high, text: "Recording · " + section.app.clock(audio.duration), blink: Math.floor(audio.duration) % 2 === 0 ? 1 : 0.35 }
                : audio.active ? { dot: theme.accent, text: "Listening", blink: 1 } : { dot: theme.border, text: "Idle", blink: 1 }
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 3.5
                color: parent.chip.dot
                opacity: parent.chip.blink
            }
            Txt { size: 12; tnum: true; color: theme.secondary; text: parent.chip.text }
        }
    }

    Rectangle {
        id: meterCard
        y: 32
        width: parent.width
        height: 252.09
        radius: 8
        color: theme.surface
        border.color: theme.border

        Item {
            x: 19
            y: 17
            width: parent.width - 38
            height: 56.09

            Txt { size: 11.5; color: theme.secondary; text: "Peak" }
            Txt {
                id: peakValue
                y: 22.09
                size: 34
                lh: 1
                mono: true
                tnum: true
                tracking: -1.02
                text: section.level.peakText
            }
            Txt {
                x: peakValue.implicitWidth + 6
                anchors.baseline: peakValue.baseline
                size: 12
                color: theme.secondary
                text: "dBFS"
            }
            Column {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 6
                Row {
                    anchors.right: parent.right
                    spacing: 7
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: section.level.dot
                    }
                    Txt { size: 13; font.weight: Font.Medium; color: section.level.ink; text: section.level.status }
                }
                Txt {
                    anchors.right: parent.right
                    size: 11.5
                    mono: true
                    tnum: true
                    color: theme.secondary
                    text: "RMS " + section.level.rmsText
                }
            }
        }
        Waveform {
            x: 19
            y: 87.09
            width: parent.width - 38
            height: 150
            samples: audio.waveform
            dimmed: !audio.active
        }
        Rectangle {
            visible: !audio.active
            anchors.horizontalCenter: parent.horizontalCenter
            y: 87.09 + (150 - height) / 2
            width: idleHint.width + 24
            height: idleHint.height + 8
            color: theme.surface
            Txt {
                id: idleHint
                anchors.centerIn: parent
                width: Math.min(implicitWidth, meterCard.width - 86)
                size: 13
                color: theme.secondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Select Check levels and speak at your normal volume."
            }
        }
    }

    Item {
        y: 302.09
        width: parent.width
        height: 75.09
        opacity: backend.supported.gain === true ? 1 : 0.45

        Item {
            width: parent.width
            height: 26
            Txt { id: gainLabel; anchors.verticalCenter: parent.verticalCenter; size: 14; font.weight: Font.Medium; text: "Input gain" }
            Txt {
                x: gainLabel.implicitWidth + 10
                anchors.verticalCenter: parent.verticalCenter
                size: 12.5
                mono: true
                tnum: true
                color: theme.secondary
                text: backend.supported.gain === true ? C.format("gain", C.num(section.app.values.gain)) : "Unavailable"
            }
            T.AbstractButton {
                id: muteButton
                readonly property bool muted: C.num(section.app.values.mute) > 0
                anchors.right: parent.right
                width: muteLabel.implicitWidth + 24
                height: 26
                enabled: backend.supported.mute === true
                hoverEnabled: true
                text: muted ? "Muted" : "Mute"
                Accessible.role: Accessible.CheckBox
                Accessible.checked: muted
                Accessible.name: "Mute"
                onClicked: backend.setControl("mute", muted ? 0 : 1)
                background: Rectangle {
                    radius: 6
                    color: muteButton.muted ? theme.foreground : "transparent"
                    border.color: muteButton.muted ? theme.foreground : theme.border
                }
                contentItem: Item {}
                Txt {
                    id: muteLabel
                    anchors.centerIn: parent
                    size: 12.5
                    font.weight: Font.Medium
                    color: muteButton.muted ? theme.background : theme.secondary
                    text: muteButton.text
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
        TrackSlider {
            y: 34
            width: parent.width
            height: 22
            inset: 8
            track: 4
            knob: 16
            trackTop: 9
            knobTop: 3
            from: 22
            to: 63
            stepSize: 1
            value: section.app.values.gain === undefined ? 22 : C.num(section.app.values.gain)
            enabled: backend.supported.gain === true
            Accessible.name: "Input gain"
            onCommit: function(value) { backend.setControl("gain", value) }
        }
        Item {
            y: 59
            width: parent.width
            height: 16.1
            Txt { id: gainMin; size: 11.5; mono: true; color: theme.secondary; text: "22" }
            Txt {
                readonly property real room: gainMax.x - gainMin.implicitWidth - 16
                x: gainMin.implicitWidth + (gainMax.x - gainMin.implicitWidth - width) / 2
                width: Math.max(0, Math.min(implicitWidth, room))
                size: 11.5
                color: theme.secondary
                elide: Text.ElideRight
                text: "Set speech peaks inside the shaded band"
            }
            Txt { id: gainMax; anchors.right: parent.right; size: 11.5; mono: true; color: theme.secondary; text: "63 dB" }
        }
    }

    Item {
        y: 395.18
        width: parent.width
        height: 40

        T.AbstractButton {
            id: checkButton
            width: 14 + (parent.width - 36) / 2.4
            height: 40
            enabled: !audio.recording
            opacity: audio.recording ? 0.4 : 1
            hoverEnabled: true
            text: audio.active ? "Stop levels" : "Check levels"
            Accessible.name: text
            onClicked: audio.toggleMeter()
            background: Rectangle {
                radius: 8
                color: checkButton.hovered ? theme.surface : "transparent"
                border.color: theme.border
            }
            contentItem: Item {}
            Txt { anchors.centerIn: parent; size: 13.5; font.weight: Font.Medium; text: checkButton.text }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
        T.AbstractButton {
            id: recordButton
            x: checkButton.width + 10
            width: parent.width - x
            height: 40
            text: audio.recording ? "Stop · " + Math.floor(audio.duration) + " s" : "Record test"
            Accessible.name: audio.recording ? "Stop the voice test" : "Record a voice test"
            onClicked: audio.toggleRecord()
            background: Rectangle {
                radius: 8
                color: recordButton.pressed ? Qt.darker(theme.accent, 1.14) : theme.accent
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 11
                    color: "transparent"
                    border.width: 2
                    border.color: theme.foreground
                    visible: recordButton.visualFocus
                }
            }
            contentItem: Item {}
            Row {
                anchors.centerIn: parent
                spacing: 9
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: audio.recording ? 10 : 9
                    height: width
                    radius: audio.recording ? 2 : 4.5
                    color: theme.accentForeground
                }
                Txt {
                    size: 13.5
                    tnum: true
                    font.weight: Font.DemiBold
                    color: theme.accentForeground
                    text: recordButton.text
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    Item {
        y: 461.18
        width: parent.width
        height: 20
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            SectionLabel { text: "Takes" }
            Txt { size: 11; mono: true; color: theme.secondary; text: String(audio.takes.length) }
        }
        TextButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Open folder"
            Accessible.name: "Open the voice test folder"
            onClicked: audio.openRecordings()
        }
    }

    ListView {
        id: takeList
        y: section.listTop
        width: parent.width
        height: Math.max(0, section.height - section.listTop - section.footerHeight)
        clip: true
        model: audio.takes
        interactive: contentHeight > height + 0.5
        acceptedButtons: Qt.NoButton
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: TakeRow {}
        WheelScroll { flickable: takeList; step: 58.28; outer: section.outerScroll }

        Item {
            id: emptyState
            visible: takeList.count === 0
            width: takeList.width
            height: emptyText.implicitHeight + 25
            Rectangle { width: parent.width; height: 1; color: theme.line }
            Txt {
                id: emptyText
                y: 13
                width: parent.width
                size: 13
                color: theme.secondary
                wrapMode: Text.WordWrap
                text: "Record a reference take. Change a preset, then record another take to compare."
            }
        }
    }

    Txt {
        anchors.bottom: parent.bottom
        width: parent.width
        size: 12
        color: theme.secondary
        elide: Text.ElideRight
        text: "Tests stay on this computer. Each take stops at 60 seconds."
    }
}

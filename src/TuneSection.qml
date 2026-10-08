import QtQuick
import QtQuick.Templates as T
import "Controls.js" as C

// Presets, the three tone scales, and the headphone controls.
Column {
    id: section
    required property var app
    property var outerScroll: null
    signal openDrawer(string target)
    readonly property var values: app.values

    // Moves the preset row so that the first hidden card on one side becomes fully visible.
    // The edge keeps 40 px of the card before it, under the fade and the button.
    function pagePresets(direction) {
        const view = presetList
        const margin = 40
        const end = view.originX + Math.max(0, view.contentWidth - view.width)
        const from = presetScroll.glide.running ? presetScroll.glide.to : view.contentX
        let target = from
        if (direction > 0) {
            const card = view.itemAt(from + view.width - 1, 10)
            target = (card && card.x + card.width > from + view.width + 0.5 ? card.x : from + view.width) - margin
        } else {
            const card = view.itemAt(from + 1, 10)
            target = (card && card.x < from - 0.5 ? card.x + card.width - view.width : from - view.width) + margin
        }
        presetScroll.glideTo(Math.max(view.originX, Math.min(end, target)), 240)
    }

    component EdgeButton: T.AbstractButton {
        id: edge
        property int direction: 1
        y: 50
        width: 28
        height: 28
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        Accessible.name: direction > 0 ? "Show the next presets" : "Show the previous presets"
        onClicked: section.pagePresets(direction)
        background: Rectangle {
            radius: 14
            color: edge.hovered ? theme.surface : theme.background
            border.color: edge.hovered ? theme.secondary : theme.border
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        contentItem: Item {
            Canvas {
                anchors.centerIn: parent
                width: 8
                height: 12
                property color ink: edge.hovered ? theme.foreground : theme.secondary
                onInkChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = ink
                    ctx.lineWidth = 1.6
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    if (edge.direction > 0) { ctx.moveTo(2, 1.5); ctx.lineTo(6.5, 6); ctx.lineTo(2, 10.5) }
                    else { ctx.moveTo(6, 1.5); ctx.lineTo(1.5, 6); ctx.lineTo(6, 10.5) }
                    ctx.stroke()
                }
            }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    Item {
        width: parent.width
        height: 20
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "Presets" }
            InfoTip { anchors.verticalCenter: parent.verticalCenter; topic: "presets" }
        }
        TextButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Save current…"
            Accessible.name: "Save current settings as a preset"
            onClicked: section.openDrawer("save")
        }
    }
    Item { width: 1; height: 12 }
    Item {
        width: parent.width
        height: 128

        ListView {
            id: presetList
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 10
            model: backend.presets
            interactive: contentWidth > width
            acceptedButtons: Qt.NoButton
            clip: interactive
            boundsBehavior: Flickable.StopAtBounds
            delegate: PresetCard {
                selected: index === section.app.selectedPreset
                edited: section.app.edited
                enabled: !backend.busy
                onClicked: section.app.applyPreset(index)
            }
            WheelScroll { id: presetScroll; flickable: presetList; horizontal: true }
            WheelScroll { flickable: presetList; forwardOnly: true; outer: section.outerScroll; shiftScroll: presetScroll; redirect: presetScroll }
        }
        // The fades show that more presets sit outside the row.
        Rectangle {
            width: 32
            height: parent.height
            opacity: presetList.contentX > presetList.originX + 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: theme.background }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.right: parent.right
            width: 32
            height: parent.height
            opacity: presetList.contentX < presetList.originX + presetList.contentWidth - presetList.width - 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: theme.background }
            }
        }
        EdgeButton {
            x: 2
            direction: -1
            visible: opacity > 0
            opacity: presetList.contentX > presetList.originX + 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        EdgeButton {
            x: parent.width - width - 2
            direction: 1
            visible: opacity > 0
            opacity: presetList.contentX < presetList.originX + presetList.contentWidth - presetList.width - 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        Connections {
            target: section.app
            function onSelectedPresetChanged() {
                if (section.app.selectedPreset >= 0) presetList.positionViewAtIndex(section.app.selectedPreset, ListView.Contain)
            }
        }
    }
    Item { width: 1; height: 34 }
    Item {
        width: parent.width
        height: 20
        SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "Tone" }
        TextButton {
            visible: section.app.edited
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            enabled: !backend.busy
            text: "Reset to " + (section.app.activePreset ? section.app.activePreset.name : "")
            onClicked: section.app.applyPreset(section.app.selectedPreset)
        }
    }
    Item { width: 1; height: 12 }
    Rectangle {
        width: parent.width
        height: toneRows.implicitHeight + 2
        radius: 8
        color: theme.surface
        border.color: theme.border

        Column {
            id: toneRows
            x: 1
            y: 1
            width: parent.width - 2
            ToneRow {
                width: parent.width
                title: "Warmth"
                topic: "warmth"
                subtitle: "Adds low-end body"
                detailLabel: "Big Bottom"
                detail: C.num(section.values.bottom) > 0 ? "drive " + Math.round(C.num(section.values.bottomDrive)) + " %" : "off"
                value: section.app.marks.W
                available: section.app.supports(["bottom", "bottomDrive"])
                onCommit: function(value) { section.app.setMacro("W", value) }
                onOpenDetail: section.openDrawer("tone")
            }
            ToneRow {
                width: parent.width
                divided: true
                title: "Presence"
                topic: "presence"
                subtitle: "Adds clarity to speech"
                detailLabel: "Aural Exciter"
                detail: C.num(section.values.exciter) > 0
                    ? "mix " + Math.round(C.num(section.values.exciterMix)) + " % · "
                      + C.kHz(C.snap("exciterTune", C.num(section.values.exciterTune))) + " kHz" : "off"
                value: section.app.marks.P
                available: section.app.supports(["exciter", "exciterMix", "exciterTune"])
                onCommit: function(value) { section.app.setMacro("P", value) }
                onOpenDetail: section.openDrawer("tone")
            }
            ToneRow {
                width: parent.width
                divided: true
                title: "Leveling"
                topic: "leveling"
                subtitle: "Keeps speech consistent"
                detailLabel: "Compressor"
                detail: C.num(section.values.compressor) > 0
                    ? C.signed(C.num(section.values.compThreshold), 1) + " dB · " + C.num(section.values.compRatio).toFixed(1) + ":1 · +"
                      + C.num(section.values.compGain).toFixed(1) + " dB" : "off"
                value: section.app.marks.L
                available: section.app.supports(["compressor", "compThreshold", "compRatio", "compGain"])
                onCommit: function(value) { section.app.setMacro("L", value) }
                onOpenDetail: section.openDrawer("comp")
            }
        }
    }
    Item { width: 1; height: 34 }
    Item {
        width: parent.width
        height: 20
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "Headphones" }
            InfoTip { anchors.verticalCenter: parent.verticalCenter; topic: "headphones" }
        }
    }
    Item { width: 1; height: 12 }
    Rectangle {
        id: phonesCard
        // Below 560 pixels, the playback cell moves under the monitor cell.
        readonly property bool stacked: width < 560
        readonly property real monitorWidth: stacked ? width - 2 : (width - 3) / 2.35
        readonly property real monitorHeight: stacked ? 70.4 : 92.39
        readonly property bool playbackAvailable: backend.supported.headphones === true
        width: parent.width
        height: stacked ? 2 + monitorHeight + 1 + 92.39 : 94.39
        radius: 8
        color: theme.surface
        border.color: theme.border

        Item {
            x: 1
            y: 1
            width: phonesCard.monitorWidth
            height: phonesCard.monitorHeight
            opacity: backend.supported.directMonitor === true ? 1 : 0.45
            PodSwitch {
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "Direct monitor"
                checked: C.num(section.values.directMonitor) > 0
                enabled: backend.supported.directMonitor === true
                onToggled: backend.setControl("directMonitor", checked ? 1 : 0)
            }
            Column {
                x: 70
                width: parent.width - 90
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Txt { width: parent.width; size: 14; font.weight: Font.Medium; elide: Text.ElideRight; text: "Direct monitor" }
                Txt { width: parent.width; size: 12; color: theme.secondary; elide: Text.ElideRight; text: "Hear the mic in your headphones" }
            }
        }
        Rectangle {
            x: phonesCard.stacked ? 1 : 1 + phonesCard.monitorWidth
            y: phonesCard.stacked ? 1 + phonesCard.monitorHeight : 1
            width: phonesCard.stacked ? phonesCard.width - 2 : 1
            height: phonesCard.stacked ? 1 : 92.39
            color: theme.line
        }
        Item {
            x: phonesCard.stacked ? 1 : 2 + phonesCard.monitorWidth
            y: phonesCard.stacked ? 2 + phonesCard.monitorHeight : 1
            width: phonesCard.stacked ? phonesCard.width - 2 : phonesCard.width - 3 - phonesCard.monitorWidth
            height: 92.39
            Item {
                x: 20
                y: 14
                width: parent.width - 40
                height: 19.6
                opacity: phonesCard.playbackAvailable ? 1 : 0.45
                Txt { id: playbackLabel; size: 14; font.weight: Font.Medium; text: "Computer playback" }
                Txt {
                    anchors.right: parent.right
                    anchors.baseline: playbackLabel.baseline
                    size: 12
                    mono: true
                    tnum: true
                    color: theme.secondary
                    text: phonesCard.playbackAvailable ? C.format("headphones", C.num(section.values.headphones)) : "Unavailable"
                }
            }
            TrackSlider {
                x: 20
                y: 37.6
                width: parent.width - 40
                inset: 7
                track: 3
                knob: 14
                trackTop: 9
                knobTop: 3
                from: -60
                to: 0
                stepSize: 1
                value: section.values.headphones === undefined ? -60 : C.num(section.values.headphones)
                enabled: phonesCard.playbackAvailable
                opacity: phonesCard.playbackAvailable ? 1 : 0.45
                Accessible.name: "Computer playback volume"
                onCommit: function(value) { backend.setControl("headphones", value) }
            }
            Txt {
                x: 20
                y: 61.6
                width: parent.width - 40
                size: 12
                color: theme.secondary
                elide: Text.ElideRight
                text: "Use the dial on the microphone for headphone level."
            }
        }
    }
}

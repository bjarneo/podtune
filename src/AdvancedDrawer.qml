import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "Controls.js" as C

Item {
    id: drawer
    property bool open: false
    property real progress: open ? 1 : 0
    property var level: ({})
    signal savePreset(string name)
    visible: progress > 0
    Behavior on progress { NumberAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: [0.2, 0.75, 0.2, 1, 1, 1] } }

    readonly property real panelWidth: Math.min(473, width)
    readonly property var values: backend.previewValues
    readonly property bool compressorOn: C.num(values.compressor) > 0

    function show(section) {
        open = true
        const target = section === "comp" ? compSection : section === "tone" ? toneSection
            : section === "save" ? saveSection : null
        scroller.to = target ? Math.min(Math.max(0, target.y - 2), Math.max(0, body.contentHeight - body.height)) : 0
        scroller.restart()
        if (section === "save") focusTimer.restart()
    }
    function save() {
        if (nameField.text.trim().length === 0 || backend.busy) return
        drawer.savePreset(nameField.text)
        nameField.text = ""
    }

    Timer { id: focusTimer; interval: 320; onTriggered: nameField.forceActiveFocus() }
    NumberAnimation { id: scroller; target: body; property: "contentY"; duration: 320; easing.type: Easing.OutCubic }

    Rectangle {
        anchors.fill: parent
        color: theme.scrim
        opacity: drawer.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        MouseArea {
            anchors.fill: parent
            enabled: drawer.open
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onClicked: drawer.open = false
            onWheel: function(wheel) { wheel.accepted = true }
        }
    }

    Rectangle {
        id: panel
        x: drawer.width - drawer.panelWidth * drawer.progress + 4.73 * (1 - drawer.progress)
        width: drawer.panelWidth
        height: drawer.height
        color: theme.background
        Accessible.role: Accessible.Pane
        Accessible.name: "Advanced controls"

        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }
        Rectangle { width: 1; height: parent.height; color: theme.border }

        Item {
            id: header
            x: 1
            width: panel.width - 1
            height: 64

            Column {
                x: 24
                y: 11.9
                Txt { size: 16; font.weight: Font.DemiBold; text: "Advanced" }
                Txt { size: 12; color: theme.secondary; text: "Every verified hardware control" }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                y: 15.5
                height: 32
                spacing: 4

                Repeater {
                    model: [{ label: "Undo", ready: backend.canUndo }, { label: "Redo", ready: backend.canRedo }]
                    delegate: T.AbstractButton {
                        id: historyButton
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: historyLabel.implicitWidth + 20
                        height: 30
                        enabled: modelData.ready && !backend.busy
                        opacity: modelData.ready ? 1 : 0.4
                        hoverEnabled: true
                        text: modelData.label
                        Accessible.name: text
                        onClicked: modelData.label === "Undo" ? backend.undo() : backend.redo()
                        background: Rectangle { radius: 6; color: historyButton.hovered ? theme.surface : "transparent" }
                        contentItem: Item {}
                        Txt { id: historyLabel; x: 10; anchors.verticalCenter: parent.verticalCenter; size: 13; text: historyButton.text }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
                Item {
                    width: 13
                    height: 32
                    Rectangle { x: 6; y: 7; width: 1; height: 18; color: theme.border }
                }
                T.AbstractButton {
                    id: closeButton
                    width: 32
                    height: 32
                    hoverEnabled: true
                    Accessible.name: "Close advanced controls"
                    onClicked: drawer.open = false
                    background: Rectangle { radius: 6; color: closeButton.hovered ? theme.surface : "transparent" }
                    contentItem: Item {}
                    Txt {
                        anchors.centerIn: parent
                        size: 22
                        lh: 1
                        color: closeButton.hovered ? theme.foreground : theme.secondary
                        text: "×"
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: theme.border }
        }

        Flickable {
            id: body
            x: 1
            y: 64
            width: panel.width - 1
            height: panel.height - 64
            clip: true
            contentHeight: sections.implicitHeight + 28
            acceptedButtons: Qt.NoButton
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            WheelScroll { flickable: body }

            Column {
                id: sections
                x: 24
                width: body.width - 48

                DrawerSection {
                    Txt { size: 14; font.weight: Font.DemiBold; text: "Input" }
                    Item { width: 1; height: 8 }
                    ValueControl { controlKey: "gain"; label: "Input gain" }
                    Row {
                        spacing: 24
                        ToggleControl { width: (sections.width - 24) / 2; controlKey: "hpf"; label: "High-pass · 60 Hz" }
                        ToggleControl { width: (sections.width - 24) / 2; controlKey: "mute"; label: "Mute" }
                    }
                }

                DrawerSection {
                    id: compSection
                    Item {
                        width: parent.width
                        height: 20
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Txt { anchors.verticalCenter: parent.verticalCenter; size: 14; font.weight: Font.DemiBold; text: "Compressor" }
                            Pill { anchors.verticalCenter: parent.verticalCenter; text: "Leveling" }
                        }
                        Row {
                            anchors.right: parent.right
                            spacing: 8
                            Txt { anchors.verticalCenter: parent.verticalCenter; size: 13; color: theme.secondary; text: "Enabled" }
                            PodSwitch {
                                text: "Compressor enabled"
                                checked: drawer.compressorOn
                                enabled: backend.supported.compressor === true
                                onToggled: backend.setControl("compressor", checked ? 1 : 0)
                            }
                        }
                    }
                    Item { width: 1; height: 10 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "Reduce loud peaks and keep speech more consistent." }
                    Item { width: 1; height: 10 }
                    Rectangle {
                        width: parent.width
                        height: 156.69
                        radius: 8
                        color: theme.surface
                        border.color: theme.line

                        CompressorCurve {
                            x: 15
                            y: 13
                            width: parent.width - 30
                            height: 110
                            active: drawer.compressorOn
                            threshold: C.num(drawer.values.compThreshold)
                            ratio: Math.max(1, C.num(drawer.values.compRatio))
                            makeup: C.num(drawer.values.compGain)
                        }
                        Item {
                            x: 15
                            y: 131
                            width: parent.width - 30
                            height: 14.7
                            Txt { size: 10.5; mono: true; color: theme.secondary; text: "−60 in" }
                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                size: 10.5
                                mono: true
                                color: theme.secondary
                                text: drawer.compressorOn
                                    ? "threshold " + C.signed(C.num(drawer.values.compThreshold), 1) + " dB · " + C.num(drawer.values.compRatio).toFixed(1) + ":1"
                                    : "compressor off"
                            }
                            Txt { anchors.right: parent.right; size: 10.5; mono: true; color: theme.secondary; text: "0 dBFS" }
                        }
                    }
                    Item { width: 1; height: 8 }
                    Column {
                        width: parent.width
                        opacity: drawer.compressorOn ? 1 : 0.45
                        ValueControl { controlKey: "compThreshold"; label: "Threshold" }
                        ValueControl { controlKey: "compRatio"; label: "Ratio" }
                        Row {
                            spacing: 24
                            ValueControl { width: (sections.width - 24) / 2; controlKey: "compAttack"; label: "Attack" }
                            ValueControl { width: (sections.width - 24) / 2; controlKey: "compRelease"; label: "Release" }
                        }
                        ValueControl { controlKey: "compGain"; label: "Makeup gain" }
                    }
                }

                DrawerSection {
                    id: toneSection
                    Row {
                        height: 19.6
                        spacing: 8
                        Txt { size: 14; font.weight: Font.DemiBold; text: "APHEX tone" }
                        Pill { anchors.verticalCenter: parent.verticalCenter; text: "Warmth" }
                        Pill { anchors.verticalCenter: parent.verticalCenter; text: "Presence" }
                    }
                    Item { width: 1; height: 6 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "Presence and bass effects. These are not a parametric EQ." }
                    Item { width: 1; height: 6 }
                    ToggleControl { controlKey: "bottom"; label: "Big Bottom"; weight: Font.Medium }
                    ValueControl {
                        controlKey: "bottomDrive"
                        label: "Low-frequency drive"
                        topPadding: 2
                        bottomPadding: 8
                        opacity: (C.num(drawer.values.bottom) > 0 ? 1 : 0.45) * (available ? 1 : 0.45)
                    }
                    Item {
                        width: parent.width
                        height: 37
                        Rectangle { width: parent.width; height: 1; color: theme.line }
                        ToggleControl { y: 1; controlKey: "exciter"; label: "Aural Exciter"; weight: Font.Medium }
                    }
                    Column {
                        width: parent.width
                        opacity: C.num(drawer.values.exciter) > 0 ? 1 : 0.45
                        ValueControl { controlKey: "exciterMix"; label: "Presence mix"; topPadding: 2 }
                        ValueControl { controlKey: "exciterTune"; label: "Presence frequency" }
                    }
                }

                DrawerSection {
                    Txt { size: 14; font.weight: Font.DemiBold; text: "Noise gate" }
                    Item { width: 1; height: 6 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "The gate has no verified independent enable control. These parameters adjust its onboard behavior." }
                    Item { width: 1; height: 6 }
                    ValueControl { controlKey: "gateThreshold"; label: "Threshold" }
                    Row {
                        spacing: 24
                        ValueControl { width: (sections.width - 24) / 2; controlKey: "gateAttack"; label: "Attack" }
                        ValueControl { width: (sections.width - 24) / 2; controlKey: "gateRelease"; label: "Release" }
                    }
                }

                DrawerSection {
                    Txt { size: 14; font.weight: Font.DemiBold; text: "Headphones" }
                    Item { width: 1; height: 4 }
                    ToggleControl { controlKey: "directMonitor"; label: "Direct monitor" }
                    ValueControl { controlKey: "headphones"; label: "Computer playback volume" }
                    ValueControl { controlKey: "monitorMix"; label: "Monitor mix · raw device value" }
                    Item { width: 1; height: 6 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "The monitor mix direction depends on the device. Compare both ends at a low headphone volume." }
                }

                DrawerSection {
                    bottomGap: 16
                    Item {
                        width: parent.width
                        height: 19.6
                        Txt { id: levelsTitle; size: 14; font.weight: Font.DemiBold; text: "Levels" }
                        Txt {
                            anchors.right: parent.right
                            anchors.baseline: levelsTitle.baseline
                            size: 12
                            mono: true
                            tnum: true
                            color: theme.secondary
                            textFormat: Text.StyledText
                            text: "Peak <font color=\"" + theme.foreground + "\">" + (drawer.level.live ? drawer.level.peakText + " dBFS" : "—")
                                + "</font> · RMS " + drawer.level.rmsText
                        }
                    }
                    Item { width: 1; height: 12 }
                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 2
                        color: theme.border
                        clip: true
                        Rectangle {
                            width: parent.width * (drawer.level.fill || 0)
                            height: parent.height
                            radius: 2
                            color: drawer.level.peak > -3 ? theme.high : theme.accent
                        }
                    }
                    Item { width: 1; height: 6 }
                    Item {
                        width: parent.width
                        height: 16
                        Txt { size: 10.5; mono: true; color: theme.secondary; text: "−60" }
                        Txt { x: parent.width * 0.7 - width / 2; size: 10.5; mono: true; color: theme.secondary; text: "−18" }
                        Txt { x: parent.width * 0.9 - width; size: 10.5; mono: true; color: theme.secondary; text: "−6" }
                        Txt { anchors.right: parent.right; size: 10.5; mono: true; color: theme.secondary; text: "0" }
                    }
                    Item { width: 1; height: 8 }
                    Txt { width: parent.width; size: 13; wrapMode: Text.WordWrap; text: drawer.level.guide || "" }
                    Item { width: 1; height: 6 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "Level guidance measures the signal. Listen for tone, distortion, room noise, and comfort." }
                }

                DrawerSection {
                    id: saveSection
                    bottomGap: 16
                    Txt { size: 14; font.weight: Font.DemiBold; text: "Save preset" }
                    Item { width: 1; height: 10 }
                    Item {
                        width: parent.width
                        height: 36
                        T.TextField {
                            id: nameField
                            width: parent.width - saveButton.width - 8
                            height: 36
                            leftPadding: 12
                            rightPadding: 12
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Geist"
                            font.pixelSize: 13
                            color: theme.foreground
                            selectionColor: theme.accent
                            selectedTextColor: theme.accentForeground
                            maximumLength: 64
                            selectByMouse: true
                            Accessible.name: "New preset name"
                            onAccepted: drawer.save()
                            background: Rectangle {
                                radius: 7
                                color: theme.surface
                                border.color: nameField.activeFocus ? theme.accent : theme.border
                            }
                            Txt {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: nameField.length === 0 && nameField.preeditText.length === 0
                                size: 13
                                color: theme.secondary
                                text: "Preset name"
                            }
                        }
                        T.AbstractButton {
                            id: saveButton
                            readonly property bool ready: nameField.text.trim().length > 0 && !backend.busy && Object.keys(backend.values).length > 0
                            anchors.right: parent.right
                            width: saveLabel.implicitWidth + 32
                            height: 36
                            enabled: ready
                            opacity: ready ? 1 : 0.45
                            text: "Save"
                            Accessible.name: "Save preset"
                            onClicked: drawer.save()
                            background: Rectangle { radius: 7; color: theme.accent }
                            contentItem: Item {}
                            Txt {
                                id: saveLabel
                                anchors.centerIn: parent
                                size: 13
                                font.weight: Font.DemiBold
                                color: theme.accentForeground
                                text: saveButton.text
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                    Item { width: 1; height: 8 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "Saves the current readable hardware state. Factory presets keep your gain, headphone volume, and monitor settings." }
                }

                DrawerSection {
                    divided: false
                    bottomGap: 0
                    Txt { size: 14; font.weight: Font.DemiBold; text: "Device" }
                    Item { width: 1; height: 6 }
                    Txt { width: parent.width; size: 13; wrapMode: Text.WordWrap; text: backend.identity }
                    Item { width: 1; height: 4 }
                    Txt { width: parent.width; size: 12; color: theme.secondary; wrapMode: Text.WordWrap; text: "Each write requires an acknowledgement and a matching read-back. Power-cycle persistence needs a separate check." }
                    Item { width: 1; height: 12 }
                    Row {
                        spacing: 10
                        T.AbstractButton {
                            id: refreshButton
                            width: refreshLabel.implicitWidth + 30
                            height: 32
                            enabled: !backend.busy
                            hoverEnabled: true
                            text: "Read hardware state again"
                            Accessible.name: text
                            onClicked: backend.refresh()
                            background: Rectangle {
                                radius: 7
                                color: refreshButton.hovered ? theme.surface : "transparent"
                                border.color: theme.border
                            }
                            contentItem: Item {}
                            Txt { id: refreshLabel; anchors.centerIn: parent; size: 13; text: refreshButton.text }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                        Kbd { anchors.verticalCenter: parent.verticalCenter; text: "Ctrl R" }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Templates as T
import "Controls.js" as C

ApplicationWindow {
    id: win
    width: 1280
    height: 860
    minimumWidth: 480
    minimumHeight: 480
    visible: true
    title: "Podtune"
    color: theme.background
    font.family: "Geist"
    font.pixelSize: 14
    Material.theme: theme.dark ? Material.Dark : Material.Light
    Material.accent: theme.accent
    Material.primary: theme.surface
    Material.background: theme.surface
    Material.foreground: theme.foreground
    property bool exitApproved: false
    property bool dialogOpen: helpDialog.visible || exitDialog.visible
    property int selectedPreset: -1
    readonly property real frameWidth: Math.min(width, 1440)
    readonly property real frameX: Math.round((width - frameWidth) / 2)
    readonly property bool compact: frameWidth < 960

    readonly property var values: backend.previewValues
    readonly property var activePreset: selectedPreset >= 0 && selectedPreset < backend.presets.length ? backend.presets[selectedPreset] : null
    readonly property bool edited: activePreset !== null && backend.presetMatches[selectedPreset] !== true
    readonly property var marks: C.macros(values)
    readonly property bool connected: backend.identity.indexOf("firmware") >= 0
    readonly property var problems: [backend.error, audio.error].filter(function(text) { return text.length > 0 })
    readonly property var level: {
        const wave = audio.waveform
        const live = audio.active && wave.length > 0
        const peak = live ? C.db(C.tailPeak(wave, 8)) : -90
        const speech = live ? C.db(C.tailPeak(wave, 30)) : -90
        let status = "Not listening", dot = theme.border, ink = theme.secondary
        let guide = "Start a level check, then speak at your normal volume."
        if (live) {
            if (C.num(values.mute) > 0) {
                status = "Input muted"; guide = "The input is muted. Turn off Mute to check levels."
            } else if (speech > -3) {
                status = "Too high"; dot = theme.high; ink = theme.high
                guide = "Too high. Reduce the input gain to leave headroom."
            } else if (speech < -45) {
                status = "No speech"; guide = "No speech or a low signal. Speak closer to the microphone."
            } else if (speech < -18) {
                status = "Low signal"; dot = theme.secondary
                guide = "Low signal level. For speech, move closer or increase the input gain."
            } else if (speech > -6) {
                status = "High signal"; dot = theme.high; ink = theme.foreground
                guide = "High signal level. Reduce the input gain to leave more headroom."
            } else {
                status = "In target range"; dot = theme.accent; ink = theme.foreground
                guide = "The signal is within the target range of −18 to −6 dBFS."
            }
        }
        return {
            live: live, peak: peak, status: status, dot: dot, ink: ink, guide: guide,
            peakText: live ? C.signed(peak, 1) : "—",
            rmsText: live ? C.signed(Math.max(-90, audio.rmsDb), 1) + " dBFS" : "—",
            fill: live ? C.clamp((peak + 60) / 60, 0, 1) : 0
        }
    }

    function focusIsInteractive(textOnly) {
        var item = activeFocusItem
        while (item && item !== contentItem) {
            if (item instanceof TextInput || item instanceof TextEdit) return true
            if (!textOnly && item instanceof Control) return true
            item = item.parent
        }
        return false
    }
    function quitApp() {
        if (audio.recording || backend.busy) exitDialog.open()
        else Qt.quit()
    }
    function clock(seconds) {
        const whole = Math.floor(seconds)
        return Math.floor(whole / 60) + ":" + String(whole % 60).padStart(2, "0")
    }
    function supports(keys) {
        return keys.every(function(key) { return backend.supported[key] === true })
    }
    function applyPreset(index) {
        selectedPreset = index
        backend.applyPreset(index)
    }
    function savePreset(name) {
        const count = backend.presets.length
        backend.savePreset(name)
        if (backend.presets.length > count) selectedPreset = backend.presets.length - 1
    }
    function setMacro(key, m) {
        const changes = C.macroValues(key, m)
        for (const control in changes) {
            if (backend.supported[control] !== true) continue
            if (Math.abs(C.num(values[control]) - changes[control]) > 1e-6) backend.setControl(control, changes[control])
        }
    }

    Component.onCompleted: {
        if (selectedPreset < 0) selectedPreset = backend.presetMatches.indexOf(true)
    }
    onClosing: function(close) {
        if (!exitApproved && (audio.recording || backend.busy)) {
            close.accepted = false
            exitDialog.open()
        }
    }

    Connections {
        target: backend
        function onChanged() {
            if (win.selectedPreset < 0 || win.selectedPreset >= backend.presets.length)
                win.selectedPreset = backend.presetMatches.indexOf(true)
        }
    }
    Binding {
        target: audio
        property: "takeLabel"
        value: win.activePreset ? win.activePreset.name + (win.edited ? " · edited" : "") : "Custom"
    }

    Shortcut { sequence: "?"; enabled: !win.dialogOpen && !win.focusIsInteractive(true); context: Qt.ApplicationShortcut; onActivated: helpDialog.open() }
    Shortcut { sequence: "Q"; enabled: !win.dialogOpen && !win.focusIsInteractive(true); context: Qt.ApplicationShortcut; onActivated: win.quitApp() }
    Shortcut { sequence: "Space"; enabled: !win.dialogOpen && !win.focusIsInteractive(false); context: Qt.ApplicationShortcut; onActivated: audio.toggleRecord() }
    Shortcut { sequence: "Ctrl+Z"; enabled: !win.dialogOpen && !win.focusIsInteractive(true); context: Qt.ApplicationShortcut; onActivated: backend.undo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; enabled: !win.dialogOpen && !win.focusIsInteractive(true); context: Qt.ApplicationShortcut; onActivated: backend.redo() }
    Shortcut { sequence: "Ctrl+R"; enabled: !win.dialogOpen && !win.focusIsInteractive(true); context: Qt.ApplicationShortcut; onActivated: backend.refresh() }
    Shortcut { sequence: "Esc"; enabled: !win.dialogOpen && drawer.open; context: Qt.ApplicationShortcut; onActivated: drawer.open = false }

    Item {
        id: header
        width: parent.width
        height: 64

        Item {
            x: win.frameX
            width: win.frameWidth
            height: 63

            Image {
                x: 24
                y: 17.5
                width: 28
                height: 28
                source: "qrc:/podtune.svg"
                sourceSize: Qt.size(56, 56)
                smooth: true
                mipmap: true
            }
            Row {
                x: 66
                height: 63
                spacing: 14
                Txt {
                    visible: win.frameWidth >= 540
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16
                    font.weight: Font.DemiBold
                    tracking: -0.16
                    text: "Podtune"
                }
                Rectangle {
                    visible: identity.visible
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 18
                    color: theme.border
                }
                Row {
                    id: identity
                    readonly property int split: backend.identity.indexOf(" · ")
                    visible: win.frameWidth >= 720
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: win.connected ? theme.accent : theme.border
                    }
                    Txt { size: 13; text: identity.split < 0 ? backend.identity : backend.identity.slice(0, identity.split) }
                    Txt {
                        visible: identity.split >= 0 && win.frameWidth >= 900
                        size: 13
                        tnum: true
                        color: theme.secondary
                        text: identity.split < 0 ? "" : backend.identity.slice(identity.split + 3)
                    }
                }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 15.5
                height: 32
                spacing: 14

                Rectangle {
                    width: themeRow.implicitWidth + 6
                    height: 32
                    radius: 8
                    color: "transparent"
                    border.color: theme.border
                    Accessible.role: Accessible.Grouping
                    Accessible.name: "Theme mode"
                    Row {
                        id: themeRow
                        x: 3
                        y: 3
                        spacing: 2
                        Repeater {
                            model: [["Dark", "dark"], ["Light", "light"], ["Omarchy", "omarchy"]]
                            delegate: T.AbstractButton {
                                id: themeButton
                                required property var modelData
                                readonly property bool current: theme.mode === modelData[1]
                                width: themeLabel.implicitWidth + 22
                                height: 26
                                text: modelData[0]
                                Accessible.role: Accessible.RadioButton
                                Accessible.checked: current
                                Accessible.name: text
                                onClicked: theme.mode = modelData[1]
                                background: Rectangle { radius: 6; color: themeButton.current ? theme.line : "transparent" }
                                contentItem: Item {}
                                Txt {
                                    id: themeLabel
                                    anchors.centerIn: parent
                                    size: 12.5
                                    color: themeButton.current ? theme.foreground : theme.secondary
                                    text: themeButton.text
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
                T.AbstractButton {
                    id: helpButton
                    readonly property bool labeled: win.frameWidth >= 600
                    width: labeled ? helpLabel.implicitWidth + helpKey.width + 30 : helpKey.width + 22
                    height: 32
                    hoverEnabled: true
                    text: "Help"
                    Accessible.name: text
                    onClicked: helpDialog.open()
                    background: Rectangle { radius: 7; color: helpButton.hovered ? theme.surface : "transparent" }
                    contentItem: Item {}
                    Txt {
                        id: helpLabel
                        visible: helpButton.labeled
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13
                        color: helpButton.hovered ? theme.foreground : theme.secondary
                        text: helpButton.text
                    }
                    Kbd {
                        id: helpKey
                        x: helpButton.labeled ? helpLabel.implicitWidth + 20 : 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: "?"
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
                T.AbstractButton {
                    id: advancedButton
                    width: advancedLabel.implicitWidth + 32
                    height: 32
                    hoverEnabled: true
                    text: "Advanced"
                    Accessible.name: text
                    onClicked: drawer.show("")
                    background: Rectangle {
                        radius: 7
                        color: advancedButton.hovered ? theme.surface : "transparent"
                        border.color: advancedButton.hovered ? theme.secondary : theme.border
                    }
                    contentItem: Item {}
                    Txt {
                        id: advancedLabel
                        anchors.centerIn: parent
                        size: 13
                        font.weight: Font.Medium
                        text: advancedButton.text
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: theme.border }
    }

    Flickable {
        id: page
        anchors.top: header.bottom
        anchors.bottom: footer.top
        width: parent.width
        contentWidth: width
        contentHeight: Math.max(height, body.implicitHeight)
        interactive: contentHeight > height + 0.5
        acceptedButtons: Qt.NoButton
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        WheelScroll { id: pageScroll; flickable: page }

        Item {
            id: body
            // Two columns from 960 pixels. Below that width, one centered column.
            readonly property real rightWidth: Math.round(Math.max(360, Math.min(440, (width - 105) * 0.375)))
            readonly property real leftWidth: width - 105 - rightWidth
            readonly property real columnWidth: Math.min(width - 48, 680)
            readonly property real columnX: Math.round((width - columnWidth) / 2)
            x: win.frameX
            width: win.frameWidth
            height: page.contentHeight
            implicitHeight: win.compact ? voice.y + voice.implicitHeight + 22
                : 22 + Math.max(tune.implicitHeight, voice.minimumHeight) + 22

            TuneSection {
                id: tune
                app: win
                outerScroll: pageScroll
                x: win.compact ? body.columnX : 24
                y: 22
                width: win.compact ? body.columnWidth : body.leftWidth
                onOpenDrawer: function(target) { drawer.show(target) }
            }
            Rectangle {
                visible: !win.compact
                x: 24 + body.leftWidth + 28
                y: 22
                width: 1
                height: body.height - 44
                color: theme.border
            }
            Rectangle {
                visible: win.compact
                x: body.columnX
                y: tune.y + tune.implicitHeight + 28
                width: body.columnWidth
                height: 1
                color: theme.border
            }
            VoiceSection {
                id: voice
                app: win
                outerScroll: pageScroll
                x: win.compact ? body.columnX : body.width - 24 - body.rightWidth
                y: win.compact ? tune.y + tune.implicitHeight + 57 : 22
                width: win.compact ? body.columnWidth : body.rightWidth
                height: win.compact ? implicitHeight : body.height - 44
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 36

        Rectangle { width: parent.width; height: 1; color: theme.border }
        Item {
            x: win.frameX
            width: win.frameWidth
            height: 36

            Rectangle {
                x: 24
                y: 15.5
                width: 6
                height: 6
                radius: 3
                color: win.problems.length ? theme.high : backend.busy ? theme.secondary : theme.accent
            }
            Txt {
                id: notice
                x: 40
                y: 1 + (35 - height) / 2
                width: (hints.visible ? hints.x - 10 : parent.width - 24) - x
                size: 12
                elide: Text.ElideRight
                color: win.problems.length ? theme.foreground : theme.secondary
                text: win.problems.length ? win.problems.join(" ")
                    : backend.busy ? "Read and verify the microphone settings…"
                    : backend.notice.length ? backend.notice
                    : "Audio tests work without HID access. DSP controls require device access."
                HoverHandler { id: noticeHover }
                ToolTip.visible: noticeHover.hovered && truncated
                ToolTip.text: text
            }
            Row {
                id: hints
                visible: win.frameWidth >= 760
                anchors.right: parent.right
                anchors.rightMargin: 24
                y: 9.5
                spacing: 14
                Repeater {
                    model: [["Space", "Record"], ["Ctrl Z", "Undo"], ["?", "Help"]]
                    delegate: Row {
                        required property var modelData
                        spacing: 6
                        Kbd { text: parent.modelData[0] }
                        Txt { anchors.verticalCenter: parent.verticalCenter; size: 12; color: theme.secondary; text: parent.modelData[1] }
                    }
                }
            }
        }
    }

    AdvancedDrawer {
        id: drawer
        anchors.fill: parent
        level: win.level
        onSavePreset: function(name) { win.savePreset(name) }
    }

    HelpDialog { id: helpDialog }

    Popup {
        id: exitDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(420, win.width - 32)
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
            spacing: 10
            Txt { size: 17; font.weight: Font.DemiBold; text: "Finish the current task?" }
            Txt {
                width: exitDialog.width - 54
                size: 13.5
                wrapMode: Text.WordWrap
                text: "Quit saves the current voice test and waits for the hardware command to finish."
            }
            Item { width: 1; height: 8 }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 27
                spacing: 10
                T.AbstractButton {
                    id: stayButton
                    width: stayLabel.implicitWidth + 32
                    height: 36
                    hoverEnabled: true
                    text: "Keep working"
                    Accessible.name: text
                    onClicked: exitDialog.close()
                    background: Rectangle { radius: 7; color: stayButton.hovered ? theme.background : "transparent"; border.color: theme.border }
                    contentItem: Item {}
                    Txt { id: stayLabel; anchors.centerIn: parent; size: 13; font.weight: Font.Medium; text: stayButton.text }
                }
                T.AbstractButton {
                    id: quitButton
                    width: quitLabel.implicitWidth + 32
                    height: 36
                    text: "Quit"
                    Accessible.name: text
                    onClicked: { win.exitApproved = true; Qt.quit() }
                    background: Rectangle { radius: 7; color: theme.accent }
                    contentItem: Item {}
                    Txt { id: quitLabel; anchors.centerIn: parent; size: 13; font.weight: Font.DemiBold; color: theme.accentForeground; text: quitButton.text }
                }
            }
        }
    }
}

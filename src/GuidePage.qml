import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import "Guide.js" as G

// A full-window page that explains each control. show(topic) opens the page at one topic.
Item {
    id: page
    property bool open: false
    property real progress: open ? 1 : 0
    property string highlighted: ""
    readonly property var topics: G.order()
    readonly property bool wide: width >= 900
    readonly property real columnWidth: Math.min(640, width - 48 - (wide ? 248 : 0))
    readonly property real columnX: wide ? Math.round((width - 248 - columnWidth) / 2) + 248 : Math.round((width - columnWidth) / 2)
    readonly property string current: {
        const top = body.contentY + 48
        let id = topics[0]
        for (let i = 0; i < sections.count; i++) {
            const item = sections.itemAt(i)
            if (item && item.y <= top) id = item.topic
        }
        return id
    }
    visible: progress > 0
    Behavior on progress { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    function show(topic) {
        open = true
        Qt.callLater(function() { scrollTo(topic) })
    }
    function scrollTo(topic) {
        const index = topics.indexOf(topic)
        const item = index >= 0 ? sections.itemAt(index) : null
        scroller.to = item ? Math.max(0, Math.min(item.y - 20, body.contentHeight - body.height)) : 0
        scroller.restart()
        highlighted = ""
        highlighted = topic
        flash.restart()
    }

    Timer { id: flash; interval: 1600; onTriggered: page.highlighted = "" }
    NumberAnimation { id: scroller; target: body; property: "contentY"; duration: 260; easing.type: Easing.OutCubic }

    Rectangle {
        anchors.fill: parent
        color: theme.background
        opacity: page.progress
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: function(wheel) { wheel.accepted = true }
        }
    }

    Item {
        anchors.fill: parent
        opacity: page.progress
        transform: Translate { y: (1 - page.progress) * 12 }

        Item {
            id: header
            width: parent.width
            height: 64

            Column {
                x: 24
                y: 11.9
                Txt { size: 16; font.weight: Font.DemiBold; text: "Guide" }
                Txt { size: 12; color: theme.secondary; text: "What each control does" }
            }
            T.AbstractButton {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: 14
                y: 16
                width: 32
                height: 32
                hoverEnabled: true
                Accessible.name: "Close the guide"
                onClicked: page.open = false
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
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: theme.border }
        }

        Flickable {
            id: body
            y: 64
            width: parent.width
            height: parent.height - 64
            clip: true
            contentHeight: content.implicitHeight + 64
            acceptedButtons: Qt.NoButton
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            WheelScroll { flickable: body }

            Column {
                id: content
                x: page.columnX
                y: 8
                width: page.columnWidth

                Repeater {
                    id: sections
                    model: page.topics
                    delegate: Column {
                        id: section
                        required property string modelData
                        required property int index
                        readonly property string topic: modelData
                        readonly property var info: G.TOPICS[modelData]
                        readonly property var group: G.GROUPS.find(function(g) { return g.topics[0] === section.topic })
                        width: content.width
                        topPadding: index === 0 ? 20 : group ? 48 : 32

                        SectionLabel {
                            visible: section.group !== undefined
                            text: section.group ? section.group.title : ""
                        }
                        Item { visible: section.group !== undefined; width: 1; height: 14 }
                        Item {
                            width: parent.width
                            height: title.height
                            Rectangle {
                                x: -14
                                width: 3
                                height: parent.height
                                radius: 1.5
                                color: theme.accent
                                opacity: page.highlighted === section.topic ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                            Txt { id: title; size: 17; font.weight: Font.DemiBold; text: section.info.title }
                        }
                        Item { width: 1; height: 4 }
                        Txt { width: parent.width; size: 13.5; color: theme.secondary; wrapMode: Text.WordWrap; text: section.info.summary }

                        Column {
                            visible: (section.info.body || []).length > 0
                            width: parent.width
                            topPadding: 12
                            spacing: 10
                            Repeater {
                                model: section.info.body || []
                                delegate: Txt {
                                    required property string modelData
                                    width: section.width
                                    size: 13.5
                                    lh: 1.55
                                    wrapMode: Text.WordWrap
                                    text: modelData
                                }
                            }
                        }

                        Column {
                            visible: (section.info.steps || []).length > 0
                            width: parent.width
                            topPadding: 12
                            spacing: 6
                            Repeater {
                                model: section.info.steps || []
                                delegate: Item {
                                    required property string modelData
                                    required property int index
                                    width: section.width
                                    height: stepText.height
                                    Txt { width: 16.4; horizontalAlignment: Text.AlignRight; size: 13.5; lh: 1.55; color: theme.secondary; text: (parent.index + 1) + "." }
                                    Txt { id: stepText; x: 24; width: parent.width - 24; size: 13.5; lh: 1.55; wrapMode: Text.WordWrap; text: parent.modelData }
                                }
                            }
                        }

                        Column {
                            visible: (section.info.terms || []).length > 0
                            width: parent.width
                            topPadding: 14
                            spacing: 10
                            Repeater {
                                model: section.info.terms || []
                                delegate: Item {
                                    required property var modelData
                                    width: section.width
                                    height: Math.max(termLabel.height, termKey.height, termText.height)
                                    Txt {
                                        id: termLabel
                                        visible: !section.info.keys
                                        width: 112
                                        size: 13
                                        lh: 1.55
                                        font.weight: Font.DemiBold
                                        wrapMode: Text.WordWrap
                                        text: parent.modelData[0]
                                    }
                                    Kbd {
                                        id: termKey
                                        visible: section.info.keys === true
                                        y: 1
                                        size: 11
                                        lineSize: 18
                                        pad: 6
                                        textColor: theme.foreground
                                        text: parent.modelData[0]
                                    }
                                    Txt {
                                        id: termText
                                        x: 128
                                        width: parent.width - 128
                                        size: 13
                                        lh: 1.55
                                        color: theme.secondary
                                        wrapMode: Text.WordWrap
                                        text: parent.modelData[1]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: tocView
            visible: page.wide
            x: Math.max(24, page.columnX - 248)
            y: 64
            width: 200
            height: parent.height - 64
            clip: true
            contentHeight: toc.implicitHeight + 48
            acceptedButtons: Qt.NoButton
            boundsBehavior: Flickable.StopAtBounds
            WheelScroll { flickable: tocView }

            Column {
                id: toc
                y: 28
                width: parent.width
                Repeater {
                    model: G.GROUPS
                    delegate: Column {
                        required property var modelData
                        required property int index
                        width: toc.width
                        topPadding: index === 0 ? 0 : 20
                        spacing: 2
                        SectionLabel { text: parent.modelData.title }
                        Item { width: 1; height: 6 }
                        Repeater {
                            model: parent.modelData.topics
                            delegate: T.AbstractButton {
                                id: entry
                                required property string modelData
                                readonly property bool active: page.current === modelData
                                width: toc.width
                                height: 28
                                hoverEnabled: true
                                text: G.TOPICS[modelData].title
                                Accessible.name: text
                                onClicked: page.scrollTo(modelData)
                                background: Rectangle {
                                    radius: 6
                                    color: entry.hovered ? theme.surface : "transparent"
                                    Rectangle {
                                        x: 0
                                        y: 7
                                        width: 2
                                        height: 14
                                        radius: 1
                                        color: theme.accent
                                        visible: entry.active
                                    }
                                }
                                contentItem: Item {}
                                Txt {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 13
                                    color: entry.active || entry.hovered ? theme.foreground : theme.secondary
                                    font.weight: entry.active ? Font.Medium : Font.Normal
                                    text: entry.text
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
        }
    }
}

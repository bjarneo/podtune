import QtQuick
import QtQuick.Templates as T

// One macro control in the Tone card: a title, a tick slider, the hardware detail, and the value.
Item {
    id: row
    property string title
    property string subtitle
    property string detailLabel
    property string detail
    property int value: 0
    property bool available: true
    property bool divided: false
    signal commit(int value)
    signal openDetail()
    // Below 600 pixels, the title and the value sit above the slider.
    readonly property bool stacked: width < 600
    implicitHeight: (stacked ? 148.3 : 92.8) + (divided ? 1 : 0)

    Rectangle { visible: row.divided; width: parent.width; height: 1; color: theme.line }

    Item {
        id: box
        x: 20
        y: 18 + (row.divided ? 1 : 0)
        width: row.width - 40
        height: row.stacked ? 112.3 : 56.8
        opacity: row.available ? 1 : 0.45

        Column {
            id: titles
            y: row.stacked ? 0 : Math.round(box.height / 2) - Math.round(41.5 / 2)
            width: row.stacked ? box.width - 80 : 148
            spacing: 3
            Txt { width: parent.width; size: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; text: row.title }
            Txt { width: parent.width; size: 12.5; color: theme.secondary; elide: Text.ElideRight; text: row.subtitle }
        }

        Item {
            x: row.stacked ? 0 : 172
            y: row.stacked ? 55.5 : 0
            width: row.stacked ? box.width : box.width - 148 - 64 - 48
            height: 56.8

            T.Slider {
                id: slider
                width: parent.width
                height: 32
                from: 0
                to: 100
                stepSize: 1
                leftPadding: 1
                rightPadding: 1
                topPadding: 0
                bottomPadding: 0
                value: row.value
                enabled: row.available
                focusPolicy: Qt.StrongFocus
                Accessible.name: row.title
                onMoved: row.commit(Math.round(value))
                Keys.onPressed: function(event) {
                    const steps = { [Qt.Key_Right]: 3, [Qt.Key_Up]: 3, [Qt.Key_Left]: -3, [Qt.Key_Down]: -3,
                                    [Qt.Key_PageUp]: 30, [Qt.Key_PageDown]: -30 }
                    const next = event.key === Qt.Key_Home ? 0 : event.key === Qt.Key_End ? 100
                        : steps[event.key] !== undefined ? row.value + steps[event.key] : NaN
                    if (isNaN(next)) return
                    event.accepted = true
                    row.commit(Math.min(100, Math.max(0, next)))
                }
                handle: null
                background: Item {
                    readonly property int current: Math.round(row.value / 100 * 63)
                    Repeater {
                        model: 64
                        delegate: Rectangle {
                            required property int index
                            readonly property bool lit: row.value > 0 && index < parent.current
                            readonly property bool knob: index === parent.current
                            x: index * (2 + (slider.width - 128) / 63)
                            y: (32 - height) / 2
                            width: 2
                            height: lit ? 20 : knob ? (row.value > 0 ? 30 : 20) : 10
                            radius: 1
                            color: lit ? theme.accent : knob ? (row.value > 0 ? theme.foreground : theme.secondary) : theme.border
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -6
                        radius: 7
                        color: "transparent"
                        border.width: 2
                        border.color: theme.accent
                        visible: slider.visualFocus
                    }
                }
                HoverHandler { cursorShape: Qt.SizeHorCursor }
            }

            T.AbstractButton {
                id: link
                y: 40
                width: Math.min(detailText.x + detailText.implicitWidth, parent.width)
                height: linkLabel.height
                hoverEnabled: true
                Accessible.name: row.detailLabel + " settings"
                onClicked: row.openDetail()
                contentItem: Item {}
                Txt { id: linkLabel; size: 12; color: link.hovered ? theme.foreground : theme.secondary; text: row.detailLabel }
                Txt {
                    id: detailText
                    x: linkLabel.implicitWidth + 8
                    width: Math.max(0, link.width - x)
                    anchors.baseline: linkLabel.baseline
                    size: 11.5
                    mono: true
                    elide: Text.ElideRight
                    text: row.detail
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        Txt {
            x: box.width - 64
            y: Math.round(((row.stacked ? 41.5 : box.height) - height) / 2)
            width: 64
            horizontalAlignment: Text.AlignRight
            size: row.value > 0 ? 28 : 15
            lh: 1
            mono: true
            tnum: true
            tracking: -0.02 * size
            color: row.value > 0 ? theme.foreground : theme.secondary
            text: row.value > 0 ? String(row.value) : "Off"
        }
    }
}

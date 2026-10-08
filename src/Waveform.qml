import QtQuick
import QtQuick.Shapes

// The last 100 level intervals. The shaded band marks the speech target from -18 to -6 dBFS.
Item {
    id: view
    property var samples: []
    property bool dimmed: false
    readonly property real bandWidth: width - 30
    readonly property real middle: height / 2
    readonly property real half: (height - 8) / 2
    readonly property real a18: Math.sqrt(Math.pow(10, -18 / 20)) * half
    readonly property real a6: Math.sqrt(Math.pow(10, -6 / 20)) * half
    readonly property real step: bandWidth / 100
    implicitWidth: 402
    implicitHeight: 150

    Rectangle { y: view.middle - view.a6; width: view.bandWidth; height: view.a6 - view.a18; color: theme.accent; opacity: 0.08 }
    Rectangle { y: view.middle + view.a18; width: view.bandWidth; height: view.a6 - view.a18; color: theme.accent; opacity: 0.08 }

    component Guide: ShapePath {
        property real level
        strokeColor: theme.accent
        strokeWidth: 1
        strokeStyle: ShapePath.DashLine
        dashPattern: [2, 3]
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        startX: 0
        startY: Math.round(level) + 0.5
        PathLine { x: view.bandWidth; y: Math.round(level) + 0.5 }
    }
    Shape {
        anchors.fill: parent
        opacity: 0.35
        Guide { level: view.middle - view.a6 }
        Guide { level: view.middle - view.a18 }
        Guide { level: view.middle + view.a18 }
        Guide { level: view.middle + view.a6 }
    }

    Rectangle { y: view.middle - 0.5; width: view.bandWidth; height: 1; color: theme.border }

    Repeater {
        model: 100
        delegate: Rectangle {
            required property int index
            readonly property int sample: index - (100 - view.samples.length)
            readonly property real level: sample >= 0 ? view.samples[sample] : 0
            visible: sample >= 0
            antialiasing: true
            x: index * view.step + 0.4
            width: Math.max(1, view.step - 1.5)
            height: Math.max(1, Math.sqrt(level) * (view.height - 8))
            y: view.middle - height / 2
            color: level > 0.7079 ? theme.high : theme.accent
            opacity: (view.dimmed ? 0.25 : 1) * (0.4 + 0.6 * index / 99)
        }
    }

    Repeater {
        model: [["−6", view.middle - view.a6], ["−18", view.middle - view.a18],
                ["−18", view.middle + view.a18], ["−6", view.middle + view.a6]]
        delegate: Txt {
            required property var modelData
            anchors.right: parent.right
            y: modelData[1] - height / 2
            size: 10
            lh: 1
            mono: true
            color: theme.secondary
            text: modelData[0]
        }
    }
}

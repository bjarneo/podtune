import QtQuick
import QtQuick.Shapes
import "Controls.js" as C

// The static compressor transfer curve, from -60 dBFS to 0 dBFS input.
Item {
    id: curve
    property bool active: false
    property real threshold: -20
    property real ratio: 2
    property real makeup: 0
    readonly property real sx: width / 396
    readonly property real gain: active ? makeup : 0
    readonly property color ink: active ? theme.accent : theme.secondary
    readonly property var points: active
        ? [[-60, -60 + gain], [threshold, threshold + gain], [0, threshold - threshold / ratio + gain]]
        : [[-60, -60], [0, 0]]
    implicitHeight: 110

    function px(db) { return (db + 60) / 60 * 396 * sx }
    function py(db) { return 110 - (C.clamp(db, -60, 0) + 60) / 60 * 110 }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: theme.border
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 4]
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            startX: 0
            startY: 110
            PathLine { x: curve.width; y: 0 }
        }
        ShapePath {
            strokeColor: theme.line
            strokeWidth: 1
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            startX: curve.px(curve.threshold)
            startY: 0
            PathLine { x: curve.px(curve.threshold); y: 110 }
        }
        ShapePath {
            strokeColor: curve.ink
            strokeWidth: 2
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: curve.points.map(function(p) { return Qt.point(curve.px(p[0]), curve.py(p[1])) }) }
        }
    }
    Rectangle {
        x: curve.px(curve.threshold) - 3.5
        y: curve.py(curve.threshold + curve.gain) - 3.5
        width: 7
        height: 7
        radius: 3.5
        color: curve.ink
    }
}

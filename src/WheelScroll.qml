import QtQuick

// Scrolls a Flickable without inertia. A mouse wheel step animates for 110 ms.
// A touchpad moves the content by the exact pixel delta.
// When the view is at the end of its range, the outer WheelScroll receives the scroll.
WheelHandler {
    id: handler
    required property Flickable flickable
    property bool horizontal: false
    property real step: 96
    property var outer: null
    // With Shift held, this WheelScroll receives the scroll instead. Use it for a horizontal list.
    property var shiftScroll: null
    // A forwarding handler never moves its own view. Use it to pass vertical scrolls out of a horizontal list.
    property bool forwardOnly: false
    target: null
    orientation: horizontal && !forwardOnly ? Qt.Horizontal : Qt.Vertical
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) {
        if (shiftScroll !== null && (event.modifiers & Qt.ShiftModifier)) {
            shiftScroll.scroll(event.pixelDelta.y || event.pixelDelta.x, event.angleDelta.y || event.angleDelta.x)
            event.accepted = true
            return
        }
        const pixel = orientation === Qt.Horizontal ? event.pixelDelta.x : event.pixelDelta.y
        const angle = orientation === Qt.Horizontal ? event.angleDelta.x : event.angleDelta.y
        if (pixel === 0 && angle === 0) {
            event.accepted = false
            return
        }
        event.accepted = (!forwardOnly && scroll(pixel, angle)) || (outer !== null && outer.scroll(pixel, angle)) || outer !== null
    }

    function scroll(pixel, angle) {
        const delta = pixel !== 0 ? pixel : angle / 120 * step
        const start = horizontal ? flickable.originX : flickable.originY
        const extent = Math.max(0, horizontal ? flickable.contentWidth - flickable.width : flickable.contentHeight - flickable.height)
        const current = glide.running ? glide.to : horizontal ? flickable.contentX : flickable.contentY
        const next = Math.max(start, Math.min(start + extent, current - delta))
        if (Math.abs(next - current) < 0.01) return false
        flickable.cancelFlick()
        if (pixel !== 0) {
            glide.stop()
            if (horizontal) flickable.contentX = next
            else flickable.contentY = next
        } else {
            glide.to = next
            glide.restart()
        }
        return true
    }

    property NumberAnimation glide: NumberAnimation {
        target: handler.flickable
        property: handler.horizontal ? "contentX" : "contentY"
        duration: 110
        easing.type: Easing.OutCubic
    }
}

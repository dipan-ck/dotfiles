import QtQuick

Item {
    id: metric
    property string icon:         ""
    property real   percent:      0
    property color  colorAccent:  "#000000"
    property color  colorSurface: "#000000"
    property real   circleSize:   22
    property real   iconSize:     18
    property color  iconColor:    "#111111"
    property real   bgArcOpacity:   0.60
    property real   fillArcOpacity: 0.95

    property real visualPercent: 0
    Behavior on visualPercent { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
    onPercentChanged:       visualPercent = percent
    onVisualPercentChanged: pieCanvas.requestPaint()
    onVisibleChanged:       if (visible) pieCanvas.requestPaint()
    Component.onCompleted:  pieCanvas.requestPaint()
    onColorAccentChanged:   pieCanvas.requestPaint()
    onColorSurfaceChanged:  pieCanvas.requestPaint()

    width:  circleSize
    height: circleSize

    Canvas {
        id: pieCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx   = width  / 2
            const cy   = height / 2
            const r    = cx - 0.5
            const p    = Math.min(Math.max(metric.visualPercent, 0), 100)
            const ac   = metric.colorAccent
            const r255 = v => Math.round(v * 255)

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fillStyle = `rgba(${r255(ac.r)},${r255(ac.g)},${r255(ac.b)},${metric.bgArcOpacity})`
            ctx.fill()

            if (p > 0) {
                const startA = -Math.PI / 2
                const endA   = startA + (p / 100) * Math.PI * 2
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.arc(cx, cy, r, startA, endA)
                ctx.closePath()
                ctx.fillStyle = `rgba(${r255(ac.r)},${r255(ac.g)},${r255(ac.b)},${metric.fillArcOpacity})`
                ctx.fill()
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text:             metric.icon
        font.family:      "JetBrainsMono Nerd Font"
        font.pixelSize:   metric.iconSize
        color:            metric.iconColor
        renderType:       Text.NativeRendering
    }
}

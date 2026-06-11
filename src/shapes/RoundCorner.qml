import QtQuick

/*!
    RoundCorner.qml — single rounded screen corner.
    Ported from NothingLess. Draws a quarter-circle filled with
    the current theme background color to mask sharp screen edges.
*/
Item {
    id: root

    enum Corner {
        TopLeft, TopRight, BottomLeft, BottomRight
    }

    property int corner: RoundCorner.Corner.TopLeft
    property int size: Theme.cornerRadius
    property color maskColor: Theme.background

    implicitWidth: size
    implicitHeight: size

    onMaskColorChanged: canvas.requestPaint()
    onCornerChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()
    onVisibleChanged: { if (visible) canvas.requestPaint() }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.Image

        onPaint: {
            var ctx = getContext("2d")
            var r = root.size
            var c = root.maskColor
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()

            switch (root.corner) {
            case RoundCorner.Corner.TopLeft:
                ctx.arc(r, r, r, Math.PI, 3 * Math.PI / 2)
                ctx.lineTo(0, 0)
                break
            case RoundCorner.Corner.TopRight:
                ctx.arc(0, r, r, 3 * Math.PI / 2, 2 * Math.PI)
                ctx.lineTo(r, 0)
                break
            case RoundCorner.Corner.BottomLeft:
                ctx.arc(r, 0, r, Math.PI / 2, Math.PI)
                ctx.lineTo(0, r)
                break
            case RoundCorner.Corner.BottomRight:
                ctx.arc(0, 0, r, 0, Math.PI / 2)
                ctx.lineTo(r, r)
                break
            }

            ctx.closePath()
            ctx.fillStyle = c
            ctx.fill()
        }
    }
}

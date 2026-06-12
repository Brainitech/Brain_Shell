import QtQuick
import "../"
import "../theme"

Rectangle {
    id: root
    width: 24
    height: 24
    radius: 4

    color: hover.hovered ? Theme.active : "transparent"

    property string text: ""
    property color textColor: Theme.text
    signal clicked()

    // ── Micro-interactions: organic hover + press feedback ──────────────
    scale: press.pressed ? 0.92 : (hover.hovered ? 1.08 : 1.0)
    Behavior on scale { NumberAnimation { duration: Anim.microHover; easing: Anim.outBack } }
    Behavior on color { ColorAnimation { duration: Anim.microHover } }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: hover.hovered ? Theme.background : root.textColor
        font.pixelSize: 14
        scale: press.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: Anim.microPress; easing: Anim.outBack } }
        Behavior on color { ColorAnimation { duration: Anim.microHover } }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    MouseArea {
        id: press
        anchors.fill: parent
        onClicked: root.clicked()
    }
}

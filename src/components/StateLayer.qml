import QtQuick
import "../theme"

/*!
    StateLayer — Material 3 interaction overlay.

    Provides hover, press, and focus visual feedback as an overlay
    on top of a parent item. Use inside a MouseArea.

    Usage:
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            StateLayer {
                anchors.fill: parent
                hovered: ma.containsMouse
                pressed: ma.pressed
            }
        }
*/
Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool focused: false

    // Opacity levels (M3 spec)
    property real hoverOpacity: 0.08
    property real pressOpacity: 0.12
    property real focusOpacity: 0.12

    color: Theme.text
    opacity: 0
    radius: parent ? parent.radius : 0

    states: [
        State { name: "pressed"; when: root.pressed
            PropertyChanges { target: root; opacity: root.pressOpacity } },
        State { name: "hovered"; when: root.hovered && !root.pressed
            PropertyChanges { target: root; opacity: root.hoverOpacity } },
        State { name: "focused"; when: root.focused && !root.hovered && !root.pressed
            PropertyChanges { target: root; opacity: root.focusOpacity } }
    ]

    transitions: [
        Transition {
            from: ""; to: "*"
            NumberAnimation { property: "opacity"; duration: Anim.standardSmall; easing.type: Anim.easing("standard").type }
        }
    ]
}

import QtQuick
import "../"

// Reusable vertical tab column.
// Supports mouse wheel scrolling to cycle pages.
// Parent Row decides whether it sits left or right.

Item {
    id: root

    property var    model:       []
    property string currentPage: ""

    signal pageChanged(string key)

    implicitWidth:  col.implicitWidth
    implicitHeight: col.implicitHeight

    // ── Wheel: cycle through pages ────────────────────────────────────────────
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            var keys = root.model.map(function(m) { return m.key })
            var idx  = keys.indexOf(root.currentPage)
            if (event.angleDelta.y < 0)
                idx = (idx + 1) % keys.length          // scroll down → next
            else
                idx = (idx - 1 + keys.length) % keys.length  // scroll up → prev
            root.pageChanged(keys[idx])
        }
    }

    Column {
        id: col
        anchors.centerIn: parent
        // spacing: 8
        spacing : (parent.height - model.length * tabHeight) / (model.length - 1)

        Repeater {
            model: root.model

            delegate: Rectangle {
                width:  40
                height: 60
                radius: Theme.cornerRadius * 2

                color: root.currentPage === modelData.key
                           ? Theme.active
                           : (hov.hovered ? Qt.rgba(1,1,1,0.08) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text:            modelData.icon
                    font.pixelSize:  16
                    color: root.currentPage === modelData.key
                               ? Theme.background
                               : Theme.text
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked:    root.pageChanged(modelData.key)
                }
            }
        }
    }
}

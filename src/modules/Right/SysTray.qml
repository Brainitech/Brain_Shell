import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import "../../components"
import "../../"

RowLayout {
    id: root
    property real localScale: 1.0

    RowLayout {
        id: trayRow
        Layout.alignment: Qt.AlignVCenter
        
        // Custom state for toggling
        property bool isOpen: false

        // UX: Smooth fade and slide animation instead of abruptly disappearing
        visible: opacity > 0
        opacity: isOpen ? 1 : 0
        Layout.preferredWidth: isOpen ? implicitWidth : 0
        clip: true

        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }

        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                // UX: Larger 28x28 hit-box makes it easier to click than a 16x16 icon
                width: Math.round(26 * localScale)
                height: Math.round(26 * localScale)
                radius: Math.round(6 * localScale)
                color: trayMouse.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent" // Subtle hover effect
                
                Image {
                    width: Math.round(16 * localScale)
                    height: Math.round(16 * localScale)
                    anchors.centerIn: parent
                    source: modelData.icon
                    smooth: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor // Visual cue that it's clickable
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            // Support for native context menus if Quickshell exposes it
                            if (typeof modelData.contextMenu === "function") {
                                modelData.contextMenu() 
                            }
                        }
                    }
                }
            }
        }
    }

    // Tray Toggle Button
    IconBtn {
        localScale: root.localScale
        Layout.alignment: Qt.AlignVCenter
        text: trayRow.isOpen ? "" : ""
        onClicked: trayRow.isOpen = !trayRow.isOpen
    }
}
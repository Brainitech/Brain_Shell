import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import "../../components"
import "../../windows"
import "../../"
import "../../theme"

RowLayout {
    id: root

    // Wrap tray icons in a Flickable to prevent clipping when many items are present
    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: trayRow.isOpen ? Math.min(trayRow.implicitWidth, 260) : 0
        Layout.preferredHeight: 26
        clip: true

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: Anim.standardSmall; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve }
        }

        Flickable {
            id: trayFlick
            anchors.fill: parent
            contentWidth: trayRow.implicitWidth
            contentHeight: 26
            boundsBehavior: Flickable.StopAtBounds
            interactive: trayRow.isOpen && trayRow.implicitWidth > parent.width

            RowLayout {
                id: trayRow
                anchors.verticalCenter: parent.verticalCenter

                // Custom state for toggling
                property bool isOpen: false

                opacity: isOpen ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Anim.standardSmall; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve }
                }

                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        // UX: Larger 28x28 hit-box makes it easier to click than a 16x16 icon
                        width: 26
                        height: 26
                        radius: 6
                        color: trayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent" // Subtle hover effect

                        Image {
                            width: 16
                            height: 16
                            anchors.centerIn: parent
                            source: modelData.icon
                            smooth: true
                            sourceSize.width:  16
                            sourceSize.height: 16
                            asynchronous: true
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
        }
    }

    // Tray Toggle Button
    IconBtn {
        Layout.alignment: Qt.AlignVCenter
        text: trayRow.isOpen ? "" : ""
        onClicked: trayRow.isOpen = !trayRow.isOpen
    }
}
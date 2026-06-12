import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import "../../components"
import "../../windows"
import "../../"

RowLayout {
    id: root

    RowLayout {
        id: trayRow
        Layout.alignment: Qt.AlignVCenter

        property bool isOpen: false

        // Smooth fade-and-slide instead of abrupt disappearance
        visible: opacity > 0
        opacity: isOpen ? 1 : 0
        Layout.preferredWidth: isOpen ? implicitWidth : 0
        clip: true

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                width: 26
                height: 26
                radius: 6
                color: trayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                Image {
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    source: modelData.icon
                    smooth: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
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
        Layout.alignment: Qt.AlignVCenter
        text: trayRow.isOpen ? "" : ""
        onClicked: trayRow.isOpen = !trayRow.isOpen
    }
}

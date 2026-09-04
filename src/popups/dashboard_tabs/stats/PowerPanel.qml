import QtQuick
import "../../"
import "../../../"
import "../../../components"

Item {
    id: root

    property real localScale: 1.0
    required property var cpuFreqService
    required property var envyService

    Column {
        anchors.centerIn: parent
        spacing:          Math.round(16 * localScale)

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)

            // Label + lock icon hinting auto-cpufreq manages this
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(5 * localScale)

                Text {
                    text:           "󰌾"
                    font.pixelSize: Math.round(11 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:           "Power Profile"
                    font.pixelSize: Math.round(11 * localScale)
                    font.weight:    Font.Medium
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)

                ProfileButton {
                    localScale: root.localScale
                    label:     root.cpuFreqService.activeProfile === "performance" ? "Performance" : "Power Saver"
                    active:    true
                    enabled:   true
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width:  Math.round(200 * localScale)
            height: 1
            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU Mode"
                font.pixelSize: Math.round(11 * localScale)
                font.weight:    Font.Medium
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)

                ProfileButton {
                    localScale: root.localScale
                    label:     "Integrated"
                    active:    root.envyService.currentMode === "integrated"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("integrated")
                }
                ProfileButton {
                    localScale: root.localScale
                    label:     "Hybrid"
                    active:    root.envyService.currentMode === "hybrid"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("hybrid")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU mode switch requires a reboot"
                font.pixelSize: Math.round(10 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
        }
    }
}

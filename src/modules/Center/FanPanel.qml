import QtQuick
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0
    required property var service

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        spacing: Math.round(10 * localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Fan Control"
            font.pixelSize: Math.round(14 * localScale)
            color:          Qt.rgba(1, 1, 1, 0.35)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: parent.parent.width * 0.1

            ProfileButton {
                localScale: root.localScale
                icon:      "󱗰"
                label:     "Quiet"
                active:    service.mode === "quiet"
                onClicked: service.setMode("quiet")
            }
            ProfileButton {
                localScale: root.localScale
                icon:      "󰁪"
                label:     "Auto"
                active:    service.mode === "auto"
                onClicked: service.setMode("auto")
            }
            ProfileButton {
                localScale: root.localScale
                icon:      "󱓞"
                label:     "Max"
                active:    service.mode === "max"
                onClicked: service.setMode("max")
            }
        }
    }
}

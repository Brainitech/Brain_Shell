import QtQuick
import "../../"
import "../../components"

Item{
    id: root
    
    required property var  service
    property string fanMode: "quiet"
    
     // ── Fan control block — anchored right ────────────────────────────────────
    Column {
        anchors.horizontalCenter:          parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Fan Control"
            font.pixelSize: 14
            color:          Qt.rgba(1, 1, 1, 0.35)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: parent.parent.width * 0.1

            ProfileButton {
                icon:      "󱗰"
                label:     "Quiet"
                active:    root.fanMode === "quiet"
                onClicked: root.fanMode = "quiet"
            }
            ProfileButton {
                icon:      "󰁪"
                label:     "Auto"
                active:    root.fanMode === "auto"
                onClicked: root.fanMode = "auto"
            }
            ProfileButton {
                icon:      "󱓞"
                label:     "Max"
                active:    root.fanMode === "max"
                onClicked: root.fanMode = "max"
            }
        }
    }
}
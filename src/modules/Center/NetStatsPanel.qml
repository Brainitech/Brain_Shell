import QtQuick
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0
    required property var service

    Column {
        anchors.centerIn: parent
        width:            parent.width - Math.round(16 * localScale)
        spacing:          Math.round(10 * localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Network"
            font.pixelSize: Math.round(11 * localScale)
            font.weight:    Font.Medium
            color:          Qt.rgba(1, 1, 1, 0.4)
        }

        Column {
            width:   parent.width
            spacing: Math.round(6 * localScale)

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "Interface"
                value:      root.service.iface
            }

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "↑ Upload"
                value:      root.service.upSpeed
                valueColor: "#90ef90"
            }

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "↓ Download"
                value:      root.service.downSpeed
                valueColor: "#a6d0f7"
            }
        }
    }
}

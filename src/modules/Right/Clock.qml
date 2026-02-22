import QtQuick
import "../../"

Text {
        text: Qt.formatDateTime(new Date(), "hh:mm")
        color: Theme.text
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.text =
                Qt.formatDateTime(new Date(), "hh:mm")
        }
    }

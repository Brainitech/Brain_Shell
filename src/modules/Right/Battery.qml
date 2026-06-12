import QtQuick
import "../../services"
import "../../"

Item {
    // Set to true to always show percentage beside the icon.
    // When false (default), percentage only shows on hover.
    property bool showPercentage: false

    implicitWidth:  visible ? status.implicitWidth : 0
    implicitHeight: visible ? status.implicitHeight : 0

    visible: status.visible

    BatteryStatus {
        id:               status
        anchors.centerIn: parent
        showPercentage:   parent.showPercentage
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var next = !Popups.batteryOpen
            Popups.closeAll()
            Popups.batteryOpen = next
        }
    }
}

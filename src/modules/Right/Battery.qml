import QtQuick
import "../../services"
import "../../"

Item {
    property real localScale: 1.0
    // Set to true to always show percentage beside the icon.
    // When false (default), percentage only shows on hover.
    property bool showPercentage: false

    implicitWidth:  status.implicitWidth
    implicitHeight: status.implicitHeight
    
    visible: ShellState.hasBattery

    BatteryStatus {
        id:               status
        localScale:       parent.localScale
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

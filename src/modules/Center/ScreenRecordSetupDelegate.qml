import QtQuick
import Quickshell
import "../../"
import "../../theme"
import "../../services"
import "../../state"

Item {
    id: delegateRoot
    required property string itemType
    required property real localScale
    required property int fw

    anchors {
        fill: parent
        leftMargin: fw / 2
        rightMargin: fw / 2
    }
    visible: itemType === "record_setup"
    
    Item {
        id: compactStrip
        anchors.fill: parent

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Math.round(10 * localScale)
            width: Math.round(8 * localScale); height: Math.round(8 * localScale); radius: width / 2
            color: "#ff4444"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Record Button (Center)
        Rectangle {
            anchors.centerIn: parent
            width: Math.round(76 * localScale); height: Math.round(22 * localScale); radius: height / 2
            color: recBtnH.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.85) : Qt.rgba(0.8, 0.1, 0.1, 0.7)
            Behavior on color { ColorAnimation { duration: Anim.fast} }
            Text { text: "Record"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: "#ffffff"; anchors.centerIn: parent }
            HoverHandler { id: recBtnH }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.startRecording() }
        }

        // Cancel Button (Extreme Right)
        Item {
            anchors.right: parent.right
            anchors.rightMargin: Math.round(10 * localScale)
            width: Math.round(24 * localScale); height: Math.round(24 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent; radius: width / 2
                color: cancelH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast } }
            }
            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: Math.round(10 * localScale); color: Theme.subtext }
            HoverHandler { id: cancelH }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.cancelSetup() }
        }
    }
}

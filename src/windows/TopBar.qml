import Quickshell
import QtQuick
import "../components"
import "../modules/Center/"
import "../modules/Right/"
import "../modules/Left/"
import "../"
import "../shapes/"
import "../popups/"

PanelWindow {
    id: root

    property string screenName: screen ? screen.name : ""

    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.notchHeight
    exclusiveZone: Theme.exclusionGap

    // Background shape
    SeamlessBarShape {
        anchors.fill: parent
    }

    // Left Content
    Item {
        implicitHeight: Theme.notchHeight
        implicitWidth:  Theme.lNotchWidth
        anchors.left: parent.left

        LeftContent {
            anchors.centerIn: parent
        }
    }

    // Center Content
    Item {
        implicitHeight: Theme.notchHeight
        implicitWidth:  Theme.cNotchWidth
        anchors.centerIn: parent

        CenterContent {
            anchors.centerIn: parent
        }
    }

    // Right Content
    Item {
        implicitHeight: Theme.notchHeight
        implicitWidth:  Theme.rNotchWidth
        anchors.right: parent.right

        RightContent {
            anchors.centerIn: parent
        }
    }

    // --- Popups ---
    // Declared here so they have access to this PanelWindow as anchorWindow.

    AudioPopup {
        anchorWindow: root
    }
}

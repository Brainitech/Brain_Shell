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
        top:   true
        left:  true
        right: true
    }

    implicitHeight: Theme.notchHeight
    exclusiveZone:  Theme.exclusionGap

    // ── Computed notch widths ────────────────────────────────────────────────
    // Each notch measures its content's implicitWidth, adds padding, then
    // clamps the result between the Theme min/max values.
    // The shape and the item containers all read these same values so
    // everything stays perfectly in sync.

    readonly property int lWidth: Math.max(
        Theme.lNotchMinWidth,
        Math.min(Theme.lNotchMaxWidth,
                 leftContent.implicitWidth + Theme.notchPadding * 2)
    )

    readonly property int cWidth: Math.max(
        Theme.cNotchMinWidth,
        Math.min(Theme.cNotchMaxWidth,
                 centerContent.implicitWidth + Theme.notchPadding * 2)
    )

    readonly property int rWidth: Math.max(
        Theme.rNotchMinWidth,
        Math.min(Theme.rNotchMaxWidth,
                 rightContent.implicitWidth + Theme.notchPadding * 2)
    )

    // ── Background shape ─────────────────────────────────────────────────────
    SeamlessBarShape {
        anchors.fill: parent
        leftWidth:    root.lWidth
        centerWidth:  root.cWidth
        rightWidth:   root.rWidth
    }

    // ── Left notch ───────────────────────────────────────────────────────────
    Item {
        id: leftNotch
        implicitHeight: Theme.notchHeight
        implicitWidth:  root.lWidth
        anchors.left:   parent.left

        LeftContent {
            id: leftContent
            anchors.centerIn: parent
        }
    }

    // ── Center notch ─────────────────────────────────────────────────────────
    Item {
        id: centerNotch
        implicitHeight: Theme.notchHeight
        implicitWidth:  root.cWidth
        anchors.centerIn: parent

        CenterContent {
            id: centerContent
            anchors.centerIn: parent
        }
    }

    // ── Right notch ──────────────────────────────────────────────────────────
    Item {
        id: rightNotch
        implicitHeight: Theme.notchHeight
        implicitWidth:  root.rWidth
        anchors.right:  parent.right

        RightContent {
            id: rightContent
            anchors.centerIn: parent
        }
    }

    // ── Popups ───────────────────────────────────────────────────────────────
    // Declared here so they have access to this PanelWindow as anchorWindow.
    AudioPopup {
        anchorWindow: root
        notchWidth:   root.rWidth
    }
}

import Quickshell
import QtQuick
import "../components"
import "../modules/Center/"
import "../modules/Right/"
import "../modules/Left/"
import "../"
import "../shapes/"

// TopBar owns the notch layout and exposes clamped notch widths.
// It does NOT instantiate any popups — that is PopupLayer's job.

PanelWindow {
    id: root

    property string screenName: screen ? screen.name : ""

    color: "transparent"

    anchors {
        top:   true
        left:  true
        right: true
    }

    // FIXED — never changes. Dashboard expansion is handled by a
    // separate PopupWindow (Dashboard.qml) that drops down below the notch.
    // Animating implicitHeight on a PanelWindow causes a compositor
    // window resize which is inherently jerky.
    implicitHeight: Theme.notchHeight

    exclusiveZone: Theme.exclusionGap

    // ── Clamped notch widths (read by PopupLayer / SeamlessBarShape) ─────────

    readonly property int lWidth: Math.max(
        Theme.lNotchMinWidth,
        Math.min(Theme.lNotchMaxWidth,
                 leftContent.implicitWidth + Theme.notchPadding * 2)
    )

    // cWidth animates to dashboardWidth when the dashboard is open.
    // Safe to animate — PanelWindow spans full screen width so no
    // compositor resize occurs, only a QML canvas repaint.
    property int cWidth: Popups.dashboardOpen
        ? Theme.dashboardWidth
        : Math.max(
            Theme.cNotchMinWidth,
            Math.min(Theme.cNotchMaxWidth,
                     centerContent.implicitWidth + Theme.notchPadding * 2)
          )
    Behavior on cWidth {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    }

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
        implicitHeight: Theme.notchHeight
        implicitWidth:  root.rWidth
        anchors.right:  parent.right

        RightContent {
            id: rightContent
            anchors.centerIn: parent
        }
    }
}

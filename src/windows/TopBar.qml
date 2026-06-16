import Quickshell
import QtQuick
import "../components"
import "../modules/Center/"
import "../modules/Right/"
import "../modules/Left/"
import "../"
import "../shapes/"

PanelWindow {
    id: root

    property string screenName: screen ? screen.name : ""

    // ── Context-Aware Scaling ─────────────────────────────────────────────────
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    color: "transparent"

    anchors {
        top:   true
        left:  true
        right: true
    }

    Binding { target: ShellState; property: "topBarLWidth"; value: root.lWidth }
    Binding { target: ShellState; property: "topBarCWidth"; value: root.cWidth }
    Binding { target: ShellState; property: "topBarRWidth"; value: root.rWidth }

    // ── Height shrinks to a border strip in focus mode ───────────────────────
    // Safe to animate on PanelWindow (anchored, no position jank).
    // PopupWindow is the one that must never have animated implicitHeight.
    implicitHeight: (ShellState.focusMode ? Math.round(Theme.borderWidth * root.localScale) : Math.round(Theme.notchHeight * root.localScale)) + 1
    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    }

    exclusiveZone: ShellState.focusMode ? 0 : Math.round(Theme.exclusionGap * root.localScale)
    Behavior on exclusiveZone {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    }

    readonly property int lWidth: Math.max(
        Math.round(Theme.lNotchMinWidth * root.localScale),
        Math.min(Math.round(Theme.lNotchMaxWidth * root.localScale),
                 leftContent.implicitWidth + Math.round(Theme.notchPadding * 2 * root.localScale))
    )

    // cWidth uses Popups.dashboardPageWidth when the dashboard is open,
    // so the center notch tracks the active tab's declared width.
    property int cWidth: Popups.dashboardOpen
        ? Math.min(Popups.dashboardPageWidth * root.localScale, (screen ? screen.width : 1920) * 0.95)
        : Math.max(
            Math.round(Theme.cNotchMinWidth * root.localScale),
            Math.min(Math.round(Theme.cNotchMaxWidth * root.localScale),
                     centerContent.implicitWidth + Math.round(Theme.notchPadding * 2 * root.localScale))
          )
    Behavior on cWidth {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    }

    // Width matches sizer open width: popupWidth + notchRadius (fw) in both popups
    property int rWidth: Math.max(
        Math.round(Theme.rNotchMinWidth * root.localScale),
        Math.min(Math.round(Theme.rNotchMaxWidth * root.localScale), rightContent.implicitWidth + Math.round(Theme.notchPadding * 2 * root.localScale))
    )

    // ── Border strip (focus mode) ────────────────────────────────────────────
    // Painted behind the notch content layer. Visible only when focus mode
    // fades the notches out. Uses the same bar color so it reads as a thin
    // edge strip matching the side border strips.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: ShellState.focusMode ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
        }
    }

    // ── Notch content (fades out in focus mode) ──────────────────────────────
    Item {
        anchors.fill: parent
        opacity: ShellState.focusMode ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
        }

        states: [
        State {
            name: "notifications"
            when: Popups.notificationsOpen
            PropertyChanges { target: root; rWidth: Math.round(((Theme.notificationsWidth * root.localScale) + (Theme.notchRadius * root.localScale)*1.5 -2)) }
        },
        State {
            name: "network"
            when: Popups.networkOpen && !Popups.notificationsOpen
            PropertyChanges { target: root; rWidth: Math.round((Theme.networkPopupWidth * root.localScale) + (Theme.notchRadius * root.localScale)) }
        },
        State {
            name: "toast"
            when: Popups.notificationToastOpen && !Popups.notificationsOpen && !Popups.networkOpen
            PropertyChanges { target: root; rWidth: Math.round((Theme.notificationToastWidth * root.localScale) + (Theme.notchRadius * root.localScale) + (Theme.notchPadding * root.localScale)) }
        }
    ]

    transitions: [
        Transition {
            // This animation ONLY runs when switching between popups (and toasts) and the base state.
            NumberAnimation { property: "rWidth"; duration: Theme.animDuration; easing.type: Easing.InOutCubic }
        }
    ]

        SeamlessBarShape {
            id: barShape
            anchors.fill: parent
            leftWidth:   root.lWidth
            centerWidth: root.cWidth
            rightWidth:  root.rWidth
            notchHeight:    Math.round(Theme.notchHeight * root.localScale)
            radius:         Math.round(Theme.notchRadius * root.localScale)
            topBorderWidth: Math.round(Theme.borderWidth * root.localScale)
        }

        Item {
            id:           leftNotch
            width:        root.lWidth
            height:       Math.round((Theme.notchHeight - Theme.borderWidth) * root.localScale)
            anchors.left: parent.left
            anchors.top:  parent.top
            anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)

            LeftContent {
                id: leftContent
                localScale: root.localScale
                anchors.centerIn: parent
            }
        }

        Item {
            id:               centerNotch
            width:            root.cWidth
            height:           Math.round((Theme.notchHeight - Theme.borderWidth) * root.localScale)
            anchors.centerIn: parent
            anchors.top:      parent.top
            anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)

            CenterContent {
                id: centerContent
                localScale: root.localScale
                anchors.centerIn: parent
            }
        }

        Item {
            id:            rightNotch
            width:         root.rWidth
            height:        Math.round((Theme.notchHeight - Theme.borderWidth) * root.localScale)
            anchors.right: parent.right
            anchors.top:   parent.top
            anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)

            clip: true

            RightContent {
                id: rightContent
                localScale: root.localScale
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Math.round(Theme.notchPadding * root.localScale)
            }
        }
    }
}

import QtQuick
import "../"

Item {
    id: root

    property string edge: "left"
    property bool   open: false
    property bool   hoverEnabled: false
    property bool   triggerHovered: false
    property bool   pinned: false

    property int slideDuration: Popups.slideDuration
    property int closeDelay:    Popups.hoverCloseDelay
    property int openDelay:     Popups.hoverOpenDelay

    property bool windowVisible: false
    readonly property bool sliding: shellXAnim.running || shellYAnim.running

    readonly property real innerX: shell.x
    readonly property real innerY: shell.y
    readonly property real innerWidth: shell.width
    readonly property real innerHeight: shell.height

    signal closeRequested()
    signal pinRequested()

    default property alias content: contentHost.data

    property bool _selfHovered: false
    property bool _hoverOpenActive: false
    readonly property bool _effectiveOpen: open || _hoverOpenActive
    readonly property bool _isHoverOpen: hoverEnabled && (triggerHovered || _selfHovered)

    on_IsHoverOpenChanged: {
        if (_isHoverOpen) {
            hoverCloseTimer.stop()
            _hoverOpenActive = true
        } else {
            if (_hoverOpenActive) hoverCloseTimer.restart()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: root.openDelay
        onTriggered: {
            if (root._isHoverOpen) root._hoverOpenActive = true
        }
    }

    clip: true

    on_EffectiveOpenChanged: {
        if (_effectiveOpen) {
            hoverCloseTimer.stop()
            slideCloseTimer.stop()
            windowVisible = true
        } else {
            slideCloseTimer.restart()
        }
    }

    Timer {
        id: slideCloseTimer
        interval: (Anim.style === "none" ? 0 : root.slideDuration) + 20
        onTriggered: root.windowVisible = false
    }

    Timer {
        id: hoverCloseTimer
        interval: root.closeDelay
        onTriggered: {
            if (!root.triggerHovered && !root._selfHovered) {
                root._hoverOpenActive = false
                if (!root.pinned) root.closeRequested()
            }
        }
    }

    // Shell: the popup shape wrapper. Uses the global curve but clamps to prevent edge detachment.
    Item {
        id: shell
        width:  parent.width
        height: parent.height

        property real targetX: root._effectiveOpen ? 0 : (root.edge === "left" ? -width : (root.edge === "right" ? width : 0))
        property real targetY: root._effectiveOpen ? 0 : (root.edge === "top" ? -height : (root.edge === "bottom" ? height : 0))

        property real animX: targetX
        property real animY: targetY

        Behavior on animX {
            enabled: Anim.style !== "none"
            NumberAnimation { id: shellXAnim; duration: root.slideDuration; easing.type: Anim.globalCurve }
        }
        Behavior on animY {
            enabled: Anim.style !== "none"
            NumberAnimation { id: shellYAnim; duration: root.slideDuration; easing.type: Anim.globalCurve }
        }

        x: root.edge === "left" ? Math.min(0, animX) 
         : root.edge === "right" ? Math.max(0, animX) 
         : animX
         
        y: root.edge === "top" ? Math.min(0, animY)
         : root.edge === "bottom" ? Math.max(0, animY)
         : animY

        HoverHandler { onHoveredChanged: root._selfHovered = hovered }
        TapHandler   { onTapped: root.pinRequested() }

        Item {
            id: contentHost
            anchors.fill: parent
        }
    }
}

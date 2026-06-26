import QtQuick
import "../"

// Slide-in/out animation container for all popups.
//
// Universal behavior lives here — animation, hover-to-open,
// self-hover tracking, and close delay. Each popup just wires
// its own Popups.* bool into `open` and optionally into
// `triggerHovered`, then listens for `closeRequested`.
//
// Usage (click-only popup — e.g. ArchMenu):
//   PopupSlide {
//       id: slide
//       edge: "left"
//       open: Popups.archMenuOpen
//       // content
//   }
//
// Usage (hover popup — e.g. AudioPopup):
//   PopupSlide {
//       id: slide
//       edge: "right"
//       open: Popups.audioOpen
//       hoverEnabled:    true
//       triggerHovered:  Popups.audioTriggerHovered
//       onCloseRequested: Popups.audioOpen = false
//       // content
//   }
//
// Always bind PopupWindow.visible to slide.windowVisible.

Item {
    id: root

    // ── Required ──────────────────────────────────────────────────────────────
    property string edge: "left"    // "left" | "right" | "top" | "bottom"
    property bool   open: false     // the Popups.*Open bool for this popup

    // ── Hover-to-open (optional) ──────────────────────────────────────────────
    property bool hoverEnabled:   false
    property bool triggerHovered: false   // bind to Popups.*TriggerHovered
    property bool pinned:         false   // bind to Popups.*Pinned

    // ── Universal timing — sourced from Popups singleton ──────────────────────
    property int slideDuration: Popups.slideDuration
    property int closeDelay:    Popups.hoverCloseDelay
    property int openDelay:     Popups.hoverOpenDelay

    // ── Output ────────────────────────────────────────────────────────────────
    // Bind PopupWindow.visible to this
    property bool windowVisible: false
    readonly property bool sliding: xAnim.running || yAnim.running

    // Emitted after closeDelay when hover leaves — popup sets its Popups.* bool
    signal closeRequested()

    // Emitted when clicked inside the popup to pin it open
    signal pinRequested()

    // ── Internal ──────────────────────────────────────────────────────────────
    property bool _selfHovered: false

    // The popup should be visually open when:
    readonly property bool _isHoverOpen: hoverEnabled && (triggerHovered || _selfHovered)
    readonly property bool _effectiveOpen: open || _hoverOpenActive

    property bool _hoverOpenActive: false

    on_IsHoverOpenChanged: {
        if (_isHoverOpen) {
            if (hoverCloseTimer.running) {
                // Recovering from a deadzone cross -> immediate open
                hoverCloseTimer.stop()
                _hoverOpenActive = true
            } else if (!open && !_hoverOpenActive) {
                // Initial hover -> delayed open
                hoverOpenTimer.restart()
            }
        } else {
            hoverOpenTimer.stop()
            if (_hoverOpenActive) {
                hoverCloseTimer.restart()
            }
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: root.openDelay
        onTriggered: {
            if (root._isHoverOpen) {
                root._hoverOpenActive = true
            }
        }
    }

    default property alias content: inner.data

    clip: true

    // ── State machine ─────────────────────────────────────────────────────────
    on_EffectiveOpenChanged: {
        if (_effectiveOpen) {
            hoverCloseTimer.stop()
            slideCloseTimer.stop()
            windowVisible = true
        } else {
            slideCloseTimer.restart()
        }
    }

    // Wait for slide-out to finish before hiding window
    Timer {
        id: slideCloseTimer
        interval: root.slideDuration + 20
        onTriggered: root.windowVisible = false
    }

    // Hover leave — wait closeDelay then emit closeRequested
    Timer {
        id: hoverCloseTimer
        interval: root.closeDelay
        onTriggered: {
            // Double-check hover is still gone before requesting close
            if (!root.triggerHovered && !root._selfHovered) {
                root._hoverOpenActive = false
                if (!root.pinned) {
                    root.closeRequested()
                }
            }
        }
    }

    // ── Sliding item ──────────────────────────────────────────────────────────
    Item {
        id: inner
        width:  parent.width
        height: parent.height

        x: root._effectiveOpen ? 0 : (root.edge === "left"  ? -width  :
                                       root.edge === "right" ?  width  : 0)

        y: root._effectiveOpen ? 0 : (root.edge === "top"    ? -height :
                                       root.edge === "bottom" ?  height : 0)

        Behavior on x { NumberAnimation { id: xAnim; duration: root.slideDuration; easing.type: Anim.outCubic} }
        Behavior on y { NumberAnimation { id: yAnim; duration: root.slideDuration; easing.type: Anim.outCubic} }

        // Self-hover tracking — automatically available to all popups
        HoverHandler {
            onHoveredChanged: root._selfHovered = hovered
        }

        // Interaction pinning — passively detect clicks inside to pin
        TapHandler {
            onTapped: root.pinRequested()
        }
    }
}

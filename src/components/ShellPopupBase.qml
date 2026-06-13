import QtQuick
import "../theme"

/*!
    ShellPopupBase — reusable Ambxst-style popup animation base.

    Philosophy (from Ambxst):
      - Scale 0.9→1.0 + opacity 0→1 on open (OutCubic, feels fluid)
      - Scale 1.0→0.92 + opacity 1→0 on close (faster — OutQuad)
      - transformOrigin anchored to logical edge (Top/Bottom/Left/Right)
      - Single animDuration from Theme, with Behavior.enabled guard
      - scale+opacity > plain opacity — looks more physical

    Usage:
      ShellPopupBase {
          transformEdge: "top"  // where the popup "grows from"
          isOpen: someState
          // content children go here
          Rectangle { anchors.fill: parent; color: "red" }
      }
*/
Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property bool isOpen: false
    property string transformEdge: "top"  // top | bottom | left | right | center
    property bool disableAutoHide: false   // set true when parent manages visibility

    property alias popupOpacity: root._popupOpacity
    property alias popupScale: root._popupScale

    // ── Animations — smooth, no bounce (OutBack was too sharp/bouncy) ────────
    // Open: smooth deceleration. Close: faster, no overshoot.
    property real _popupOpacity: isOpen ? 1 : 0
    property real _popupScale: isOpen ? 1 : 0.92

    readonly property int _dur: Theme.animDuration

    transformOrigin: {
        switch (transformEdge) {
            case "top":    return Item.Top
            case "bottom": return Item.Bottom
            case "left":   return Item.Left
            case "right":  return Item.Right
            default:       return Item.Center
        }
    }

    opacity: _popupOpacity
    scale: _popupScale
    visible: opacity > 0

    Behavior on _popupOpacity {
        enabled: _dur > 0
        NumberAnimation {
            duration: root.isOpen ? _dur : Math.round(_dur * 0.5)
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InQuad
        }
    }

    Behavior on _popupScale {
        enabled: _dur > 0
        NumberAnimation {
            duration: root.isOpen ? Math.round(_dur * 1.1) : Math.round(_dur * 0.4)
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InQuad
        }
    }

    Timer {
        id: _hideTimer
        interval: Math.round(_dur * 0.5) + 20
        onTriggered: root.visible = false
    }

    onIsOpenChanged: {
        if (isOpen) {
            _hideTimer.stop()
            root.visible = true
            // Force reset then animate in (Ambxst Qt.callLater pattern)
            Qt.callLater(function() {
                root._popupOpacity = 1
                root._popupScale = 1
            })
        } else {
            root._popupOpacity = 0
            root._popupScale = 0.88
            if (!disableAutoHide) _hideTimer.restart()
        }
    }
}

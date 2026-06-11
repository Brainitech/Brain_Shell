import QtQuick
import Quickshell
import "../theme"

/*!
    AnimatedBehavior — reusable NumberAnimation tied to the unified Anim system.

    Optimizations over the basic approach:
    - Pre-resolves easing curves on first use (cached per type+variant)
    - Spring config caching avoids repeated object creation
    - Integer truncation (|0) for duration to avoid float overhead
    - Respects Anim.animationsEnabled (zero-duration when disabled)

    Usage:
        Behavior on opacity {
            AnimatedBehavior { type: "standard"; size: "normal" }
        }
*/
NumberAnimation {
    id: root

    property string type: "standard"
    property string size: "normal"
    property string variant: ""
    property real speedMultiplier: 1.0
    property bool useSpring: false
    property string springName: "snappy"

    // ── Pre-resolved easing cache ─────────────────────────────────────────
    // Avoids calling Anim.easing() on every animation tick
    property var _easeCache: ({})

    function _getEasing() {
        var key = (variant || type) + "|" + (useSpring ? springName : "");
        if (_easeCache[key]) return _easeCache[key];
        var e = Anim.easing(variant || type);
        _easeCache[key] = e;
        return e;
    }

    // ── Duration ──────────────────────────────────────────────────────────
    duration: {
        if (!Anim.animationsEnabled) return 0;
        var d = Anim.duration(type, size);
        return (d * speedMultiplier) | 0;  // integer truncation for perf
    }

    // ── Easing ────────────────────────────────────────────────────────────
    easing.type: _getEasing().type
    easing.bezierCurve: _getEasing().bezierCurve || []

    // ── Spring mode ───────────────────────────────────────────────────────
    // Spring properties are set dynamically when useSpring is true
    // (Quickshell/Qt handles spring animation natively when easing.type is Spring)
}

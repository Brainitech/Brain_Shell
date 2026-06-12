pragma Singleton
import QtQuick
import "../services"

/*!
    Anim.qml — Unified animation system for Brain_Shell.

    Provides consistent durations, easing curves, and behavior helpers
    to replace hardcoded animation values scattered across the shell.

    Usage:
        Behavior on opacity {
            AnimatedBehavior { type: "standard"; size: "normal" }
        }

        NumberAnimation {
            duration: Anim.duration("emphasized", "normal")
            easing.type: Anim.easing("emphasized").type
            easing.bezierCurve: Anim.easing("emphasized").bezierCurve
        }

        // Or use convenience properties:
        duration: Anim.standardNormal
*/
QtObject {
    id: root

    // Global animation kill-switch (reduced motion / game mode)
    property bool animationsEnabled: true

    // Global speed multiplier from config
    readonly property real _speed: ShellConfigService.animationSpeed

    // ============================================
    // DURATION PRESETS (ms)
    // Base aligned with Ambxst: animDuration = 300ms
    // ============================================

    // Standard motion (UI feedback, small transitions)
    readonly property int standardSmall:      150
    readonly property int standardNormal:     300
    readonly property int standardLarge:      400
    readonly property int standardExtraLarge: 500

    // Emphasized motion (larger UI changes, entrances/exits)
    readonly property int emphasizedSmall:    250
    readonly property int emphasizedNormal:   400
    readonly property int emphasizedLarge:    550

    // Spatial motion (movement across space)
    readonly property int spatialFast:        200
    readonly property int spatialDefault:     350
    readonly property int spatialSlow:        500

    // Spring motion (elastic/bouncy)
    readonly property int springSmall:        350
    readonly property int springNormal:       500
    readonly property int springLarge:        650

    // ============================================
    // EASING PRESETS (Ambxst-inspired)
    // ============================================

    readonly property var _easings: ({
        "standard":       { type: Easing.Bezier, bezierCurve: [0.25, 0.0, 0.0, 1.0] },  // OutQuart — main Ambxst curve
        "outQuart":       { type: Easing.Bezier, bezierCurve: [0.25, 0.0, 0.0, 1.0] },  // OutQuart alias
        "outCubic":       { type: Easing.Bezier, bezierCurve: [0.0,  0.0, 0.2, 1.0] },  // OutCubic — Ambxst secondary
        "outSine":        { type: Easing.Bezier, bezierCurve: [0.4,  0.0, 0.6, 1.0] },  // OutSine — Ambxst gentle
        "emphasized":     { type: Easing.Bezier, bezierCurve: [0.05, 0.7, 0.1, 1.0] },
        "emphasizedExit": { type: Easing.Bezier, bezierCurve: [0.3, 0.0, 0.8, 0.15] },
        "collapse":       { type: Easing.Bezier, bezierCurve: [0.25, 1.0, 0.5, 1.0] },
        "spatial":        { type: Easing.Bezier, bezierCurve: [0.4, 0.0, 0.2, 1.0] },
        "decelerate":     { type: Easing.Bezier, bezierCurve: [0.0, 0.0, 0.2, 1.0] },
        "accelerate":     { type: Easing.Bezier, bezierCurve: [0.4, 0.0, 1.0, 1.0] },
        "linear":         { type: Easing.Linear, bezierCurve: [] }
    })

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    function duration(type, size) {
        if (!root.animationsEnabled) return 0;
        var d;
        switch (type + "-" + size) {
            case "standard-small":      d = standardSmall; break;
            case "standard-normal":     d = standardNormal; break;
            case "standard-large":      d = standardLarge; break;
            case "standard-extraLarge": d = standardExtraLarge; break;
            case "emphasized-small":    d = emphasizedSmall; break;
            case "emphasized-normal":   d = emphasizedNormal; break;
            case "emphasized-large":    d = emphasizedLarge; break;
            case "spatial-fast":        d = spatialFast; break;
            case "spatial-default":     d = spatialDefault; break;
            case "spatial-slow":        d = spatialSlow; break;
            case "spring-small":        d = springSmall; break;
            case "spring-normal":       d = springNormal; break;
            case "spring-large":        d = springLarge; break;
            default:                    d = standardNormal; break;
        }
        return Math.round(d / root._speed);
    }

    function easing(name) {
        var e = _easings[name] || _easings["standard"];
        return {
            type: e.type,
            bezierCurve: e.bezierCurve || []
        };
    }

    // Apply to an existing NumberAnimation instance
    function configure(anim, type, size, variant) {
        if (!root.animationsEnabled) {
            anim.duration = 0;
            return;
        }
        anim.duration = root.duration(type, size);
        var easeName = variant || type;
        var e = root.easing(easeName);
        anim.easing.type = e.type;
        if (e.bezierCurve.length > 0) {
            anim.easing.bezierCurve = e.bezierCurve;
        }
    }

    // List transition helpers (return { duration, easing: { type, bezierCurve } })
    function listAddTransition() {
        return {
            duration: root.animationsEnabled ? root.standardNormal : 0,
            easing: {
                type: root.easing("standard").type,
                bezierCurve: root.easing("standard").bezierCurve
            }
        };
    }

    function listRemoveTransition() {
        return {
            duration: root.animationsEnabled ? root.standardSmall : 0,
            easing: {
                type: root.easing("accelerate").type,
                bezierCurve: root.easing("accelerate").bezierCurve
            }
        };
    }

    function listDisplacedTransition() {
        return {
            duration: root.animationsEnabled ? root.standardNormal : 0,
            easing: {
                type: root.easing("spatial").type,
                bezierCurve: root.easing("spatial").bezierCurve
            }
        };
    }
}

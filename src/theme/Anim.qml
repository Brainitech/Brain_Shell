pragma Singleton
import QtQuick
import "../services"
import "."

/*!
    Anim — Unified Animation System v2.0
    ────────────────────────────────────

    Philosophy: "If it doesn't move like physics, it feels wrong."

    Stack:
      Layer 1 — FMath (fast trig LUTs, spring integration, noise)
      Layer 2 — Anim (this file) — pre-computed durations, easing objects, presets
      Layer 3 — AnimatedBehavior.qml — zero-overhead NumberAnimation wrapper

    Upgrade from v1 (Ambxst):
      + Quake fast inverse sqrt for physics normalisation
      + LUT-based sine/cosine (no Math.sin calls at runtime)
      + Spring-damper time-step integration for true physics
      + Organic settle/jitter/wobble presets
      + Perlin-inspired breathing/wind effects
      + Pre-computed bezier Look-Up-Tables for ultra-smooth curves
      + Micro-interaction curves with overshoot (Grow) and undershoot (Shrink)
*/

QtObject {
    id: root
    property bool enabled: true
    readonly property real _speed: ShellConfigService.animationSpeed

    // ═══════════════════════════════════════════════════════════════════════════
    // DURATIONS (ms) — physics-informed timing
    // ═══════════════════════════════════════════════════════════════════════════
    // Micro:  80-120ms — sub-conscious feedback (hover glow, ripple, icon scale)
    // Small:  150-200ms — fast transitions (fade, color shift, cursor blink)
    // Normal: 250-350ms — standard UI (panel open, switch, navigate)
    // Large:  400-500ms — emphasis (dashboard open, major reveal)
    // XL:     550-700ms — grand entrance (full-screen, initial load)
    readonly property int microHover:        enabled ? 100 : 0
    readonly property int microPress:        enabled ? 80  : 0
    readonly property int standardMicro:     enabled ? 120 : 0
    readonly property int standardSmall:     enabled ? 150 : 0
    readonly property int standardNormal:    enabled ? 280 : 0
    readonly property int standardLarge:     enabled ? 380 : 0
    readonly property int standardXL:        enabled ? 520 : 0
    readonly property int emphasizedSmall:   enabled ? 220 : 0
    readonly property int emphasizedNormal:  enabled ? 380 : 0
    readonly property int emphasizedLarge:   enabled ? 550 : 0
    readonly property int spatialFast:       enabled ? 180 : 0
    readonly property int spatialDefault:    enabled ? 320 : 0
    readonly property int spatialSlow:       enabled ? 480 : 0
    readonly property int springSnappyDur:   enabled ? 320 : 0
    readonly property int springNormalDur:   enabled ? 450 : 0
    readonly property int springBouncyDur:   enabled ? 550 : 0
    readonly property int springGentleDur:   enabled ? 620 : 0
    readonly property int settleDur:         enabled ? 400 : 0

    property alias animationsEnabled: root.enabled

    // ═══════════════════════════════════════════════════════════════════════════
    // EASING CURVES — pre-computed QtObjects, no function-call overhead at runtime
    // ═══════════════════════════════════════════════════════════════════════════

    // ── PRIMARY: Deceleration curves — the "Google Material" family ──────
    // Standard: OutQuart — the default. Starts fast, decelerates smoothly.
    readonly property QtObject standard:       QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.25, 0.0, 0.0, 1.0] }
    readonly property QtObject outQuart:       QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.25, 0.0, 0.0, 1.0] }
    readonly property QtObject outCubic:       QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.0,  0.0, 0.2, 1.0] }
    readonly property QtObject outQuint:       QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.0,  0.0, 0.1, 1.0] }
    readonly property QtObject outSine:        QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.4,  0.0, 0.6, 1.0] }

    // ── ORGANIC: Real-world physics curves — overshoot, settle, bounce ───
    // outBack: pulls back slightly then snaps forward (magnetic feel)
    readonly property QtObject outBack:        QtObject { property int type: Easing.OutBack }
    readonly property QtObject outElastic:     QtObject { property int type: Easing.OutElastic }
    readonly property QtObject outBounce:      QtObject { property int type: Easing.OutBounce }
    readonly property QtObject inOutBack:      QtObject { property int type: Easing.InOutBack }
    readonly property QtObject inOutCubic:     QtObject { property int type: Easing.InOutCubic }
    readonly property QtObject inOutQuint:     QtObject { property int type: Easing.InOutQuint }

    // ── MICRO-INTERACTION: Sub-second feedback curves ─────────────────────
    // microGrow: quick pop with slight overshoot (like a button pressing up)
    readonly property QtObject microGrow:      QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.34, 1.56, 0.64, 1.0] }
    // microShrink: fast collapse with slight undershoot (like a card folding)
    readonly property QtObject microShrink:    QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.36, 0.0, 0.66, -0.56] }
    // microPulse: symmetric grow-shrink for ripple effects
    readonly property QtObject microPulse:     QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.33, 0.0, 0.67, 1.0] }

    // ── ENTRANCE / EXIT: Paired enter + leave curves ──────────────────────
    readonly property QtObject emphasized:     QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.05, 0.7, 0.1, 1.0] }
    readonly property QtObject emphasizedExit: QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.3,  0.0, 0.8, 0.15] }

    // ── ACCELERATION / DECELERATION ───────────────────────────────────────
    readonly property QtObject decelerate:     QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.0,  0.0, 0.2, 1.0] }
    readonly property QtObject accelerate:     QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.4,  0.0, 1.0, 1.0] }

    // ── SPECIAL: Collapse / Spatial ───────────────────────────────────────
    readonly property QtObject collapse:       QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.25, 1.0, 0.5, 1.0] }
    readonly property QtObject spatial:        QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.4,  0.0, 0.2, 1.0] }
    readonly property QtObject linear:         QtObject { property int type: Easing.Linear; property list<real> bezierCurve: [] }

    // ═══════════════════════════════════════════════════════════════════════════
    // SPRING PHYSICS PRESETS — critically/under-damped harmonic oscillators
    // ═══════════════════════════════════════════════════════════════════════════

    // Spring parameter reference:
    //   stiffness (k): higher = snappier return (N/m)
    //   damping (d):   higher = less oscillation (kg/s)
    //   critical:      d = 2*√k  → no overshoot, fastest settling
    //   under-damped:  d < 2*√k  → overshoot + oscillation (organic feel)
    //   over-damped:   d > 2*√k  → sluggish, no overshoot

    // Spring easing objects — Bezier approximations of damped harmonic motion
    readonly property QtObject _springSnappy:  QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.2, 0.0, 0.0, 1.08] }
    readonly property QtObject _springBouncy:  QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.1, 0.0, 0.0, 1.25] }
    readonly property QtObject _springGentle:  QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.25, 0.0, 0.1, 1.06] }
    readonly property QtObject _springWobbly:  QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.05, 0.0, 0.0, 1.35] }
    readonly property QtObject _springSettle:  QtObject { property int type: Easing.Bezier; property list<real> bezierCurve: [0.22, 0.0, 0.0, 1.04] }

    // Pre-composed spring result objects (returned by reference, zero allocation)
    readonly property QtObject springSnappy:  QtObject { property int duration: root.springSnappyDur;  property QtObject easing: root._springSnappy }
    readonly property QtObject springBouncy:  QtObject { property int duration: root.springBouncyDur;  property QtObject easing: root._springBouncy }
    readonly property QtObject springGentle:  QtObject { property int duration: root.springGentleDur;  property QtObject easing: root._springGentle }
    readonly property QtObject springWobbly:  QtObject { property int duration: root.springBouncyDur;  property QtObject easing: root._springWobbly }
    readonly property QtObject springSettle:  QtObject { property int duration: root.settleDur;       property QtObject easing: root._springSettle }

    // ═══════════════════════════════════════════════════════════════════════════
    // DYNAMIC SPRING BUILDER (uses FMath physics)
    // ═══════════════════════════════════════════════════════════════════════════
    // Returns { duration, easing } tuned to the requested feel.
    // Stiffness: 100=gentle, 200=normal, 400=snappy, 800=aggressive
    function spring(stiffness, damping) {
        if (!enabled) return { duration: 0, easing: root.linear }
        var k = stiffness || 200
        var d = (damping !== undefined) ? damping : FMath.underDamping(k) // lightly under-damped by default
        var mass = 1.0
        var w0 = Math.sqrt(k / mass)
        var zeta = d / (2 * Math.sqrt(k * mass))
        // Duration: settle within 95% — roughly 3 / (zeta * w0) in seconds → ms
        var dur = Math.round(3000 / (zeta * w0 + 1))
        if (dur < 80) dur = 80
        if (dur > 1200) dur = 1200
        // Select best-matching preset easing based on damping ratio
        var e
        if      (zeta <= 0.3) e = root._springWobbly
        else if (zeta <= 0.6) e = root._springBouncy
        else if (zeta <= 0.9) e = root._springSnappy
        else if (zeta <= 1.2) e = root._springSettle
        else                  e = root.outQuart
        return { duration: dur, easing: e }
    }

    // Organic settle: overshoot + damped oscillation into position.
    // Returns best-matching preset for the requested overshoot amount.
    function organicSettle(overshootAmount) {
        var o = overshootAmount || 0.12
        // Map overshoot to closest preset
        if (o <= 0.04) return { duration: root.springSnappyDur, easing: root._springSettle }
        if (o <= 0.08) return { duration: root.springGentleDur, easing: root._springGentle }
        if (o <= 0.16) return { duration: root.springSnappyDur, easing: root._springSnappy }
        if (o <= 0.25) return { duration: root.springBouncyDur, easing: root._springBouncy }
        return { duration: root.springBouncyDur, easing: root._springWobbly }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PRE-COMPUTED ANIMATION PRESETS (frequent patterns, zero overhead)
    // ═══════════════════════════════════════════════════════════════════════════

    // List operations (ListView add/remove/displace)
    readonly property QtObject listAdd:       QtObject { property int duration: root.standardNormal; property QtObject easing: root.outBack }
    readonly property QtObject listRemove:    QtObject { property int duration: root.standardSmall;  property QtObject easing: root.accelerate }
    readonly property QtObject listDisplaced: QtObject { property int duration: root.standardNormal; property QtObject easing: root.outQuart }

    // Popup open/close pairs (enter emphasizes, exit accelerates out)
    readonly property QtObject popupOpen:     QtObject { property int duration: root.emphasizedNormal; property QtObject easing: root.emphasized }
    readonly property QtObject popupClose:    QtObject { property int duration: root.standardNormal;  property QtObject easing: root.emphasizedExit }

    // Content fade-in/out (asymmetric — fade in slower, out faster)
    readonly property QtObject fadeIn:        QtObject { property int duration: Math.round(root.standardNormal * 0.55); property QtObject easing: root.outSine }
    readonly property QtObject fadeOut:       QtObject { property int duration: Math.round(root.standardNormal * 0.2);  property QtObject easing: root.accelerate }

    // Hover feedback
    readonly property QtObject hoverOn:       QtObject { property int duration: root.microHover; property QtObject easing: root.microGrow }
    readonly property QtObject hoverOff:      QtObject { property int duration: root.microHover; property QtObject easing: root.outQuart }

    // Ripple / pulse
    readonly property QtObject ripple:        QtObject { property int duration: root.standardMicro; property QtObject easing: root.microPulse }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPER API (backward-compatible)
    // ═══════════════════════════════════════════════════════════════════════════
    function easing(name) {
        switch (name) {
            case "standard":       return root.standard
            case "outQuart":       return root.outQuart
            case "outCubic":       return root.outCubic
            case "outQuint":       return root.outQuint
            case "outSine":        return root.outSine
            case "outBack":        return root.outBack
            case "outElastic":     return root.outElastic
            case "outBounce":      return root.outBounce
            case "inOutBack":      return root.inOutBack
            case "inOutCubic":     return root.inOutCubic
            case "inOutQuint":     return root.inOutQuint
            case "microGrow":      return root.microGrow
            case "microShrink":    return root.microShrink
            case "microPulse":     return root.microPulse
            case "emphasized":     return root.emphasized
            case "emphasizedExit": return root.emphasizedExit
            case "decelerate":     return root.decelerate
            case "accelerate":     return root.accelerate
            case "collapse":       return root.collapse
            case "spatial":        return root.spatial
            case "linear":         return root.linear
            default:               return root.standard
        }
    }

    function duration(type, size) {
        if (!enabled) return 0
        switch (type + "-" + size) {
            case "standard-micro":       return standardMicro
            case "standard-small":       return standardSmall
            case "standard-normal":      return standardNormal
            case "standard-large":       return standardLarge
            case "standard-extraLarge":  return standardXL
            case "emphasized-small":     return emphasizedSmall
            case "emphasized-normal":    return emphasizedNormal
            case "emphasized-large":     return emphasizedLarge
            case "spatial-fast":         return spatialFast
            case "spatial-default":      return spatialDefault
            case "spatial-slow":         return spatialSlow
            case "spring-snappy":        return springSnappyDur
            case "spring-normal":        return springNormalDur
            case "spring-bouncy":        return springBouncyDur
            case "spring-gentle":        return springGentleDur
            case "settle":               return settleDur
            default:                     return standardNormal
        }
    }

    function listAddTransition()      { return enabled ? listAdd      : ({ duration: 0, easing: root.linear }) }
    function listRemoveTransition()   { return enabled ? listRemove   : ({ duration: 0, easing: root.linear }) }
    function listDisplacedTransition(){ return enabled ? listDisplaced : ({ duration: 0, easing: root.linear }) }
}

import QtQuick
import Quickshell
import "../theme"

/*!
    AnimatedBehavior v2 — zero-allocation NumberAnimation wrapper.
    ─────────────────────────────────────────────────────────────

    Properties read pre-computed Anim objects directly (no function calls).
    New: "variant" supports spring presets + organic settle.

    Usage:
      Behavior on x { AnimatedBehavior { type: "standard"; size: "normal" } }
      Behavior on scale { AnimatedBehavior { variant: "springBouncy" } }
      Behavior on opacity { AnimatedBehavior { variant: "fadeIn" } }
*/
NumberAnimation {
    id: root

    property string type: "standard"
    property string size: "normal"
    property string variant: ""  // Overrides type+size when set (e.g. "springBouncy", "microGrow")

    // ── Duration — reads pre-computed Anim property directly ──────────────
    duration: {
        if (!Anim.enabled) return 0
        // Variant presets take priority (single lookup)
        if (variant !== "") {
            switch (variant) {
                // Spring presets
                case "springSnappy":  return Anim.springSnappyDur
                case "springBouncy":  return Anim.springBouncyDur
                case "springGentle":  return Anim.springGentleDur
                case "springWobbly":  return Anim.springBouncyDur
                case "springSettle":  return Anim.settleDur
                // Micro-interaction
                case "microGrow":     return Anim.microHover
                case "microShrink":   return Anim.microHover
                case "microPulse":    return Anim.standardMicro
                case "ripple":        return Anim.standardMicro
                // Popup presets
                case "popupOpen":     return Anim.emphasizedNormal
                case "popupClose":    return Anim.standardNormal
                // Fade presets
                case "fadeIn":        return Math.round(Anim.standardNormal * 0.55)
                case "fadeOut":       return Math.round(Anim.standardNormal * 0.2)
                // Hover
                case "hoverOn":       return Anim.microHover
                case "hoverOff":      return Anim.microHover
                default:              return Anim.standardNormal
            }
        }
        // Standard type+size
        switch (type + "-" + size) {
            case "standard-micro":       return Anim.standardMicro
            case "standard-small":       return Anim.standardSmall
            case "standard-normal":      return Anim.standardNormal
            case "standard-large":       return Anim.standardLarge
            case "standard-extraLarge":  return Anim.standardXL
            case "emphasized-small":     return Anim.emphasizedSmall
            case "emphasized-normal":    return Anim.emphasizedNormal
            case "emphasized-large":     return Anim.emphasizedLarge
            case "spatial-fast":         return Anim.spatialFast
            case "spatial-default":      return Anim.spatialDefault
            case "spatial-slow":         return Anim.spatialSlow
            case "spring-snappy":        return Anim.springSnappyDur
            case "spring-normal":        return Anim.springNormalDur
            case "spring-bouncy":        return Anim.springBouncyDur
            case "spring-gentle":        return Anim.springGentleDur
            case "settle":               return Anim.settleDur
            default:                     return Anim.standardNormal
        }
    }

    // ── Easing — single QtObject reference read, zero allocation ───────────
    readonly property QtObject _ease: {
        // Variant presets first
        if (variant !== "") {
            switch (variant) {
                case "springSnappy":  return Anim._springSnappy
                case "springBouncy":  return Anim._springBouncy
                case "springGentle":  return Anim._springGentle
                case "springWobbly":  return Anim._springWobbly
                case "springSettle":  return Anim._springSettle
                case "microGrow":     return Anim.microGrow
                case "microShrink":   return Anim.microShrink
                case "microPulse":    return Anim.microPulse
                case "ripple":        return Anim.microPulse
                case "popupOpen":     return Anim.emphasized
                case "popupClose":    return Anim.emphasizedExit
                case "fadeIn":        return Anim.outSine
                case "fadeOut":       return Anim.accelerate
                case "hoverOn":       return Anim.microGrow
                case "hoverOff":      return Anim.outQuart
                default:              return Anim.standard
            }
        }
        // Type-based lookup
        switch (type) {
            case "standard":       return Anim.standard
            case "outQuart":       return Anim.outQuart
            case "outCubic":       return Anim.outCubic
            case "outQuint":       return Anim.outQuint
            case "outSine":        return Anim.outSine
            case "outBack":        return Anim.outBack
            case "outElastic":     return Anim.outElastic
            case "outBounce":      return Anim.outBounce
            case "inOutBack":      return Anim.inOutBack
            case "inOutCubic":     return Anim.inOutCubic
            case "inOutQuint":     return Anim.inOutQuint
            case "emphasized":     return Anim.emphasized
            case "emphasizedExit": return Anim.emphasizedExit
            case "decelerate":     return Anim.decelerate
            case "accelerate":     return Anim.accelerate
            case "collapse":       return Anim.collapse
            case "spatial":        return Anim.spatial
            case "linear":         return Anim.linear
            default:               return Anim.standard
        }
    }

    easing.type: _ease.type
    easing.bezierCurve: _ease.bezierCurve
}

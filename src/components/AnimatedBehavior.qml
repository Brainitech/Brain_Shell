import QtQuick
import Quickshell
import "../theme"

/*!
    AnimatedBehavior — lightweight NumberAnimation wrapper.
    Ambxst-optimized: reads pre-computed Anim properties directly, no function calls.
*/
NumberAnimation {
    id: root

    property string type: "standard"
    property string size: "normal"
    property string variant: ""

    // ── Duration — reads pre-computed Anim property directly ──────────────
    duration: {
        if (!Anim.enabled) return 0
        switch (type + "-" + size) {
            case "standard-small":       return Anim.standardSmall
            case "standard-normal":      return Anim.standardNormal
            case "standard-large":       return Anim.standardLarge
            case "standard-extraLarge":  return Anim.standardExtraLarge
            case "emphasized-small":     return Anim.emphasizedSmall
            case "emphasized-normal":    return Anim.emphasizedNormal
            case "emphasized-large":     return Anim.emphasizedLarge
            case "spatial-fast":         return Anim.spatialFast
            case "spatial-default":      return Anim.spatialDefault
            case "spatial-slow":         return Anim.spatialSlow
            case "spring-small":         return Anim.springSmall
            case "spring-normal":        return Anim.springNormal
            case "spring-large":         return Anim.springLarge
            default:                     return Anim.standardNormal
        }
    }

    // ── Easing — reads pre-computed QtEasingCurve directly ────────────────
    readonly property QtEasingCurve _ease: {
        var n = variant || type
        switch (n) {
            case "standard":       return Anim.standard
            case "outQuart":       return Anim.outQuart
            case "outCubic":       return Anim.outCubic
            case "outSine":        return Anim.outSine
            case "emphasized":     return Anim.emphasized
            case "emphasizedExit": return Anim.emphasizedExit
            case "decelerate":     return Anim.decelerate
            case "accelerate":     return Anim.accelerate
            case "collapse":       return Anim.collapse
            case "spatial":        return Anim.spatialEase
            case "linear":         return Anim.linear
            default:               return Anim.standard
        }
    }

    easing.type: _ease.type
    easing.bezierCurve: _ease.bezierCurve
}

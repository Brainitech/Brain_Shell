pragma Singleton
import QtQuick
import "../services"

QtObject {
    id: root
    property bool enabled: true
    readonly property real _speed: ShellConfigService.animationSpeed

    readonly property int standardSmall:     enabled ? 150 : 0
    readonly property int standardNormal:    enabled ? 300 : 0
    readonly property int standardLarge:     enabled ? 400 : 0
    readonly property int standardExtraLarge: enabled ? 500 : 0
    readonly property int emphasizedSmall:   enabled ? 250 : 0
    readonly property int emphasizedNormal:  enabled ? 400 : 0
    readonly property int emphasizedLarge:   enabled ? 550 : 0
    readonly property int spatialFast:       enabled ? 200 : 0
    readonly property int spatialDefault:    enabled ? 350 : 0
    readonly property int spatialSlow:       enabled ? 500 : 0
    readonly property int springSmall:       enabled ? 350 : 0
    readonly property int springNormal:      enabled ? 500 : 0
    readonly property int springLarge:       enabled ? 650 : 0

    property alias animationsEnabled: root.enabled

    // Pre-computed easing objects — named .type and .bezierCurve for API compat
    readonly property QtObject standard:       QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.25, 0.0, 0.0, 1.0] }
    readonly property QtObject outQuart:       QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.25, 0.0, 0.0, 1.0] }
    readonly property QtObject outCubic:       QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.0,  0.0, 0.2, 1.0] }
    readonly property QtObject outSine:        QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.4,  0.0, 0.6, 1.0] }
    readonly property QtObject emphasized:     QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.05, 0.7, 0.1, 1.0] }
    readonly property QtObject emphasizedExit: QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.3,  0.0, 0.8, 0.15] }
    readonly property QtObject decelerate:     QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.0,  0.0, 0.2, 1.0] }
    readonly property QtObject accelerate:     QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.4,  0.0, 1.0, 1.0] }
    readonly property QtObject collapse:       QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.25, 1.0, 0.5, 1.0] }
    readonly property QtObject spatialEase:    QtObject { property int type: Easing.Bezier; property var bezierCurve: [0.4,  0.0, 0.2, 1.0] }
    readonly property QtObject linear:         QtObject { property int type: Easing.Linear; property var bezierCurve: [] }

    // ── Backward-compat helpers ───────────────────────────────────────────
    function easing(name) {
        switch (name) {
            case "standard":       return root.standard
            case "outQuart":       return root.outQuart
            case "outCubic":       return root.outCubic
            case "outSine":        return root.outSine
            case "emphasized":     return root.emphasized
            case "emphasizedExit": return root.emphasizedExit
            case "decelerate":     return root.decelerate
            case "accelerate":     return root.accelerate
            case "collapse":       return root.collapse
            case "spatial":        return root.spatialEase
            case "linear":         return root.linear
            default:               return root.standard
        }
    }

    function duration(type, size) {
        if (!enabled) return 0
        switch (type + "-" + size) {
            case "standard-small":       return standardSmall
            case "standard-normal":      return standardNormal
            case "standard-large":       return standardLarge
            case "standard-extraLarge":  return standardExtraLarge
            case "emphasized-small":     return emphasizedSmall
            case "emphasized-normal":    return emphasizedNormal
            case "emphasized-large":     return emphasizedLarge
            case "spatial-fast":         return spatialFast
            case "spatial-default":      return spatialDefault
            case "spatial-slow":         return spatialSlow
            case "spring-small":         return springSmall
            case "spring-normal":        return springNormal
            case "spring-large":         return springLarge
            default:                     return standardNormal
        }
    }

    readonly property QtObject listAdd:      QtObject { property int duration: Anim.standardNormal; property QtObject easing: Anim.standard }
    readonly property QtObject listRemove:   QtObject { property int duration: Anim.standardSmall;  property QtObject easing: Anim.accelerate }
    readonly property QtObject listDisplaced: QtObject { property int duration: Anim.standardNormal; property QtObject easing: Anim.spatialEase }

    function listAddTransition()      { return enabled ? listAdd      : ({ duration: 0, easing: root.linear }) }
    function listRemoveTransition()   { return enabled ? listRemove   : ({ duration: 0, easing: root.linear }) }
    function listDisplacedTransition(){ return enabled ? listDisplaced : ({ duration: 0, easing: root.linear }) }
}

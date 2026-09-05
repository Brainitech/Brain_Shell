pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../services"

QtObject {
    id: root

    // "slide" | "parallax" | "none"
    property string style: "slide"

    property real speedMultiplier: 1.0
    property string curveStyle: "smooth"


    function setStyle(newStyle) {
        root.style = newStyle
        PrefsService.saveConfig()
    }
    
    function setSpeedMultiplier(val) {
        root.speedMultiplier = val
        PrefsService.saveConfig()
    }
    
    function setCurve(val) {
        root.curveStyle = val
        PrefsService.saveConfig()
    }

    // Standard durations automatically scaled by speedMultiplier
    readonly property int superFast:  Math.max(0, Math.round(80 / speedMultiplier))
    readonly property int fast:       Math.max(0, Math.round(100 / speedMultiplier))
    readonly property int color:      Math.max(0, Math.round(120 / speedMultiplier))
    readonly property int mediumFast: Math.max(0, Math.round(150 / speedMultiplier))
    readonly property int normal:     Math.max(0, Math.round(200 / speedMultiplier))
    readonly property int mediumSlow: Math.max(0, Math.round(250 / speedMultiplier))
    readonly property int slow:       Math.max(0, Math.round(350 / speedMultiplier))
    readonly property int slower:     Math.max(0, Math.round(400 / speedMultiplier))
    readonly property int verySlow:   Math.max(0, Math.round(500 / speedMultiplier))
    readonly property int extraSlow:  Math.max(0, Math.round(600 / speedMultiplier))
    readonly property int megaSlow:   Math.max(0, Math.round(900 / speedMultiplier))
    readonly property int transition: Math.max(0, Math.round(320 / speedMultiplier))

    // Global Curve Modifier
    readonly property int globalCurve: {
        if (curveStyle === "spring") return Easing.OutBack;
        if (curveStyle === "cinematic") return Easing.InOutQuart;
        return Easing.OutQuart; // Default to smooth
    }

    // Easings (Mapping legacy bindings to the new global curve where appropriate)
    // To ensure a truly unified feel, we route the common transition easings through globalCurve.
    readonly property int outCubic: globalCurve
    readonly property int inOutCubic: globalCurve
    readonly property int outExpo: globalCurve
    readonly property int outBack: globalCurve
    
    // Explicit curves for specific UI micro-interactions (not globally mapped unless requested)
    readonly property int inOutSine: Easing.InOutSine
    readonly property int outQuad: Easing.OutQuad
    readonly property int inQuad: Easing.InQuad
    readonly property int inOutQuad: Easing.InOutQuad
    readonly property int outElastic: Easing.OutElastic
    readonly property int inCubic: Easing.InCubic
    readonly property int linear: Easing.Linear

    Component.onCompleted: {
        // Auto-create the JSON file if it doesn't exist yet on startup
        var initProc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { }', root, "InitConfigProc")
        initProc.command = [
            "bash", "-c",
            "if [ ! -f '" + root.configPath + "' ]; then mkdir -p \"$(dirname '" + root.configPath + "')\" && cat << 'EOF' > '" + root.configPath + "'\n" +
            "{\n" +
            "    \"_comment_style\": \"Available styles: 'slide', 'parallax', 'none'\",\n" +
            "    \"style\": \"slide\",\n" +
            "    \"_comment_speed\": \"Multiplier for all animations. 1.0 is default. 0.5 is 2x faster, 2.0 is 2x slower.\",\n" +
            "    \"speed_multiplier\": 1.0,\n" +
            "    \"_comment_curve\": \"Available curves: 'smooth', 'spring', 'linear', 'cinematic'\",\n" +
            "    \"curve\": \"smooth\"\n" +
            "}\nEOF\nfi"
        ]
        initProc.running = true
    }

    property var _conn: Connections {
        target: PrefsService
        function onLoaded() {
            root.style = PrefsService.animStyle
            root.speedMultiplier = PrefsService.animSpeed
            root.curveStyle = PrefsService.animCurve
        }
        function onAnimStyleChanged() { root.style = PrefsService.animStyle }
        function onAnimSpeedChanged() { root.speedMultiplier = PrefsService.animSpeed }
        function onAnimCurveChanged() { root.curveStyle = PrefsService.animCurve }
    }
}

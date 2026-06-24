pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // "slide" | "parallax" | "none"
    property string style: "slide"

    property real speedMultiplier: 1.0
    property string curveStyle: "smooth"

    // Config persistence
    readonly property string configPath: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/animation_prefs.json"
    property var _prefsFile: FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var txt = text()
            if (txt && txt !== "") {
                try {
                    var obj = JSON.parse(txt)
                    if (obj.style && obj.style !== "") root.style = obj.style
                    if (obj.speed_multiplier) root.speedMultiplier = obj.speed_multiplier
                    if (obj.curve && obj.curve !== "") root.curveStyle = obj.curve
                } catch(e) {}
            }
        }
    }

    property var saveConfigProc: Process {}

    function setStyle(newStyle) {
        root.style = newStyle
        _save()
    }
    
    function setSpeedMultiplier(val) {
        root.speedMultiplier = val
        _save()
    }
    
    function setCurve(val) {
        root.curveStyle = val
        _save()
    }

    function _save() {
        var json = JSON.stringify({
            "_comment_style": "Available styles: 'slide', 'parallax', 'none'",
            "style": root.style,
            "_comment_speed": "Animation speed. 1.0 is default. 2.0 is 2x faster, 0.5 is 2x slower.",
            "speed_multiplier": root.speedMultiplier,
            "_comment_curve": "Available curves: 'smooth', 'spring', 'linear', 'cinematic'",
            "curve": root.curveStyle
        }, null, 4)
        
        saveConfigProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + root.configPath + "')\" && " +
            "cat << 'EOF' > '" + root.configPath + "'\n" + json + "\nEOF"
        ]
        saveConfigProc.running = true
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
        if (curveStyle === "linear") return Easing.Linear;
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
}

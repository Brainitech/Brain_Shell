pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // "slide" | "parallax" | "none"
    property string style: "slide"

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
                    if (obj.superFast) root.superFast = obj.superFast
                    if (obj.fast) root.fast = obj.fast
                    if (obj.color) root.color = obj.color
                    if (obj.mediumFast) root.mediumFast = obj.mediumFast
                    if (obj.normal) root.normal = obj.normal
                    if (obj.mediumSlow) root.mediumSlow = obj.mediumSlow
                    if (obj.slow) root.slow = obj.slow
                    if (obj.slower) root.slower = obj.slower
                    if (obj.verySlow) root.verySlow = obj.verySlow
                    if (obj.extraSlow) root.extraSlow = obj.extraSlow
                    if (obj.megaSlow) root.megaSlow = obj.megaSlow
                    if (obj.transition) root.transition = obj.transition
                } catch(e) {}
            }
        }
    }

    property var saveConfigProc: Process {}

    function setStyle(newStyle) {
        root.style = newStyle
        _save()
    }
    
    function setSpeed(prop, val) {
        root[prop] = val
        _save()
    }

    function _save() {
        var json = JSON.stringify({
            "_comment_style": "Available styles: 'slide', 'parallax', 'none'",
            "style": root.style,
            "_comment_speeds": "You can override default animation speeds below (in milliseconds).",
            "superFast": root.superFast,
            "fast": root.fast,
            "color": root.color,
            "mediumFast": root.mediumFast,
            "normal": root.normal,
            "mediumSlow": root.mediumSlow,
            "slow": root.slow,
            "slower": root.slower,
            "verySlow": root.verySlow,
            "extraSlow": root.extraSlow,
            "megaSlow": root.megaSlow,
            "transition": root.transition
        }, null, 4)
        
        saveConfigProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + root.configPath + "')\" && " +
            "cat << 'EOF' > '" + root.configPath + "'\n" + json + "\nEOF"
        ]
        saveConfigProc.running = true
    }
    // Standard durations
    property int superFast: 80
    property int fast: 100
    property int color: 120
    property int mediumFast: 150
    property int normal: 200
    property int mediumSlow: 250
    property int slow: 350
    property int slower: 400
    property int verySlow: 500
    property int extraSlow: 600
    property int megaSlow: 900
    property int transition: 320

    // Easings
    property int outCubic: Easing.OutCubic
    property int inOutCubic: Easing.InOutCubic
    property int inOutSine: Easing.InOutSine
    property int outExpo: Easing.OutExpo
    property int outBack: Easing.OutBack
    property int outQuad: Easing.OutQuad
    property int inQuad: Easing.InQuad
    property int inOutQuad: Easing.InOutQuad
    property int outElastic: Easing.OutElastic
    property int inCubic: Easing.InCubic
    property int linear: Easing.Linear
}

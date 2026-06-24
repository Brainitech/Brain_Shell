pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    signal loaded()

    property string customAvatarPath: ""
    property bool bootFocusMode: false
    property string defaultDashboardTab: "Home"
    property string defaultAudioTab: "Output"
    property bool use24HourTime: false

    property string _cfgBuf: ""
    
    property var _configFile: FileView {
        path: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/shell_prefs.json"
        onLoaded: {
            root._parse(text())
        }
    }

    function _parse(raw) {
        if (!raw || raw.trim() === "") return
        try {
            var o = JSON.parse(raw)
            if (o.customAvatarPath !== undefined) root.customAvatarPath = o.customAvatarPath
            if (o.bootFocusMode !== undefined) root.bootFocusMode = o.bootFocusMode
            if (o.defaultDashboardTab !== undefined) root.defaultDashboardTab = o.defaultDashboardTab
            if (o.defaultAudioTab !== undefined) root.defaultAudioTab = o.defaultAudioTab
            if (o.use24HourTime !== undefined) root.use24HourTime = o.use24HourTime
        } catch(e) {}
        root.loaded()
    }

    function saveConfig() {
        var path = Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/shell_prefs.json"
        var data = JSON.stringify({
            customAvatarPath: root.customAvatarPath,
            bootFocusMode: root.bootFocusMode,
            defaultDashboardTab: root.defaultDashboardTab,
            defaultAudioTab: root.defaultAudioTab,
            use24HourTime: root.use24HourTime
        })
        _saveProc.command = ["bash", "-c", "mkdir -p \"$(dirname '" + path + "')\" && printf '%s' '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"]
        _saveProc.running = false
        _saveProc.running = true
    }

    property var _saveProc: Process { command: []; running: false }
}

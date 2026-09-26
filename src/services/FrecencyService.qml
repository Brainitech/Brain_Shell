import QtQuick
import Quickshell
import Quickshell.Io
import "../"
pragma Singleton

QtObject {
    id: root

    property var _data: ({})
    property bool _loaded: false

    property var _initProc: Process {
        command: []
        running: false
        onExited: {
            _fileView.path = ShellState.userDataDir + "/app_frecency.json"
        }
    }

    property var _fileView: FileView {
        watchChanges: true
        onTextChanged: {
            var content = text()
            if (content.trim() === "") {
                root._data = {}
            } else {
                try {
                    root._data = JSON.parse(content)
                } catch (e) {
                    console.log("FrecencyService: JSON parse error:", e)
                    root._data = {}
                }
            }
            root._loaded = true
        }
    }

    property var _saveProc: Process {
        command: []
        running: false
    }

    function _save() {
        var path = ShellState.userDataDir + "/app_frecency.json"
        var jsonStr = JSON.stringify(root._data)
        _saveProc.command = ["bash", "-c", "mkdir -p \"$(dirname '" + path + "')\" && printf '%s' '" + jsonStr.replace(/'/g, "'\\''") + "' > '" + path + "'"]
        _saveProc.running = false
        _saveProc.running = true
    }

    function recordLaunch(appId) {
        if (!appId || !_loaded) return
        
        var now = Math.floor(Date.now() / 1000)
        var appData = root._data[appId] || { timestamps: [] }
        
        appData.timestamps.unshift(now)
        if (appData.timestamps.length > 10) {
            appData.timestamps = appData.timestamps.slice(0, 10)
        }
        
        root._data[appId] = appData
        _save()
    }

    function getScore(appId) {
        if (!appId || !_loaded || !root._data[appId]) return 0
        
        var now = Math.floor(Date.now() / 1000)
        var timestamps = root._data[appId].timestamps
        var score = 0
        
        for (var i = 0; i < timestamps.length; i++) {
            var age = now - timestamps[i]
            if (age < 14400)         score += 100
            else if (age < 86400)    score += 70
            else if (age < 259200)   score += 50
            else if (age < 604800)   score += 30
            else if (age < 1209600)  score += 10
            else                     score += 1
        }
        
        return score
    }

    function sortApps(appsArray) {
        if (!appsArray) return []
        
        return appsArray.slice().sort(function(a, b) {
            var scoreA = root.getScore(a.id)
            var scoreB = root.getScore(b.id)
            
            if (scoreA !== scoreB) {
                return scoreB - scoreA
            }
            
            var nameA = (a.name || "").toLowerCase()
            var nameB = (b.name || "").toLowerCase()
            return nameA.localeCompare(nameB)
        })
    }

    Component.onCompleted: {
        var p = ShellState.userDataDir + "/app_frecency.json"
        _initProc.command = ["bash", "-c", "mkdir -p \"$(dirname \"" + p + "\")\" && touch \"" + p + "\""]
        _initProc.running = true
    }
}

pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

QtObject {
    id: root
    
    property int brightness: 0
    property int maxBrightness: 100
    
    function setBrightness(v) {
        brightWrite.command = ["brightnessctl", "set", v + "%"]
        brightWrite.running = true
        root.brightness = v
    }
    
    property var brightRead: Process {
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(',')
                if (parts.length >= 4) {
                    var pctStr = parts[3]
                    var val = parseInt(pctStr.replace('%', ''))
                    if (!isNaN(val)) root.brightness = val
                }
            }
        }
    }
    
    property var brightWrite: Process {
        command: []
        running: false
        onRunningChanged: if (!running) root.brightRead.running = true
    }
    
    property var pollTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.brightRead.running = true
    }
}

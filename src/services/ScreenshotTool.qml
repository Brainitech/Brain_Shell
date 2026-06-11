pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell
import "../"

/*!
    ScreenshotTool — screenshot utility using grim + slurp.

    Modes: screen, window, region.
    Saves to ~/Pictures/Screenshots/ with timestamp.
    Supports copy-to-clipboard.
*/
QtObject {
    id: root

    property bool capturing: false

    property var _notifyProc: Process { command: []; running: false }
    property var _captureProc: Process {
        command: []
        running: false
        onExited: function(exitCode) {
            root.capturing = false
            if (exitCode === 0 && root._lastFile !== "") {
                _notifyProc.command = ["bash", "-c",
                    "FILE=\"" + root._lastFile + "\"; " +
                    "DIR=\"$(dirname \"$FILE\")\"; " +
                    "ACTION=$(notify-send" +
                    " --app-name 'Screenshot'" +
                    " --icon 'camera-photo-symbolic'" +
                    " --action 'view=View Folder'" +
                    " --action 'copy=Copy to Clipboard'" +
                    " --wait" +
                    " 'Screenshot Saved' \"$FILE\"); " +
                    "case \"$ACTION\" in" +
                    "  view) xdg-open \"$DIR\" ;;" +
                    "  copy) wl-copy < \"$FILE\" ;;" +
                    "esac"]
                _notifyProc.running = true
            }
        }
    }

    property string _lastFile: ""
    property var _windowPickerProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            id: windowPickerOut
            onStreamFinished: {
                var g = windowPickerOut.text.trim()
                if (g !== "") root._doCapture(g)
                else root.capturing = false
            }
        }
    }

    property var _regionPickerProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            id: regionPickerOut
            onStreamFinished: {
                var g = regionPickerOut.text.trim()
                if (g !== "") root._doCapture(g)
                else root.capturing = false
            }
        }
    }

    function captureScreen() {
        root._doCapture("")
    }

    function captureWindow() {
        root.capturing = true
        _windowPickerProc.command = [
            "bash", "-c",
            "hyprctl clients -j | python3 -c \"" +
            "import sys,json; ws=json.load(sys.stdin); " +
            "[print(str(w['at'][0])+','+str(w['at'][1])+' '+str(w['size'][0])+'x'+str(w['size'][1])) " +
            "for w in ws if w['mapped']]\" | slurp"
        ]
        _windowPickerProc.running = false
        _windowPickerProc.running = true
    }

    function captureRegion() {
        root.capturing = true
        _regionPickerProc.command = [
            "bash", "-c",
            "hyprctl monitors -j | python3 -c \"" +
            "import sys,json; ms=json.load(sys.stdin); " +
            "[print(str(m['x'])+','+str(m['y'])+' '+str(m['width'])+'x'+str(m['height'])) for m in ms]\" | slurp"
        ]
        _regionPickerProc.running = false
        _regionPickerProc.running = true
    }

    function _doCapture(geometry) {
        root.capturing = true
        var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        root._lastFile = Quickshell.env("HOME") + "/Pictures/Screenshots/" + ts + ".png"

        var cmd = "mkdir -p $HOME/Pictures/Screenshots && grim"
        if (geometry !== "") cmd += " -g '" + geometry + "'"
        cmd += " '" + root._lastFile + "'"

        _captureProc.command = ["bash", "-c", cmd]
        _captureProc.running = false
        _captureProc.running = true
    }
}

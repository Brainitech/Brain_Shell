import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../components"

// Dashboard Home tab — layout only.
//
//  ┌──────────────┬───────────────────────────┬──────────────┐
//  │ ProfileCard  │  ClockCard                │              │
//  ├──────────────┤                           │ QuickSettings│
//  │ CalendarCard │  PlayerCard               │ (brightness  │
//  │              │                           │  + toggles)  │
//  └──────────────┴───────────────────────────┴──────────────┘

Item {
    id: root

    property real localScale: 1.0

    readonly property int colW:     Math.round(210 * localScale)
    readonly property int gap:      Math.round(8 * localScale)
    readonly property int profileH: Math.round(160 * localScale)
    readonly property int clockH:   Math.round(220 * localScale)

    // ── Avatar path ───────────────────────────────────────────────────────────
    property string _avatarPath: ""
    property string _staticJpg:  ""   // resolved once: $HOME/.curr_wall_static.jpg
    property string _customAvatar: ""

    FileView {
        id: profilePrefs
        path: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/profile_prefs.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var txt = text()
            if (txt && txt !== "") {
                try {
                    var obj = JSON.parse(txt)
                    if (obj.custom_avatar && obj.custom_avatar !== "") {
                        root._customAvatar = obj.custom_avatar
                    } else {
                        root._customAvatar = ""
                    }
                } catch(e) {}
            } else {
                root._customAvatar = ""
            }
            root._updateAvatar()
        }
    }

    function _updateAvatar() {
        if (root._customAvatar !== "") {
            root._avatarPath = root._customAvatar
        } else if (root._staticJpg !== "") {
            root._avatarPath = root._staticJpg
        }
    }

    // Resolve $HOME once, then set the fixed path.
    // Both gif (magick frame) and non-gif (symlink) cases now land at the
    // same ~/.curr_wall_static.jpg so no readlink resolution is needed.
    Process {
        command: ["bash", "-c", "echo $HOME"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var h = line.trim()
                if (h === "") return
                root._staticJpg  = h + "/.curr_wall_static.jpg"
                root._updateAvatar()
            }
        }
    }

    // Re-arm the image on every successful apply.
    Connections {
        target: WallpaperService
        function onWallpaperApplied(path) {
            root._avatarPath = ""
            reloadTimer.restart()
        }
    }

    Timer {
        id: reloadTimer
        interval: 0
        repeat:   false
        onTriggered: root._updateAvatar()
    }

    Component.onCompleted: {
        var p = Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/profile_prefs.json"
        var initProc = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { }', root, "InitProfileProc")
        initProc.command = [
            "bash", "-c",
            "if [ ! -f '" + p + "' ]; then mkdir -p \"$(dirname '" + p + "')\" && echo '{\"custom_avatar\": \"\"}' > '" + p + "'; fi"
        ]
        initProc.running = true
    }

    // ── Left column ───────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW

        ProfileCard {
            id: profileCard
            localScale: root.localScale
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH
            avatarPath: root._avatarPath
        }

        CalendarCard {
            localScale: root.localScale
            anchors {
                left: parent.left; right: parent.right
                top: profileCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }

    // ── Right column — QuickSettings fills full height ────────────────────────
    QuickSettings {
        id: rightCard
        localScale: root.localScale
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW
    }

    // ── Center column ─────────────────────────────────────────────────────────
    Item {
        id: centerCol
        anchors {
            left:  leftCol.right;  leftMargin:  root.gap
            right: rightCard.left; rightMargin: root.gap
            top:   parent.top;     bottom:      parent.bottom
            topMargin: root.gap
        }

        ClockCard {
            id: clockCard
            localScale: root.localScale
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.clockH
        }

        PlayerCard {
            localScale: root.localScale
            anchors {
                left:   parent.left;  right:  parent.right
                top:    clockCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }
}

import QtQuick
import Quickshell.Io
import "../"
import "../components"

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

    readonly property int colW:    210
    readonly property int gap:       8
    readonly property int profileH: 160
    readonly property int clockH:   220

    // ── Avatar path — resolved from ~/.curr_wall_static symlink ──────────────
    property string _avatarPath: ""

    // Polls readlink -f on the symlink every 2s.
    // ln -sf replaces a symlink inode — that's a directory event, not a file
    // content change — so FileView.watchChanges never fires for it. Polling
    // is the reliable alternative.
    Process {
        id: wallReadProc
        command: ["bash", "-c", "readlink -f ~/.curr_wall_static 2>/dev/null"]
        running: true   // first read on startup
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.trim()
                if (p !== "" && p !== root._avatarPath)
                    root._avatarPath = p
            }
        }
    }

    Timer {
        interval: 2000
        running:  true
        repeat:   true
        onTriggered: {
            wallReadProc.running = false
            wallReadProc.running = true
        }
    }

    // ── Left column ───────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW

        ProfileCard {
            id: profileCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH
            avatarPath: root._avatarPath
        }

        CalendarCard {
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
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.clockH
        }

        PlayerCard {
            anchors {
                left:   parent.left;  right:  parent.right
                top:    clockCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }
}

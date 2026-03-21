pragma Singleton
import QtQuick
import Quickshell.Io

// ============================================================
// WallpaperService — wallpaper list + apply pipeline
//
// Flow:
//   refresh()   → lists wallpaperDir via find
//   apply(path) → swww img + ln -sf ~/.curr_wall + matugen
// ============================================================

QtObject {
    id: root

    // ── State ─────────────────────────────────────────────────────────────────
    property var    wallpapers:   []
    property string currentWall:  ""
    property string previewWall:  ""
    property string scheme:       "content"
    property bool   applying:     false
    property string wallpaperDir: "~/Pictures/Wallpapers"

    readonly property var schemes: [
        "content", "tonal-spot", "fidelity", "neutral", "monochrome"
    ]

    // ── File listing ──────────────────────────────────────────────────────────
    function refresh() {
        if (listProc.running) return
        root.wallpapers = []
        listProc.running = true
    }

    property var listProc: Process {
        command: [
            "bash", "-c",
            "find " + root.wallpaperDir + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.gif' -o -iname '*.webp' \\) | sort"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var t = line.trim()
                if (t !== "") root.wallpapers = root.wallpapers.concat([t])
            }
        }
    }

    // ── Apply pipeline ────────────────────────────────────────────────────────
    function apply(path) {
        if (root.applying || path === "") return
        root.applying    = true
        root.currentWall = path
        applyProc.command = [
            "bash", "-c",
            "swww img --transition-type grow --transition-step 200 --transition-duration 1.2 --transition-fps 60 --transition-pos bottom \"" + path + "\" " +
            "&& ln -sf \"" + path + "\" ~/.curr_wall " +
            "&& matugen image \"$(readlink -f ~/.curr_wall)\" --source-color-index 0 --type scheme-" + root.scheme
        ]
        applyProc.running = true
    }

    property var applyProc: Process {
        onExited: function(exitCode, exitStatus) {
            root.applying = false
        }
    }

    Component.onCompleted: refresh()
}

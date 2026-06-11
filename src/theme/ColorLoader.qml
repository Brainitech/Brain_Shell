import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================
// ColorsLoader — watches ~/.cache/brain-shell/colors.json
// and exposes parsed color properties.
//
// Not a singleton. Instantiated as a property inside Theme.qml.
// Theme.qml reads loader.background, loader.active etc.
// ============================================================

QtObject {
    id: root

    // ── Parsed colors (with fallbacks matching original palette) ──────────────
    property color background: "#1a282a"
    property color active:     "#a6d0f7"
    property color text:       "#cdd6f4"
    property color subtext:    "#94e2d5"
    property color icon:       "#cdd6f4"
    property color border:     "#ffffff"
    property color iconFont:   "#2f8d97"

    // ── File watcher ──────────────────────────────────────────────────────────
    property var _file: FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/brain-shell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._parse(colorsFile.text())
    }

    // ── Fallback polling — ensures colors stay in sync on all filesystems ────
    property Timer _pollTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            colorsFile.reload()
        }
    }

    // ── Parser ────────────────────────────────────────────────────────────────
    function _parse(raw) {
        if (!raw || raw.trim() === "") return
        try {
            var obj = JSON.parse(raw)
            if (obj.background) root.background = obj.background
            if (obj.active)     root.active     = obj.active
            if (obj.text)       { root.text = obj.text; root.icon = obj.text }
            if (obj.subtext)    root.subtext    = obj.subtext
            if (obj.border)     root.border     = obj.border
            if (obj.iconFont)   root.iconFont   = obj.iconFont
        } catch (e) {
            // Malformed JSON — keep fallback values
        }
    }
}

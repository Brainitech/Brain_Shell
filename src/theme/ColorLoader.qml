import QtQuick
import Quickshell.Io
import "../"

// ============================================================
// ColorsLoader — watches ~/.cache/brain-shell/colors.json
// and exposes parsed color properties.
// ============================================================

QtObject {
    id: root
    
    property bool overrideMode: false

    // ── Parsed colors (with fallbacks matching original palette) ──────────────
    property color background: "#1a282a"
    property color active:     "#001f3c"
    property color text:       "#cdd6f4"
    property color subtext:    "#94e2d5"
    property color icon:       "#003cff"
    property color border:     "#ffffff"
    property color iconFont:   "#000000"

    // ── File watcher ──────────────────────────────────────────────────────────
    property var _file: FileView {
        id: colorsFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._parse(colorsFile.text())
    }

    property var _homeProc: Process {
        command: ["bash", "-c", "echo $HOME"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var h = line.trim()
                if (h !== "")
                    colorsFile.path = h + "/.cache/brain-shell/colors.json"
            }
        }
    }

    // ── Parser ────────────────────────────────────────────────────────────────
    function _adjustLightMode() {
        if (!PrefsService.darkMode && !root.overrideMode) {
            root.background = Qt.darker(root.background, 1.06)
            root.border = Qt.rgba(root.text.r, root.text.g, root.text.b, 0.25)
            root.subtext = Qt.rgba(root.text.r, root.text.g, root.text.b, 0.75)
            root.iconFont = root.active
        }
    }

    function _parse(raw) {
        if (!raw || raw.trim() === "") return
        if (root.overrideMode) {
            root._loadOverrides()
            return
        }
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
        _adjustLightMode()
    }

    function _loadOverrides() {
        root.background = PrefsService.overrideBg
        root.active     = PrefsService.overrideActive
        root.text       = PrefsService.overrideText
        root.border     = PrefsService.overrideBorder
        root.subtext    = PrefsService.overrideSubtext
        root.icon       = PrefsService.overrideIcon
        root.iconFont   = PrefsService.overrideIconFont
    }
    
    onOverrideModeChanged: {
        if (overrideMode) {
            _loadOverrides()
        } else {
            _parse(colorsFile.text())
        }
    }

    property var _con: Connections {
        target: PrefsService
        function onDarkModeChanged()          { if (!root.overrideMode) root._parse(colorsFile.text()) }
        function onOverrideBgChanged()        { if (root.overrideMode) root._loadOverrides() }
        function onOverrideBorderChanged()    { if (root.overrideMode) root._loadOverrides() }
        function onOverrideActiveChanged()    { if (root.overrideMode) root._loadOverrides() }
        function onOverrideIconFontChanged()  { if (root.overrideMode) root._loadOverrides() }
        function onOverrideTextChanged()      { if (root.overrideMode) root._loadOverrides() }
        function onOverrideSubtextChanged()   { if (root.overrideMode) root._loadOverrides() }
        function onOverrideIconChanged()      { if (root.overrideMode) root._loadOverrides() }
    }
}

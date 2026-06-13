pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

/*!
    WallpaperService — wallpaper list + apply pipeline + thumbnail cache.

    Replicates NothingLess' approach:
    - Wallpaper change is INSTANT (sets property, no shell blocking)
    - Matugen runs as fire-and-forget background process
    - Lockscreen frame generation is fire-and-forget
    - Symlink + static frame generated in background
*/
QtObject {
    id: root

    // ── Config paths ─────────────────────────────────────────────────────────
    readonly property string configPath:
        Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/wallpaper.json"
    readonly property string cacheDir:
        Quickshell.env("HOME") + "/.cache/Brain_Shell"
    readonly property string thumbDir:   cacheDir + "/thumbnails"
    readonly property string lockscreenDir: cacheDir + "/lockscreen"

    readonly property string fallbackDir:
        decodeURIComponent(Qt.resolvedUrl("../assets/wallpapers").toString().replace("file://", ""))

    // ── State ─────────────────────────────────────────────────────────────────
    property var    wallpapers:       []
    property string currentWall:      ""
    property string previewWall:      ""
    property string scheme:           "content"
    property bool   applying:         false
    property string wallpaperDir:     "~/Pictures/Wallpapers"
    property var    perScreenWallpapers: ({})

    // Subfolder / filter support
    property var activeFilters: []
    property var subfolderFilters: []
    property var allSubdirs: []

    // Thumbnails — deterministic proxy paths (NothingLess approach, no hash map)
    property bool   thumbsReady: false
    property string _thumbDir: thumbDir

    // Dedup matugen runs
    property string _lastMatugenWall: ""
    property string _lastMatugenScheme: ""

    readonly property var schemes: [
        "content", "tonal-spot", "fidelity", "fruit-salad", "neutral", "monochrome",
        "expressive", "rainbow"
    ]

    signal wallpaperApplied(string path)
    signal thumbnailsReady()
    signal wallpapersRefreshed()
    signal lockscreenFrameReady(string framePath)

    // ── File type detection ──────────────────────────────────────────────────
    function getFileType(path) {
        if (!path) return "unknown"
        var ext = path.toLowerCase().split('.').pop()
        if (['jpg','jpeg','png','webp','tif','tiff','bmp'].includes(ext)) return 'image'
        if (['gif'].includes(ext)) return 'gif'
        if (['mp4','webm','mkv','mov','avi'].includes(ext)) return 'video'
        return 'unknown'
    }

    function getColorSource(filePath) {
        var ft = root.getFileType(filePath)
        if (ft === 'video' || ft === 'gif') return root.thumbnailFor(filePath) || filePath
        return filePath
    }

    function getLockscreenFramePath(filePath) {
        if (!filePath) return ""
        var ft = root.getFileType(filePath)
        if (ft === 'image') return filePath
        if (ft === 'video' || ft === 'gif')
            return root.lockscreenDir + "/" + filePath.split('/').pop() + ".jpg"
        return filePath
    }

    // ── Deterministic thumbnail path (NothingLess proxy structure) ──────────
    function thumbnailFor(filePath) {
        if (!filePath) return ""
        // Normalize wallpaperDir to absolute (expand ~ if present)
        var base = root.wallpaperDir
        if (base.startsWith("~/"))
            base = Quickshell.env("HOME") + base.substring(1)
        if (!base.endsWith("/")) base += "/"
        if (!filePath.startsWith(base)) return ""
        var rel = filePath.substring(base.length)
        return root.thumbDir + "/" + rel + ".jpg"
    }

    // ── Filter utilities ─────────────────────────────────────────────────────
    readonly property var filteredWallpapers: {
        var all = root.wallpapers
        if (!all || !all.length) return []
        var sf = root.subfolderFilters
        if (sf && sf.length) {
            var base = root.wallpaperDir; if (!base.endsWith("/")) base += "/"
            var f = []; for (var i = 0; i < all.length; i++) {
                var rel = all[i]; if (rel.startsWith(base)) rel = rel.substring(base.length)
                if (sf.includes(rel.split("/")[0])) f.push(all[i])
            }; all = f
        }
        var af = root.activeFilters
        if (af && af.length) {
            var r = []; for (var j = 0; j < all.length; j++) {
                if (af.includes(root.getFileType(all[j]))) r.push(all[j])
            }; return r
        }
        return all
    }

    function toggleFilter(type) {
        var c = root.activeFilters.slice(); var i = c.indexOf(type)
        if (i >= 0) c.splice(i, 1); else c.push(type); root.activeFilters = c
    }
    function toggleSubfolder(f) {
        var c = root.subfolderFilters.slice(); var i = c.indexOf(f)
        if (i >= 0) c.splice(i, 1); else c.push(f); root.subfolderFilters = c
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  NAVIGATION — NothingLess style: set property, matugen in background
    // ═══════════════════════════════════════════════════════════════════════════
    function nextWallpaper() {
        if (!root.wallpapers.length) return
        var idx = root.wallpapers.indexOf(root.currentWall)
        idx = (idx < 0 || idx >= root.wallpapers.length - 1) ? 0 : idx + 1
        root._setWallpaper(root.wallpapers[idx])
    }

    function previousWallpaper() {
        if (!root.wallpapers.length) return
        var idx = root.wallpapers.indexOf(root.currentWall)
        idx = (idx <= 0) ? root.wallpapers.length - 1 : idx - 1
        root._setWallpaper(root.wallpapers[idx])
    }

    function setWallpaperByIndex(index) {
        if (index >= 0 && index < root.wallpapers.length)
            root._setWallpaper(root.wallpapers[index])
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  CORE: Instant wallpaper change + fire-and-forget side effects
    //
    //  NothingLess pattern:
    //    1. Set currentWall → triggers renderer crossfade (INSTANT)
    //    2. Spawn background processes (matugen, symlink, frame) — non-blocking
    //    3. Config saved after background work finishes
    // ═══════════════════════════════════════════════════════════════════════════

    // Public API — user clicked "Apply" in the popup
    function apply(path, screen) {
        if (root.applying || path === "") return
        root.applying = true

        if (screen !== undefined && screen !== null && screen !== "") {
            var ps = Object.assign({}, root.perScreenWallpapers)
            ps[screen] = path; root.perScreenWallpapers = ps
        }

        // 1. INSTANT: set the wallpaper — crossfade starts immediately
        root.currentWall = path
        root.wallpaperApplied(path)

        // 2. Background: symlink + static frame + matugen + lockscreen
        root._spawnSideEffects(path)

        // 3. Save config
        root.saveConfig()
        root.applying = false
    }

    // Internal — navigation uses this, skips config save
    function _setWallpaper(path) {
        if (path === root.currentWall || path === "") return

        // INSTANT
        root.currentWall = path
        root.wallpaperApplied(path)

        // Background
        root._spawnSideEffects(path)
        root.saveConfig()
    }

    // Fire-and-forget background work
    function _spawnSideEffects(path) {
        // NothingLess approach: use THUMBNAIL as matugen source (fast, already generated)
        // Symlinks for external consumers (lockscreen, etc.)
        // No ffmpeg extraction — thumbnail IS the static frame
        var colorSource = root.getColorSource(path)
        var matugenCfg = decodeURIComponent(Qt.resolvedUrl("../config/matugen.toml").toString().replace("file://", ""))

        // Symlink current wallpaper
        var linkCmd = "ln -sf '" + path + "' ~/.curr_wall 2>/dev/null; " +
                      "ln -sf '" + (colorSource || path) + "' ~/.curr_wall_static.jpg 2>/dev/null"
        _linkProc.command = ["bash", "-c", linkCmd]
        _linkProc.running = false
        _linkProc.running = true

        // Matugen — separate, lighter process (NothingLess style: direct command, no bash pipe)
        var needMatugen = (root._lastMatugenWall !== path || root._lastMatugenScheme !== root.scheme)
        root._lastMatugenWall = path
        root._lastMatugenScheme = root.scheme
        if (needMatugen) {
            var source = colorSource || path
            _matugenWithCfg.command = ["matugen", "image", source, "--source-color-index", "0",
                "-c", matugenCfg, "-t", "scheme-" + root.scheme]
            _matugenWithCfg.running = false
            _matugenWithCfg.running = true

            _matugenPlain.command = ["matugen", "image", source, "--source-color-index", "0",
                "-t", "scheme-" + root.scheme]
            _matugenPlain.running = false
            _matugenPlain.running = true
        }

        // Lockscreen frame (parallel, independent)
        root._generateLockscreenFrame(path)
    }

    // ── Symlink only ─────────────────────────────────────────────────────────
    property Process _linkProc: Process {}

    // ── Matugen with Brain_Shell config ──────────────────────────────────────
    property Process _matugenWithCfg: Process {
        onExited: { root.updateBorders() }
    }

    // ── Matugen plain (updates system-level cache) ───────────────────────────
    property Process _matugenPlain: Process {}

    // ── Lockscreen frame ─────────────────────────────────────────────────────
    function _generateLockscreenFrame(filePath) {
        if (!filePath) return
        var ft = root.getFileType(filePath)
        if (ft !== 'video' && ft !== 'gif') return

        var scriptPath = decodeURIComponent(
            Qt.resolvedUrl("../scripts/lockwall.py").toString().replace("file://", ""))
        _lockwallProc.cmd = ["python3", scriptPath, filePath, root.cacheDir]
        _lockwallProc.proc.running = false
        _lockwallProc.proc.running = true
    }

    property var _lockwallProc: QtObject {
        property var cmd: []
        property Process proc: Process {
            command: _lockwallProc.cmd
            onExited: function(code) {
                if (code === 0) root.lockscreenFrameReady(root.getLockscreenFramePath(root.currentWall))
            }
        }
    }

    // ── Scheme setter ────────────────────────────────────────────────────────
    function setScheme(newScheme) {
        if (root.scheme === newScheme) return
        root.scheme = newScheme
        root.saveConfig()
        if (root.currentWall) root._spawnSideEffects(root.currentWall)
    }

    // ── Per-screen clear ─────────────────────────────────────────────────────
    function clearPerScreenWallpaper(screen) {
        var ps = Object.assign({}, root.perScreenWallpapers)
        delete ps[screen]; root.perScreenWallpapers = ps
        root.saveConfig()
    }

    // ── Border update ────────────────────────────────────────────────────────
    function updateBorders() {
        var primary = String(Theme.active).replace('#', '')
        if (primary === "") return
        var cmd = "hyprctl keyword general:col.active_border \"rgb(" + primary + ")\""
        try {
            if (ShellState && ShellState.configProvider === "lua")
                cmd = "hyprctl eval 'hl.config({ general = { [\"col.active_border\"] = { colors = { \"rgb(" + primary + ")\" } } } })'"
        } catch(e) {}
        _borderProc.command = ["bash", "-c", cmd]
        _borderProc.running = false; _borderProc.running = true
    }
    property Process _borderProc: Process {}

    // ═══════════════════════════════════════════════════════════════════════════
    //  FILE SCANNING & WATCHERS
    // ═══════════════════════════════════════════════════════════════════════════
    function refresh() {
        if (_listProc.running) return
        root.wallpapers = []; root.thumbsReady = false
        _listProc.running = true
        root.scanSubfolders()
    }

    function scanSubfolders() {
        if (!root.wallpaperDir) return
        _scanSubProc.command = [
            "find", root.wallpaperDir, "-mindepth", "1",
            "-name", ".*", "-prune", "-o", "-type", "d", "-print"
        ]
        _scanSubProc.running = false; _scanSubProc.running = true
    }

    property Process _scanSubProc: Process {
        stdout: SplitParser { onRead: function(line) {
            var t = line.trim(); if (!t) return
            var base = root.wallpaperDir; if (!base.endsWith("/")) base += "/"
            var rel = t; if (t.startsWith(base)) rel = t.substring(base.length)
            if (rel.indexOf("/") === -1 && !rel.startsWith(".")) {
                var c = root.allSubdirs.slice()
                if (!c.includes(rel)) { c.push(rel); c.sort(); root.allSubdirs = c }
            }
        }}
        onExited: { root.subfolderFilters = root.allSubdirs.slice() }
    }

    property var _listTemp: []
    property Process _listProc: Process {
        command: ["bash", "-c",
            "find " + root.wallpaperDir + " -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.gif' -o -iname '*.webp' -o -iname '*.tif' -o -iname '*.tiff' " +
            "-o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' " +
            "-o -iname '*.mov' -o -iname '*.avi' \\) | sort"
        ]
        stdout: SplitParser { onRead: function(line) { var t = line.trim(); if (t) _listTemp.push(t) } }
        onExited: {
            var files = _listTemp; _listTemp = []
            if (!files.length) { root._scanFallback(); return }
            root.wallpapers = files
            root.wallpapersRefreshed()
            // Only auto-assign on first load when currentWall is empty
            if (!root.currentWall && files.length) {
                root.currentWall = files[0]
                root.saveConfig()
            }
            root._startThumbGen()
            if (root.currentWall) root._spawnSideEffects(root.currentWall)
        }
    }

    // ── Fallback ─────────────────────────────────────────────────────────────
    property var _fbTemp: []
    function _scanFallback() {
        _fbProc.command = ["bash", "-c",
            "find " + root.fallbackDir + " -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"
        ]
        _fbProc.running = false; _fbProc.running = true
    }
    property Process _fbProc: Process {
        stdout: SplitParser { onRead: function(line) { var t = line.trim(); if (t) _fbTemp.push(t) } }
        onExited: {
            var files = _fbTemp; _fbTemp = []
            root.wallpapers = files; root.wallpapersRefreshed()
            if (files.length && !root.currentWall) {
                root.currentWall = files[0]
                root.saveConfig()
            }
        }
    }

    // ── Watchers ─────────────────────────────────────────────────────────────
    property var _dirWatcher: FileView {
        path: root.wallpaperDir; watchChanges: true; printErrors: false
        onFileChanged: { root.refresh() }
    }
    property var _subWatchers: []
    onAllSubdirsChanged: {
        for (var i = 0; i < root._subWatchers.length; i++)
            if (root._subWatchers[i]) root._subWatchers[i].destroy()
        root._subWatchers = []
        var base = root.wallpaperDir; if (!base.endsWith("/")) base += "/"
        for (var j = 0; j < root.allSubdirs.length; j++) {
            var w = Qt.createQmlObject(
                'import Quickshell; FileView { watchChanges: true; printErrors: false }', root)
            w.path = base + root.allSubdirs[j]
            w.fileChanged.connect(function() { root.refresh() })
            root._subWatchers.push(w)
        }
    }
    onWallpaperDirChanged: { _dirWatcher.path = root.wallpaperDir; root.refresh() }

    // ── Thumbnails (NothingLess approach: proxy dirs, run immediately) ───────
    property Process _thumbGen: Process {
        command: ["python3",
            decodeURIComponent(Qt.resolvedUrl("../scripts/thumbgen_batch.py").toString().replace("file://", "")),
            root.wallpaperDir, "--cache", root.thumbDir, "--size", "256", "--workers", "4", "--quiet"
        ]
        stdout: StdioCollector { onStreamFinished: { if (text.length > 0) console.log("[WallpaperService]", text) } }
        stderr: StdioCollector { onStreamFinished: { if (text.length > 0) console.warn("[WallpaperService]", text) } }
        onExited: {
            root.thumbsReady = true
            root.thumbnailsReady()
        }
    }
    function _startThumbGen() {
        if (_thumbGen.running) return
        _thumbGen.running = true
    }

    // ── Config ───────────────────────────────────────────────────────────────
    property string _cfgBuf: ""
    property Process _readCfg: Process {
        command: ["bash", "-c", "cat '" + root.configPath + "' 2>/dev/null"]
        stdout: SplitParser { onRead: function(line) { root._cfgBuf += line } }
        onExited: {
            if (root._cfgBuf) { try {
                var o = JSON.parse(root._cfgBuf)
                if (o.currentWall  && o.currentWall  !== "") root.currentWall  = o.currentWall
                if (o.wallpaperDir && o.wallpaperDir !== "") root.wallpaperDir = o.wallpaperDir
                if (o.scheme       && o.scheme       !== "") root.scheme       = o.scheme
                if (o.perScreen    && typeof o.perScreen === "object") root.perScreenWallpapers = o.perScreen
            } catch(e) {} }
            root._cfgBuf = ""
            if (!root.currentWall)
                root.currentWall = root.fallbackDir + "/brain-shell-default-0.png"
            root.refresh()
        }
    }

    function saveConfig() {
        var json = JSON.stringify({
            currentWall: root.currentWall, wallpaperDir: root.wallpaperDir,
            scheme: root.scheme, perScreen: root.perScreenWallpapers
        })
        _saveCfg.command = ["bash", "-c",
            "mkdir -p \"$(dirname '" + root.configPath.replace(/'/g, "'\\''") + "')\" && " +
            "printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + root.configPath.replace(/'/g, "'\\''") + "'"
        ]
        _saveCfg.running = false; _saveCfg.running = true
    }
    property Process _saveCfg: Process {}

    Component.onCompleted: { _readCfg.running = true }
}

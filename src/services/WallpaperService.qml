pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// ============================================================
// WallpaperService — wallpaper list + apply pipeline + thumbnail cache
//
// Flow:
//   Component.onCompleted → readConfigProc (sets currentWall etc.)
//                         → refresh() (populates wallpapers list + thumbnails)
//   apply(path, screen)   → sets wallpaper (optionally per-screen)
//                         → saveConfig()
// ============================================================

QtObject {
    id: root

    // ── Config paths ─────────────────────────────────────────────────────────
    readonly property string configPath: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/wallpaper.json"
    readonly property string thumbDir:   Quickshell.env("HOME") + "/.cache/Brain_Shell/thumbnails"

    // ── State ─────────────────────────────────────────────────────────────────
    property var    wallpapers:   []
    property var    tempWalls:    []
    property string currentWall:  ""
    property string previewWall:  ""
    property string scheme:       "content"
    property bool   applying:     false
    property string wallpaperDir: "~/Pictures/Wallpapers"

    // Per-screen wallpapers: { "DP-1": "/path/to/wall.jpg", ... }
    property var perScreenWallpapers: ({})

    // Type filters: [] = show all, ["image","gif","video"] = filtered
    property var activeFilters: []

    // Thumbnail cache: maps original path → thumbnail path
    property var thumbMap: ({})
    property bool thumbsReady: false

    readonly property var schemes: [
        "content", "tonal-spot", "fidelity", "fruit-salad", "neutral", "monochrome",
        "expressive", "rainbow"
    ]

    signal wallpaperApplied(string path)
    signal thumbnailsReady()
    signal wallpapersRefreshed()

    // ── File type detection (ported from NothingLess) ────────────────────────
    function getFileType(path) {
        if (!path) return "unknown"
        var ext = path.toLowerCase().split('.').pop()
        if (['jpg','jpeg','png','webp','tif','tiff','bmp'].includes(ext)) return 'image'
        if (['gif'].includes(ext)) return 'gif'
        if (['mp4','webm','mkv','mov','avi'].includes(ext)) return 'video'
        return 'unknown'
    }

    // ── Filtered wallpapers ──────────────────────────────────────────────────
    readonly property var filteredWallpapers: {
        var all = root.wallpapers
        var filters = root.activeFilters
        if (!filters || filters.length === 0) return all
        var result = []
        for (var i = 0; i < all.length; i++) {
            var ft = root.getFileType(all[i])
            if (filters.includes(ft)) result.push(all[i])
        }
        return result
    }

    // ── Thumbnail helpers ────────────────────────────────────────────────────
    function thumbnailFor(filePath) {
        var t = root.thumbMap[filePath]
        if (t && t !== "") return t
        var ext = filePath.toLowerCase().split('.').pop()
        // Videos need generated thumbnails — can't use original as Image source
        if (['mp4','webm','mkv','mov','avi'].includes(ext)) return ""
        // Static images and GIFs: use original as fallback while thumbs generate
        return filePath
    }

    // ── Toggle filter ────────────────────────────────────────────────────────
    function toggleFilter(type) {
        var copy = root.activeFilters.slice()
        var idx = copy.indexOf(type)
        if (idx >= 0) copy.splice(idx, 1)
        else copy.push(type)
        root.activeFilters = copy
    }

    // ── File listing + refresh ───────────────────────────────────────────────
    function refresh() {
        if (listProc.running) return
        root.tempWalls  = []
        root.thumbsReady = false
        listProc.running = true
    }

    property var listProc: Process {
        command: [
            "bash", "-c",
            "find " + root.wallpaperDir + " -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.gif' -o -iname '*.webp' " +
            "-o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' " +
            "-o -iname '*.mov' -o -iname '*.avi' \\) | sort"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var t = line.trim()
                if (t !== "") root.tempWalls.push(t)
            }
        }
        onExited: function() {
            root.wallpapers = root.tempWalls
            root.wallpapersRefreshed()
            root._startThumbGen()
        }
    }

    // ── Directory watcher — auto-refresh on changes ──────────────────────────
    property var _dirWatcher: FileView {
        path: root.wallpaperDir
        watchChanges: true
        printErrors: false
        onFileChanged: {
            console.log("[WallpaperService] directory changed, refreshing...")
            root.refresh()
        }
    }

    // Re-bind watcher when wallpaperDir changes
    onWallpaperDirChanged: {
        _dirWatcher.path = root.wallpaperDir
        root.refresh()
    }

    // ── Thumbnail batch generation ──────────────────────────────────────────
    property string _thumbBuf: ""
    property var thumbGenProc: Process {
        command: [
            "python3", Quickshell.shellDir + "/src/scripts/thumbgen_batch.py",
            root.wallpaperDir,
            "--cache", root.thumbDir,
            "--size", "400",
            "--workers", "3"
        ]
        stdout: SplitParser {
            onRead: function(line) { root._thumbBuf += line }
        }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    var list = JSON.parse(root._thumbBuf)
                    var map = {}
                    for (var i = 0; i < list.length; i++) {
                        var item = list[i]
                        if (item.thumbnail) map[item.original] = item.thumbnail
                    }
                    root.thumbMap = map
                    root.thumbsReady = true
                    root.thumbnailsReady()
                } catch(e) {
                    console.warn("WallpaperService: thumbnail parse failed", e)
                }
            }
            root._thumbBuf = ""
        }
    }

    function _startThumbGen() {
        root._thumbBuf = ""
        if (thumbGenProc.running) return
        thumbGenProc.running = true
    }

    // ── Config read — runs on startup, then calls refresh() ──────────────────
    property string _cfgBuf: ""
    property var readConfigProc: Process {
        command: ["bash", "-c", "cat '" + root.configPath + "' 2>/dev/null"]
        stdout: SplitParser {
            onRead: function(line) { root._cfgBuf += line }
        }
        onExited: function() {
            if (root._cfgBuf !== "") {
                try {
                    var obj = JSON.parse(root._cfgBuf)
                    if (obj.currentWall  && obj.currentWall  !== "") root.currentWall  = obj.currentWall
                    if (obj.wallpaperDir && obj.wallpaperDir !== "") root.wallpaperDir = obj.wallpaperDir
                    if (obj.scheme       && obj.scheme       !== "") root.scheme       = obj.scheme
                    if (obj.perScreen    && typeof obj.perScreen === "object") root.perScreenWallpapers = obj.perScreen
                } catch(e) {}
            }
            if (root.currentWall === "") {
                var defaultWall = Quickshell.shellDir + "/src/assets/wallpapers/brain-shell-default-0.png"
                root.apply(defaultWall)
            }
            root.refresh()
        }
    }

    // ── Config write — called after a successful apply ────────────────────────
    function saveConfig() {
        var json = JSON.stringify({
            currentWall:  root.currentWall,
            wallpaperDir: root.wallpaperDir,
            scheme:       root.scheme,
            perScreen:    root.perScreenWallpapers
        })
        saveConfigProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + root.configPath + "')\" && " +
            "printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + root.configPath + "'"
        ]
        saveConfigProc.running = true
    }

    property var saveConfigProc: Process {}

    // ── Apply pipeline — supports per-screen via optional screen param ────────
    function apply(path, screen) {
        if (root.applying || path === "") return
        root.applying = true

        // Per-screen: store in map, but also update currentWall for the renderer
        if (screen !== undefined && screen !== null && screen !== "") {
            var ps = Object.assign({}, root.perScreenWallpapers)
            ps[screen] = path
            root.perScreenWallpapers = ps
        }
        root.currentWall = path

        applyProc.command = [
            "bash", "-c",
            // Symlink current wallpaper for external consumers (lockscreen, etc.)
            "ln -sf \"" + path + "\" ~/.curr_wall " +
            // Generate static frame for matugen (videos/GIFs need a still image)
            "&& (" +
            "  if [[ \"" + path + "\" == *.gif ]] || [[ \"" + path + "\" == *.mp4 ]] || [[ \"" + path + "\" == *.webm ]] || [[ \"" + path + "\" == *.mkv ]] || [[ \"" + path + "\" == *.mov ]] || [[ \"" + path + "\" == *.avi ]]; then " +
            "    rm -f ~/.curr_wall_static.jpg; " +
            "    FRAME_OK=false; " +
            // Try ffmpeg first (fast, reliable for videos)
            "    if command -v ffmpeg >/dev/null 2>&1; then " +
            "      ffmpeg -y -i \"" + path + "\" -vframes 1 -q:v 3 ~/.curr_wall_static.jpg 2>/dev/null && FRAME_OK=true; " +
            "    fi; " +
            // Try magick (ImageMagick v7) or convert (v6) for GIFs
            "    if [ \"$FRAME_OK\" != \"true\" ]; then " +
            "      if command -v magick >/dev/null 2>&1; then " +
            "        magick \"" + path + "[0]\" ~/.curr_wall_static.jpg 2>/dev/null && FRAME_OK=true; " +
            "      elif command -v convert >/dev/null 2>&1; then " +
            "        convert \"" + path + "[0]\" ~/.curr_wall_static.jpg 2>/dev/null && FRAME_OK=true; " +
            "      fi; " +
            "    fi; " +
            // Fallback: use thumbnail if frame extraction failed
            "    if [ \"$FRAME_OK\" != \"true\" ] && [ -f \"" + root.thumbDir + "/\"*.jpg ]; then " +
            "      cp \"$(ls -t " + root.thumbDir + "/*.jpg 2>/dev/null | head -1)\" ~/.curr_wall_static.jpg 2>/dev/null || true; " +
            "    fi; " +
            "    true; " +  // never fail the chain
            "  else " +
            "    ln -sf \"" + path + "\" ~/.curr_wall_static.jpg; " +
            "  fi; " +
            ") " +
            // Run matugen on the static frame to extract Material You colors
            "&& if [ -f ~/.curr_wall_static.jpg ]; then " +
            "  matugen image \"$(readlink -f ~/.curr_wall_static.jpg)\" " +
            "    -c \"" + Quickshell.shellDir + "/src/config/matugen.toml\" " +
            "    --source-color-index 0 --type scheme-" + root.scheme + " " +
            "    2>/dev/null || true; " +
            "fi " +
            // Also run without config to update system-level matugen cache
            "&& if [ -f ~/.curr_wall_static.jpg ]; then " +
            "  matugen image \"$(readlink -f ~/.curr_wall_static.jpg)\" " +
            "    --source-color-index 0 --type scheme-" + root.scheme + " " +
            "    2>/dev/null || true; " +
            "fi"
        ]
        applyProc.running = true
    }

    // ── Clear per-screen wallpaper ───────────────────────────────────────────
    function clearPerScreenWallpaper(screen) {
        var ps = Object.assign({}, root.perScreenWallpapers)
        delete ps[screen]
        root.perScreenWallpapers = ps
        root.saveConfig()
    }

    // ── Set matugen scheme ───────────────────────────────────────────────────
    function setScheme(newScheme) {
        if (root.scheme === newScheme) return
        root.scheme = newScheme
        if (root.currentWall) root.apply(root.currentWall)
    }
    
    property Process applyProc: Process {
        onExited: function(exitCode, exitStatus) {
            root.applying = false
            if (exitCode === 0) {
                root.wallpaperApplied(root.currentWall)
                root.saveConfig()

                // Trigger border update after wallpaper application finishes
                updateBorders()
            }
        }
    }

    // New function to update borders based on config provider
    function updateBorders() {
        // Strip '#' from the colors (assuming QML hex format #RRGGBB)
        let primary = String(Theme.active).replace('#', '')
        

        // Build command based on config provider
        if (ShellState.configProvider === "lua") {
            // Using hl.config with RGB strings in Lua
            borderUpdateProc.command = [
                "bash", "-c",
                "hyprctl eval 'hl.config({ general = { [\"col.active_border\"] = { colors = { \"rgb(" + primary + ")\" } } } })'"
            ]
        } else {
            // Using hyprctl keyword for .conf
            borderUpdateProc.command = [
                "bash", "-c",
                "hyprctl keyword general:col.active_border \"rgb(" + primary + ")\""
            ]
        }
        
        borderUpdateProc.running = true
    }

    property Process borderUpdateProc: Process {
        command: []
    }

    Component.onCompleted: {
        readConfigProc.running = true
        if (Theme.active && String(Theme.active).trim() !== "") {
            updateBorders()
        }
    }
}

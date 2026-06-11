pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

/*!
    VideoWallpaperService — hardware-accelerated video wallpaper optimizer.
    Ported from NothingLess. Handles:

    - GPU-aware FFmpeg downscaling (4K → 1080p/720p)
    - Cached low-res versions (~/.cache/Brain_Shell/video-cache/)
    - Frame skipping to target FPS
    - Multi-screen dedup (same cache for same video)
    - Pause/resume on screen lock (via IdleService)
*/
QtObject {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/Brain_Shell/video-cache"

    // Target FPS for video wallpapers (lower = less GPU)
    property int targetFps: {
        if (GpuDetector.hasHardwareDecoder) return 24
        return 15
    }

    // Max resolution height (0 = native, no downscale)
    property int targetHeight: 1080

    // ── Video detection ───────────────────────────────────────────────────────
    function isVideo(path) {
        if (!path) return false;
        return /\.(mp4|webm|mkv|mov|avi|gif)$/i.test(path);
    }

    // ── HW encoder per GPU ────────────────────────────────────────────────────
    readonly property string hwEncoder: {
        if (GpuDetector.isIntel)  return "h264_qsv";
        if (GpuDetector.isAmd)    return "h264_vaapi";
        if (GpuDetector.isNvidia) return "h264_nvenc";
        return "";
    }

    readonly property string hwScaleFilter: {
        if (GpuDetector.isIntel)  return "scale_qsv";
        if (GpuDetector.isAmd)    return "scale_vaapi";
        if (GpuDetector.isNvidia) return "scale_cuda";
        return "scale";
    }

    // ── File hash for cache names ─────────────────────────────────────────────
    function _hashPath(path) {
        var hash = 5381;
        for (var i = 0; i < path.length; i++) {
            hash = ((hash << 5) + hash) + path.charCodeAt(i);
            hash = hash & hash;
        }
        return Math.abs(hash).toString(16);
    }

    function getCachePath(originalPath) {
        if (!originalPath || targetHeight === 0) return originalPath;
        if (!isVideo(originalPath)) return originalPath;

        var ext = originalPath.toLowerCase().split(".").pop();
        var hash = _hashPath(originalPath);
        return cacheDir + "/" + hash + "-" + targetHeight + "p." + ext;
    }

    // ── Get effective path (cached if exists, else original) ──────────────────
    function getEffectivePath(originalPath, callback) {
        if (!isVideo(originalPath) || targetHeight === 0) {
            if (callback) callback(originalPath);
            return;
        }

        var cachePath = getCachePath(originalPath);

        // Queue callback for multi-screen support
        root._checkCallbacks.push({ path: cachePath, cb: callback, original: originalPath });

        if (checkProc.running) return;
        root._startCheckProcess();
    }

    function _startCheckProcess() {
        if (root._checkCallbacks.length === 0) return;
        var req = root._checkCallbacks[0];
        root._checkingPath = req.path;
        root._checkingOriginal = req.original;

        checkProc.command = ["test", "-f", req.path];
        checkProc.running = false;
        checkProc.running = true;
    }

    property Process checkProc: Process {
        running: false
        onExited: function(code) {
            var cachePath = root._checkingPath;
            var originalPath = root._checkingOriginal;
            var exists = code === 0;

            // Notify all callbacks waiting for this path
            var remaining = [];
            for (var i = 0; i < root._checkCallbacks.length; i++) {
                var item = root._checkCallbacks[i];
                if (item.path === cachePath) {
                    if (exists) {
                        if (item.cb) item.cb(cachePath);
                    } else {
                        // Not cached — generate it
                        root._generateCache(originalPath, cachePath, item.cb);
                    }
                } else {
                    remaining.push(item);
                }
            }
            root._checkCallbacks = remaining;
            root._checkingPath = "";
            root._checkingOriginal = "";

            // Process next queued path
            if (remaining.length > 0) {
                root._startCheckProcess();
            }
        }
    }

    property var _checkCallbacks: []
    property string _checkingPath: ""
    property string _checkingOriginal: ""

    // ── Generate cached downscaled version ────────────────────────────────────
    function _generateCache(originalPath, cachePath, callback) {
        // If already generating this cache, queue callback
        if (genProc.running && root._generatingPath === cachePath) {
            root._genCallbacks.push(callback);
            return;
        }

        // Ensure cache dir exists
        mkdirProc.running = false;
        mkdirProc.running = true;

        var cmd = "ffmpeg -y -i '" + originalPath + "'";

        // FPS filter
        cmd += " -filter:v fps=" + targetFps;

        // Downscale if targetHeight > 0
        if (targetHeight > 0) {
            cmd += ",scale=-2:" + targetHeight + ":flags=lanczos";
        }

        // Hardware encoder if available
        if (GpuDetector.hasHardwareDecoder && hwEncoder !== "") {
            cmd += " -c:v " + hwEncoder + " -preset fast -b:v 2M";
        } else {
            cmd += " -c:v libx264 -preset ultrafast -crf 28";
        }

        cmd += " -an -movflags +faststart '" + cachePath + "' 2>/dev/null";

        root._generatingPath = cachePath;
        root._genCallbacks = callback ? [callback] : [];

        genProc.command = ["bash", "-c", cmd];
        genProc.running = false;
        genProc.running = true;
    }

    property Process genProc: Process {
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            var success = code === 0;
            var cachePath = root._generatingPath;

            if (!success) {
                console.warn("[VideoWallpaperService] cache generation failed (exit", code + ")");
            } else {
                console.log("[VideoWallpaperService] cached →", cachePath);
            }

            var cbs = root._genCallbacks;
            root._genCallbacks = [];
            root._generatingPath = "";

            for (var i = 0; i < cbs.length; i++) {
                if (cbs[i]) cbs[i](success ? cachePath : root._checkingOriginal);
            }
        }
    }

    property var _genCallbacks: []
    property string _generatingPath: ""

    property Process mkdirProc: Process {
        command: ["mkdir", "-p", root.cacheDir]
        running: false
    }

    // ── Clear cache ───────────────────────────────────────────────────────────
    function clearCache() {
        clearProc.running = false;
        clearProc.running = true;
    }

    property Process clearProc: Process {
        command: ["bash", "-c", "rm -rf '" + root.cacheDir + "'/* 2>/dev/null; true"]
        running: false
    }

    // ── Optimize query ────────────────────────────────────────────────────────
    function optimize(wallpaperPath) {
        return {
            fps: root.targetFps,
            useHardware: GpuDetector.hasHardwareDecoder,
            isVideo: isVideo(wallpaperPath)
        };
    }

    Component.onDestruction: {
        if (genProc.running !== undefined) genProc.running = false;
    }
}

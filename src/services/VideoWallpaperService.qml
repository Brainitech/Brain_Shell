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

        var hash = _hashPath(originalPath);
        // Always output H.264 MP4 — ensures hardware decode on all GPUs.
        // VP9/WebM would fall back to CPU decode on Intel (no VAAPI VP9).
        return cacheDir + "/" + hash + "-" + targetHeight + "p.mp4";
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

    // ── Generate cached H.264 MP4 version (hardware-decodable on all GPUs) ───
    function _generateCache(originalPath, cachePath, callback) {
        if (genProc.running && root._generatingPath === cachePath) {
            root._genCallbacks.push(callback);
            return;
        }

        mkdirProc.running = false;
        mkdirProc.running = true;

        // Detect source codec to decide if transcoding is needed
        var srcCodec = GpuDetector.detectCodecFromPath(originalPath);
        var needsTranscode = (srcCodec !== "h264");

        // Always transcode non-H.264 (VP9, AV1, etc.) to H.264 for hardware decode.
        // If source is already H.264 and at target resolution, skip — no re-encode needed.
        if (!needsTranscode && targetHeight === 0) {
            // Already H.264, no downscale — use original directly
            if (callback) callback(originalPath);
            return;
        }

        // Software decode for transcode — VAAPI/Vulkan don't support VP9 on Intel.
        // Using -hwaccel none avoids the 'Failed setup for format vaapi/vulkan' spam.
        // The OUTPUT is H.264 which DOES have QSV hardware decode during playback.
        var cmd = "ffmpeg -y -loglevel error -hwaccel none -i '" + originalPath + "'";

        // FPS limit + optional downscale
        cmd += " -filter:v fps=" + targetFps;
        if (targetHeight > 0) {
            cmd += ",scale=-2:" + targetHeight + ":flags=lanczos";
        }
        // Force pixel format for hardware encoder compatibility
        cmd += ",format=yuv420p";

        // Hardware encoder if available (Intel QSV, AMD VAAPI, NVIDIA NVENC)
        if (GpuDetector.hasHardwareDecoder && hwEncoder !== "") {
            cmd += " -c:v " + hwEncoder + " -preset fast -b:v 2M -maxrate 4M -bufsize 4M";
        } else {
            cmd += " -c:v libx264 -preset veryfast -crf 26";
        }

        cmd += " -an -movflags +faststart '" + cachePath + "'";

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

    // Check if source needs transcoding for hardware decode
    function needsTranscode(path) {
        if (!isVideo(path)) return false;
        return GpuDetector.detectCodecFromPath(path) !== "h264";
    }

    Component.onDestruction: {
        if (genProc.running !== undefined) genProc.running = false;
    }
}

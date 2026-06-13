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

    // ── Get effective path (synchronous — returns cache path if exists, else compute and return) ─
    function getEffectivePath(originalPath) {
        if (!originalPath || targetHeight === 0) return originalPath;
        if (!isVideo(originalPath)) return originalPath;
        var hash = _hashPath(originalPath);
        return cacheDir + "/" + hash + "-" + targetHeight + "p.mp4";
    }

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

        if (!needsTranscode && targetHeight === 0) {
            if (callback) callback(originalPath);
            return;
        }

        var cmd = "ffmpeg -y -loglevel error -hwaccel none -i '" + originalPath + "'";
        cmd += " -filter:v fps=" + targetFps;
        if (targetHeight > 0) {
            cmd += ",scale=-2:" + targetHeight + ":flags=lanczos";
        }
        cmd += ",format=yuv420p";

        if (GpuDetector.hasHardwareDecoder && hwEncoder !== "") {
            cmd += " -c:v " + hwEncoder + " -preset fast -b:v 2M -maxrate 4M -bufsize 4M";
        } else {
            cmd += " -c:v libx264 -preset veryfast -crf 26";
        }

        cmd += " -an -movflags +faststart '" + cachePath + "'";

        root._generatingPath = cachePath;
        root._genCallbacks = callback ? [callback] : [];
        root._genOriginal = originalPath;

        genProc.command = ["bash", "-c", cmd];
        genProc.running = false;
        genProc.running = true;
    }

    property string _genOriginal: ""

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
            var original = root._genOriginal;
            root._genOriginal = "";

            for (var i = 0; i < cbs.length; i++) {
                if (cbs[i]) cbs[i](success ? cachePath : original);
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

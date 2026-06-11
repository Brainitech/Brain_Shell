pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/*!
    GpuDetector.qml — GPU vendor detection singleton.

    Detects GPU vendor synchronously at initialization time so that
    VideoWallpaperService and other consumers can rely on the vendor
    being already detected when they first query it.

    Ported from NothingLess.
*/
QtObject {
    id: root

    // Synchronous vendor detection. Set during component initialization.
    property string vendor: "unknown"

    readonly property bool hasHardwareDecoder: root.vendor !== "unknown" && root.vendor !== ""
    readonly property bool isNvidia: root.vendor === "nvidia"
    readonly property bool isAmd:    root.vendor === "amd"
    readonly property bool isIntel:  root.vendor === "intel"

    // Run detection at component creation time
    Component.onCompleted: {
        // Use Process instead of XMLHttpRequest (blocked in Qt 6)
        // The async bash fallback reads all card*/device/vendor files
        gpuDetect.running = true
    }

    // GPU vendor detection via /sys/class/drm
    property Process gpuDetect: Process {
        command: ["bash", "-c",
            "v=$(for f in /sys/class/drm/card*/device/vendor; do cat \"$f\" 2>/dev/null && break; done); " +
            "case $v in " +
            "  0x10de) echo nvidia;; " +
            "  0x1002) echo amd;; " +
            "  0x8086) echo intel;; " +
            "  *) echo unknown;; " +
            "esac"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var result = String(text).trim()
                if (result && result.length > 0) {
                    root.vendor = result
                    console.log("[GpuDetector] vendor:", result)
                }
            }
        }
    }

    function getBestDecoder(codec) {
        var c = codec || "h264"
        switch (root.vendor) {
        case "nvidia":
            return { hardware: true, decoder: c+"_cuvid", encoder: c+"_nvenc", device: "cuda", maxThreads: 2 }
        case "amd":
            return { hardware: true, decoder: c+"_vaapi", encoder: c+"_amf", device: "vaapi", maxThreads: 2 }
        case "intel":
            return { hardware: true, decoder: c+"_qsv", encoder: c+"_qsv", device: "qsv", maxThreads: 2 }
        default:
            return { hardware: false, decoder: c, encoder: null, device: "cpu", maxThreads: 4 }
        }
    }

    function detectCodecFromPath(path) {
        var ext = String(path).toLowerCase().split(".").pop()
        switch (ext) {
        case "mp4": case "mov": case "avi": return "h264"
        case "webm": case "mkv": return "vp9"
        default: return "h264"
        }
    }
}

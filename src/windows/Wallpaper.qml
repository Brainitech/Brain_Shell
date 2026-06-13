import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../"

/*!
    Wallpaper.qml — native wallpaper renderer (replaces awww).
    Renders static images via Image, videos via Video, animated GIFs via
    AnimatedImage (QtMultimedia Video does not reliably play gifs).
    Sits at WlrLayer.Background — behind all shell windows but above
    the compositor's blank root color.

    Performance features:
    - Uses VideoWallpaperService for downscaled/cached video paths
    - Pauses video when user is idle (>30s) to save GPU/CPU
    - sourceSize hints for Image to reduce decode cost

    Advanced rendering (ported from NothingLess, OFF by default so the original
    Brain_Shell look is preserved unless the user opts in via ShellState):
    - Palette tinting  (palette.frag.qsb)  → ShellState.wallpaperTint
    - Motion interpolation (interpol.frag.qsb) → ShellState.wallpaperInterpolation
*/
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "brain-shell:wallpaper"
    exclusionMode: ExclusionMode.Ignore

    // Fallback — matugen/material dark surface, never pure black
    color: Theme.background

    // ── Driven by WallpaperService singleton ──────────────────────────────────
    readonly property string currentPath: WallpaperService.currentWall || ""

    // ── Display path — updated AFTER snapshot is taken, so the old content
    //     is still rendered when we freeze the crossfade overlay.
    property string _displayPath: ""

    // Effective video path (may be downscaled cache)
    property string _effectivePath: ""
    property bool _waitingForCache: false

    function getFileType(p) {
        var ext = p.toLowerCase().split('.').pop()
        if (['jpg','jpeg','png','webp','tif','tiff','bmp'].includes(ext)) return 'image'
        if (ext === 'gif') return 'gif'
        if (['mp4','webm','mkv','mov','avi'].includes(ext)) return 'video'
        return 'unknown'
    }

    readonly property string _ftype:  getFileType(_displayPath)
    readonly property bool isImage:   _ftype === 'image'
    readonly property bool isGif:     _ftype === 'gif'
    readonly property bool isVideo:   _ftype === 'video'
    readonly property string sourceUrl: _displayPath ? "file://" + _displayPath : ""

    // Pause video when user has been idle for >30 seconds (saves GPU/CPU)
    readonly property bool videoPaused: IdleService.idleTime > 30000

    // ── Advanced rendering toggles (opt-in) ───────────────────────────────────
    readonly property bool tintEnabled:          ShellState.wallpaperTint
    readonly property bool interpolationEnabled:  ShellState.wallpaperInterpolation
    readonly property int  interpolationMultiplier: ShellState.interpolationMultiplier

    // Pause/resume video based on idle state
    onVideoPausedChanged: {
        if (!videoPlayer) return
        if (videoPaused && videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.pause()
        } else if (!videoPaused && isVideo && videoPlayer.playbackState !== MediaPlayer.PlayingState) {
            // Resume from pause or restart if stopped at end
            if (videoPlayer.playbackState === MediaPlayer.PausedState
                || videoPlayer.playbackState === MediaPlayer.StoppedState) {
                videoPlayer.play()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  PALETTE TEXTURE (built from matugen colors → used by palette tint shader)
    // ═══════════════════════════════════════════════════════════════════════════
    readonly property var _palette: [
        Colors.background, Colors.active, Colors.text,
        Colors.subtext, Colors.icon, Colors.border, Colors.iconFont
    ]
    readonly property int effectivePaletteSize: _palette.length

    Canvas {
        id: paletteCanvas
        width: root.effectivePaletteSize
        height: 1
        visible: false
        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return
            ctx.clearRect(0, 0, width, height)
            for (var i = 0; i < root._palette.length; i++) {
                ctx.fillStyle = String(root._palette[i])
                ctx.fillRect(i, 0, 1, 1)
            }
        }
        Component.onCompleted: requestPaint()
        Connections {
            target: Colors
            function onActiveChanged()     { Qt.callLater(paletteCanvas.requestPaint) }
            function onBackgroundChanged()  { Qt.callLater(paletteCanvas.requestPaint) }
        }
    }

    ShaderEffectSource {
        id: paletteTextureSource
        sourceItem: paletteCanvas
        live: false
        hideSource: true
        visible: false
        smooth: false
        recursive: false
        Connections {
            target: paletteCanvas
            function onPainted() { paletteTextureSource.scheduleUpdate() }
        }
    }

    // ── Wallpaper change: snapshot crossfade ──────────────────────────────────
    // Takes a snapshot of the old wallpaper, swaps to the new one underneath,
    // then crossfades the snapshot out for a smooth seamless transition.
    // Works with all media types: static images, GIFs, and videos.
    property string _lastPath: ""
    property bool _crossfading: false
    property bool _newContentReady: false

    // Snapshot of the old wallpaper content — frozen and crossfaded out
    ShaderEffectSource {
        id: crossfadeSnapshot
        sourceItem: contentContainer
        live: false
        visible: false
        smooth: true
        anchors.fill: parent
        z: 5
        opacity: 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutCubic
            }
        }

        onOpacityChanged: {
            if (opacity <= 0.01) {
                visible = false
                sourceItem = null
            }
        }
    }

    // ── Content-ready tracking per media type ────────────────────────────────
    property string _expectedPath: ""

    function _checkContentReady() {
        if (!_crossfading || _expectedPath === "") return
        var ftype = getFileType(_expectedPath)
        var ready = false
        if (ftype === "image") {
            ready = staticImg.status === Image.Ready
        } else if (ftype === "gif") {
            ready = gifPlayer.status === AnimatedImage.Ready
        } else if (ftype === "video") {
            ready = videoPlayer.playbackState === MediaPlayer.PlayingState
                 || videoPlayer.status === MediaPlayer.Loaded
        }
        if (ready) {
            _newContentReady = true
            _tryStartCrossfade()
        }
    }

    Connections {
        target: staticImg
        function onStatusChanged() { if (_crossfading) _checkContentReady() }
    }
    Connections {
        target: gifPlayer
        function onStatusChanged() { if (_crossfading) _checkContentReady() }
    }
    Connections {
        target: videoPlayer
        function onStatusChanged() { if (_crossfading) _checkContentReady() }
        function onPlaybackStateChanged() { if (_crossfading) _checkContentReady() }
    }

    // Safety timer — if content takes too long, crossfade anyway
    Timer {
        id: crossfadeTimeout
        interval: 1200
        repeat: false
        onTriggered: {
            if (_crossfading) {
                _newContentReady = true
                _tryStartCrossfade()
            }
        }
    }

    // Frame-delay timer — ensures snapshot renders before swapping underneath
    Timer {
        id: frameDelay
        interval: 50
        repeat: false
        property string pendingPath: ""
        onTriggered: {
            if (pendingPath !== "") {
                _performSwap(pendingPath)
                pendingPath = ""
            }
        }
    }

    function _tryStartCrossfade() {
        if (!_crossfading || !_newContentReady) return
        crossfadeSnapshot.opacity = 0
        crossfadeTimeout.stop()
    }

    onCurrentPathChanged: {
        if (currentPath === _lastPath) return
        if (currentPath === "") return
        if (_crossfading) {
            _lastPath = currentPath
            return
        }

        var prevPath = _lastPath
        _lastPath = currentPath

        if (prevPath !== "" && contentContainer.visible) {
            // 1. Freeze old wallpaper as snapshot
            crossfadeSnapshot.sourceItem = contentContainer
            crossfadeSnapshot.scheduleUpdate()
            crossfadeSnapshot.visible = true
            crossfadeSnapshot.opacity = 1.0

            // Wait 50ms (2-3 frames) for snapshot to render, then swap
            frameDelay.pendingPath = currentPath
            frameDelay.restart()
        } else {
            // First wallpaper load — no crossfade needed
            _performSwap(currentPath)
        }
    }

    function _performSwap(newPath) {
        _crossfading = true
        _newContentReady = false
        _expectedPath = newPath
        _displayPath = newPath

        // Reset stale media state from previous wallpaper type
        _resetMediaState()

        // Resolve video cache path if needed
        var ftype = getFileType(newPath)
        if (ftype === "video" && VideoWallpaperService) {
            root._waitingForCache = true
            VideoWallpaperService.getEffectivePath(newPath, function(path) {
                root._effectivePath = path || newPath
                root._waitingForCache = false
                _checkContentReady()
            })
        } else {
            root._effectivePath = newPath
            root._waitingForCache = false
        }

        // Wait for new content to be ready, then crossfade
        crossfadeTimeout.interval = (ftype === "video") ? 2500 : 1000
        crossfadeTimeout.restart()

        // Delayed check — give Qt time to start loading the new source
        Qt.callLater(function() {
            if (_crossfading) _checkContentReady()
        })

        // Clean up crossfade state after animation
        cleanupTimer.restart()
    }

    // Reset media elements to avoid stale Ready/Loaded states from previous
    // wallpaper type bleeding into the content-ready checks.
    function _resetMediaState() {
        if (!isImage && staticImg.source !== "") staticImg.source = ""
        if (!isGif && gifPlayer.source !== "") gifPlayer.source = ""
        if (!isVideo && videoPlayer.source !== "") {
            videoPlayer.stop()
            videoPlayer.source = ""
        }
    }

    Timer {
        id: cleanupTimer
        interval: 600
        repeat: false
        onTriggered: _crossfading = false
    }

    Component.onCompleted: {
        if (currentPath !== "") {
            _displayPath = currentPath
            _lastPath = currentPath
            _expectedPath = currentPath
            var ftype = getFileType(currentPath)
            if (ftype === "video" && VideoWallpaperService) {
                root._waitingForCache = true
                VideoWallpaperService.getEffectivePath(currentPath, function(path) {
                    root._effectivePath = path || currentPath
                    root._waitingForCache = false
                })
            } else {
                root._effectivePath = currentPath
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  CONTENT CONTAINER — all wallpaper media lives here so we can snapshot it
    // ═══════════════════════════════════════════════════════════════════════════
    Item {
        id: contentContainer
        anchors.fill: parent

    // ═══════════════════════════════════════════════════════════════════════════
    //  STATIC IMAGE
    // ═══════════════════════════════════════════════════════════════════════════
    Image {
        id: staticImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        cache: false
        source: isImage ? sourceUrl : ""
        visible: status === Image.Ready && isImage

        // Limit decode resolution — screen size is typically < 4K
        sourceSize.width:  3840
        sourceSize.height: 2160

        // Optional palette tint (OFF by default → identical to original)
        layer.enabled: root.tintEnabled && root.effectivePaletteSize > 0 && isImage
        layer.smooth: true
        layer.effect: ShaderEffect {
            property var paletteTexture: paletteTextureSource
            property int paletteSize: root.effectivePaletteSize
            property real sharpness: 20.0
            property real mixStrength: 1.0
            property real texWidth: staticImg.width
            property real texHeight: staticImg.height
            vertexShader:   "../config/shaders/video/palette.vert.qsb"
            fragmentShader: "../config/shaders/video/palette.frag.qsb"
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            visible: staticImg.status !== Image.Ready && isImage
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  ANIMATED GIF
    // ═══════════════════════════════════════════════════════════════════════════
    AnimatedImage {
        id: gifPlayer
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        source: isGif ? sourceUrl : ""
        playing: isGif && !videoPaused
        visible: isGif && status === AnimatedImage.Ready

        layer.enabled: root.tintEnabled && root.effectivePaletteSize > 0 && isGif
        layer.smooth: true
        layer.effect: ShaderEffect {
            property var paletteTexture: paletteTextureSource
            property int paletteSize: root.effectivePaletteSize
            property real sharpness: 20.0
            property real mixStrength: 1.0
            property real texWidth: gifPlayer.width
            property real texHeight: gifPlayer.height
            vertexShader:   "../config/shaders/video/palette.vert.qsb"
            fragmentShader: "../config/shaders/video/palette.frag.qsb"
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  VIDEO  (+ optional motion interpolation + palette tint)
    // ═══════════════════════════════════════════════════════════════════════════
    Item {
        id: videoRoot
        anchors.fill: parent
        visible: isVideo

        property bool interpolate: root.interpolationEnabled
        property int  multiplier:  root.interpolationMultiplier
        property real targetInputFps: 24.0
        property real originalFps: 30
        property real effectiveInputFps: Math.min(originalFps, targetInputFps)
        property real captureIntervalMs: 1000 / effectiveInputFps
        property real lastCaptureTime: 0
        property real blendFactor: 0.0
        property bool isOriginalFrame: true
        property int  frameCounter: 0

        onInterpolateChanged: {
            if (interpolate) {
                captureTimer.restart()
                frameAnimation.running = true
                previousFrameSource.scheduleUpdate()
                videoRoot.lastCaptureTime = Date.now()
            } else {
                captureTimer.stop()
                frameAnimation.running = false
            }
        }

        Video {
            id: videoPlayer
            anchors.fill: parent
            source: {
                if (!isVideo) return ""
                // While waiting for cache, try the original path so the video
                // starts loading immediately. It will switch to the cached
                // (optimised) version once _effectivePath is set.
                var p = root._effectivePath
                if (!p && !root._waitingForCache) {
                    // Not waiting for cache — use original directly if no
                    // transcoding is needed, otherwise wait for cache
                    p = (VideoWallpaperService && VideoWallpaperService.needsTranscode(root.currentPath)) ? "" : root.currentPath
                }
                if (!p) p = root.currentPath  // fallback to original
                return p ? "file://" + p : ""
            }
            loops: MediaPlayer.Infinite
            autoPlay: true
            muted: true
            fillMode: VideoOutput.PreserveAspectCrop
            // When interpolating, the shader draws the frames instead.
            visible: !videoRoot.interpolate || videoRoot.multiplier <= 1

            onSourceChanged: {
                if (source && source.toString() && VideoWallpaperService) {
                    var opt = VideoWallpaperService.optimize(String(source).replace("file://", ""))
                    if (opt && opt.isVideo && opt.fps && opt.fps < videoRoot.targetInputFps)
                        videoRoot.targetInputFps = opt.fps
                }
            }
            onMetaDataChanged: {
                if (metaData.frameRate && metaData.frameRate > 0) {
                    videoRoot.originalFps = metaData.frameRate
                    videoRoot.effectiveInputFps = Math.min(videoRoot.originalFps, videoRoot.targetInputFps)
                    videoRoot.captureIntervalMs = 1000 / videoRoot.effectiveInputFps
                }
            }
            onPlaybackStateChanged: {
                if (playbackState === MediaPlayer.PlayingState && videoRoot.interpolate) {
                    captureTimer.restart()
                    frameAnimation.running = true
                    previousFrameSource.scheduleUpdate()
                    videoRoot.lastCaptureTime = Date.now()
                } else if (playbackState !== MediaPlayer.PlayingState) {
                    captureTimer.stop()
                    frameAnimation.running = false
                }
            }
        }

        // Live capture of current frame (only when interpolating)
        ShaderEffectSource {
            id: liveSource
            sourceItem: videoRoot.interpolate ? videoPlayer : null
            live: videoRoot.interpolate
            hideSource: true
            smooth: true
            visible: false
        }
        // Buffer of previous frame, updated at target input FPS
        ShaderEffectSource {
            id: previousFrameSource
            sourceItem: videoRoot.interpolate ? videoPlayer : null
            live: false
            hideSource: true
            smooth: true
            visible: false
        }

        Timer {
            id: captureTimer
            interval: videoRoot.captureIntervalMs
            repeat: true
            running: false
            onTriggered: {
                if (!videoRoot.interpolate) return
                previousFrameSource.scheduleUpdate()
                videoRoot.lastCaptureTime = Date.now()
                videoRoot.isOriginalFrame = true
            }
        }

        FrameAnimation {
            id: frameAnimation
            running: false
            onTriggered: {
                if (!videoRoot.interpolate || videoRoot.multiplier <= 1) return
                if (videoPlayer.playbackState !== MediaPlayer.PlayingState) return
                var now = Date.now()
                var elapsed = now - videoRoot.lastCaptureTime
                var factor = elapsed / videoRoot.captureIntervalMs
                videoRoot.blendFactor = Math.min(1.0, factor)
                videoRoot.isOriginalFrame = (videoRoot.blendFactor < 0.01 || videoRoot.blendFactor > 0.99)
                videoRoot.frameCounter++
            }
        }

        // Interpolation shader — only loaded when feature is enabled
        // Avoids shader loading warnings when .qsb files are not compiled
        Loader {
            id: interpolationLoader
            anchors.fill: parent
            active: videoRoot.interpolate && videoRoot.multiplier > 1
            sourceComponent: Component {
                ShaderEffect {
                    anchors.fill: parent
                    property var currentFrame: liveSource
                    property var previousFrame: previousFrameSource
                    property real blendFactor: videoRoot.blendFactor
                    property vector2d iResolution: Qt.vector2d(width, height)
                    property int blockSize: 12
                    property int searchRadius: 3
                    property real motionThreshold: 0.05
                    property int debugMode: 0
                    property int isOriginalFrame: videoRoot.isOriginalFrame ? 1 : 0
                    property int frameCounter: videoRoot.frameCounter
                    vertexShader:   "../config/shaders/video/interpol.vert.qsb"
                    fragmentShader: "../config/shaders/video/interpol.frag.qsb"
                    onStatusChanged: {
                        if (status === ShaderEffect.Error) {
                            console.warn("Brain_Shell: interpolation shader error — falling back to direct video")
                            videoRoot.interpolate = false
                        }
                    }
                }
            }
        }

        // Optional palette tint over the whole video stack
        layer.enabled: root.tintEnabled && root.effectivePaletteSize > 0 && isVideo
        layer.smooth: true
        layer.effect: ShaderEffect {
            property var paletteTexture: paletteTextureSource
            property int paletteSize: root.effectivePaletteSize
            property real sharpness: 20.0
            property real mixStrength: 1.0
            property real texWidth: videoRoot.width
            property real texHeight: videoRoot.height
            vertexShader:   "../config/shaders/video/palette.vert.qsb"
            fragmentShader: "../config/shaders/video/palette.frag.qsb"
        }
    }
    }  // end contentContainer
}

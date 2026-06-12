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

    // ── Wallpaper change handler with grow-from-below transition ───────────────
    // Covers the screen with a curtain, then shrinks it upward to reveal
    // the new wallpaper from bottom to top (grow-from-below effect).
    property string _lastPath: ""

    onCurrentPathChanged: {
        if (currentPath === _lastPath) return
        if (currentPath === "") return

        // 1. Cover screen with curtain
        transitionCurtain.height = root.height

        // 2. Swap to new wallpaper path underneath
        _displayPath = currentPath
        _lastPath = currentPath

        if (isVideo && VideoWallpaperService) {
            VideoWallpaperService.getEffectivePath(currentPath, function(path) {
                root._effectivePath = path || currentPath
            })
        } else {
            root._effectivePath = currentPath
        }

        // 3. Animate curtain away → reveals new wallpaper from bottom to top
        Qt.callLater(function() {
            transitionCurtain.height = 0
        })
    }

    Component.onCompleted: {
        if (currentPath !== "") {
            _displayPath = currentPath
            _lastPath = currentPath
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
                var p = root._effectivePath || root.currentPath
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

        // Interpolation shader — blends previous + current frame
        ShaderEffect {
            id: interpolationEffect
            anchors.fill: parent
            visible: videoRoot.interpolate && videoRoot.multiplier > 1
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

    // ═══════════════════════════════════════════════════════════════════════════
    //  GROW-FROM-BELOW TRANSITION
    //  A curtain covers the old wallpaper, then shrinks upward (anchored top),
    //  revealing the new wallpaper from the bottom → growing upward.
    // ═══════════════════════════════════════════════════════════════════════════
    Rectangle {
        id: transitionCurtain
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 0  // hidden by default
        color: Theme.background
        z: 10

        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }
}

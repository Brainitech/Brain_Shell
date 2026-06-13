import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../"

/*!
    Wallpaper background window — structurally identical to NothingLess.
    No shaders. Signal-driven crossfade with direct contentReady→stabilize→crossfade.
*/
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "brain-shell:wallpaper"
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    // ── Source resolution ────────────────────────────────────────────────────
    readonly property string currentPath: WallpaperService.currentWall || ""

    readonly property string effectivePath: {
        if (!screen || !screen.name) return currentPath
        var ps = WallpaperService.perScreenWallpapers
        if (ps && ps[screen.name]) return ps[screen.name]
        return currentPath
    }

    function getFileType(p) {
        if (!p) return "unknown"
        var ext = p.toLowerCase().split('.').pop()
        if (['jpg','jpeg','png','webp','tif','tiff','bmp'].indexOf(ext) >= 0) return "image"
        if (ext === 'gif') return 'gif'
        if (['mp4','webm','mkv','mov','avi'].indexOf(ext) >= 0) return 'video'
        return 'unknown'
    }

    // ── Idle-based pause ─────────────────────────────────────────────────────
    readonly property bool videoPaused: IdleService.idleTime > 30000

    // ═══════════════════════════════════════════════════════════════════════════
    //  CROSSFADE — structurally identical to NothingLess
    // ═══════════════════════════════════════════════════════════════════════════
    property int  _activeLayer: 0
    property bool _swapping:    false
    property string _lastSource: ""

    onEffectivePathChanged: {
        if (!root.effectivePath) return
        if (root.effectivePath === root._lastSource) return
        root._lastSource = root.effectivePath
        root._beginSwap()
    }

    Component.onCompleted: {
        if (root.effectivePath && root.effectivePath !== root._lastSource) {
            root._lastSource = root.effectivePath
            root._beginSwap()
        }
    }

    function _beginSwap() {
        if (_swapping) return
        var nextLoader = (_activeLayer === 0) ? layerBLoader : layerALoader
        var currLayer  = (_activeLayer === 0) ? layerA : layerB
        var nextLayer  = (_activeLayer === 0) ? layerB : layerA
        var currLoader = (_activeLayer === 0) ? layerALoader : layerBLoader
        var isInitial  = !currLoader.item || currLoader._wallSource === ""

        // Fast path: same source already loaded
        if (!isInitial && nextLoader._wallSource === root.effectivePath && nextLoader.item) {
            _swapping = true
            _stabilizeAndFade(currLayer, nextLayer)
            return
        }

        _swapping = true
        nextLoader._wallSource = root.effectivePath
        nextLoader.active = true

        _stabilizeTimer._currLayer = currLayer
        _stabilizeTimer._nextLayer = nextLayer
        _stabilizeTimer._isInitial = isInitial

        _readyTimeoutTimer.restart()
    }

    // Called directly when the inner media signals contentReady()
    function _onLayerContentReady() {
        if (!_swapping) return
        _readyTimeoutTimer.stop()
        _stabilizeTimer.restart()
    }

    Timer {
        id: _readyTimeoutTimer
        interval: 3000
        onTriggered: {
            if (_swapping) {
                console.warn("[Wallpaper] contentReady timeout — forcing crossfade")
                _stabilizeTimer.restart()
            }
        }
    }

    Timer {
        id: _stabilizeTimer
        interval: 80
        property var _currLayer: null
        property var _nextLayer: null
        property bool _isInitial: false
        onTriggered: _stabilizeAndFade(_currLayer, _nextLayer)
    }

    function _stabilizeAndFade(currLayer, nextLayer) {
        if (currLayer) {
            // Smooth crossfade: old fades out, new fades in with subtle zoom
            crossfadeAnim.currLayer = currLayer
            crossfadeAnim.nextLayer = nextLayer
            nextLayer.scale = 0.97
            crossfadeAnim.restart()
        } else {
            nextLayer.opacity = 0.0
            nextLayer.scale   = 1.0
            fadeInOnlyAnim.targetLayer = nextLayer
            fadeInOnlyAnim.restart()
        }
    }

    ParallelAnimation {
        id: crossfadeAnim
        property var currLayer: null
        property var nextLayer: null

        NumberAnimation {
            target: crossfadeAnim.currLayer; property: "opacity"
            to: 0.0; duration: 280; easing.type: Easing.InOutCubic
        }
        ParallelAnimation {
            NumberAnimation {
                target: crossfadeAnim.nextLayer; property: "opacity"
                to: 1.0; duration: 280; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: crossfadeAnim.nextLayer; property: "scale"
                to: 1.0; duration: 320; easing.type: Easing.OutCubic
            }
        }
        onStopped: _finishSwap()
    }

    NumberAnimation {
        id: fadeInOnlyAnim
        property var targetLayer: null
        target: fadeInOnlyAnim.targetLayer; property: "opacity"
        to: 1.0; duration: 200; easing.type: Easing.OutCubic
        onStopped: _finishSwap()
    }

    function _finishSwap() {
        _activeLayer = (_activeLayer === 0) ? 1 : 0
        var oldLoader = (_activeLayer === 0) ? layerBLoader : layerALoader
        oldLoader.active = false
        oldLoader._wallSource = ""
        _swapping = false
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  LAYOUT — same structure as NothingLess: keyboard Rectangle wraps layers
    // ═══════════════════════════════════════════════════════════════════════════
    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        focus: true

        Keys.onLeftPressed:  WallpaperService.previousWallpaper()
        Keys.onRightPressed: WallpaperService.nextWallpaper()

        // ═══════════════════════════════════════════════════════════════════
        //  LAYER A
        // ═══════════════════════════════════════════════════════════════════
        Item {
            id: layerA
            anchors.fill: parent
            opacity: _activeLayer === 0 ? 1.0 : 0.0
            scale: 1.0
            Behavior on opacity { enabled: false }
            Behavior on scale   { enabled: false }

            Loader {
                id: layerALoader
                anchors.fill: parent
                asynchronous: true
                active: _activeLayer === 0
                property string _wallSource: ""

                sourceComponent: {
                    if (!_wallSource) return null
                    var ft = root.getFileType(_wallSource)
                    if (ft === 'image') return staticImageComponent
                    return videoComponent
                }
                onLoaded: {
                    if (item) {
                        if (item.contentReady) item.contentReady.connect(root._onLayerContentReady)
                        item.sourceFile = _wallSource
                    }
                }
                onStatusChanged: {
                    if (status === Loader.Error)
                        console.error("[Wallpaper] layerALoader FAILED for:", _wallSource)
                }
                Binding {
                    target: layerALoader.item; property: "sourceFile"
                    value: layerALoader._wallSource
                    when: layerALoader.item !== null && layerALoader._wallSource !== ""
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        //  LAYER B
        // ═══════════════════════════════════════════════════════════════════
        Item {
            id: layerB
            anchors.fill: parent
            opacity: _activeLayer === 1 ? 1.0 : 0.0
            scale: 1.0
            Behavior on opacity { enabled: false }
            Behavior on scale   { enabled: false }

            Loader {
                id: layerBLoader
                anchors.fill: parent
                asynchronous: true
                active: _activeLayer === 1
                property string _wallSource: ""

                sourceComponent: {
                    if (!_wallSource) return null
                    var ft = root.getFileType(_wallSource)
                    if (ft === 'image') return staticImageComponent
                    return videoComponent
                }
                onLoaded: {
                    if (item) {
                        if (item.contentReady) item.contentReady.connect(root._onLayerContentReady)
                        item.sourceFile = _wallSource
                    }
                }
                onStatusChanged: {
                    if (status === Loader.Error)
                        console.error("[Wallpaper] layerBLoader FAILED for:", _wallSource)
                }
                Binding {
                    target: layerBLoader.item; property: "sourceFile"
                    value: layerBLoader._wallSource
                    when: layerBLoader.item !== null && layerBLoader._wallSource !== ""
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  STATIC IMAGE COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: staticImageComponent
        Item {
            id: staticImageRoot
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()

            Image {
                id: rawImage
                anchors.fill: parent
                source: staticImageRoot.sourceFile ? "file://" + staticImageRoot.sourceFile : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                cache: false

                onStatusChanged: {
                    if (status === Image.Ready) {
                        staticImageRoot.contentReady()
                    } else if (status === Image.Error) {
                        console.error("[Wallpaper] image FAILED:", source)
                        staticImageRoot.contentReady()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    visible: rawImage.status !== Image.Ready
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  VIDEO + GIF COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: videoComponent
        Item {
            id: videoRoot
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()

            property string effectiveSource: ""

            function _relayReady() { videoRoot.contentReady() }

            function _ensureCache(sourcePath) {
                if (!sourcePath) { videoRoot.effectiveSource = ""; return }
                var ft = root.getFileType(sourcePath)
                if (ft === 'gif') { videoRoot.effectiveSource = sourcePath; return }
                if (typeof VideoWallpaperService === "undefined") {
                    videoRoot.effectiveSource = sourcePath; return
                }
                // Play original immediately; swap to cache when ready
                videoRoot.effectiveSource = sourcePath
                var cachePath = VideoWallpaperService.getEffectivePath(sourcePath)
                if (cachePath === sourcePath || !cachePath) return
                VideoWallpaperService.checkCache(cachePath, function(exists) {
                    if (exists && videoRoot.sourceFile === sourcePath)
                        videoRoot.effectiveSource = cachePath
                    else if (!exists)
                        VideoWallpaperService.generateCache(sourcePath, cachePath)
                })
            }

            onSourceFileChanged: {
                if (!sourceFile) return
                var ft = root.getFileType(sourceFile)
                if (ft === 'gif') { gifLoader.active = true; videoLoader.active = false }
                else { gifLoader.active = false; videoLoader.active = true }
                videoRoot._ensureCache(sourceFile)
            }

            onEffectiveSourceChanged: {
                if (videoLoader.active && videoLoader.item && videoRoot.effectiveSource)
                    videoLoader.item._setSource(videoRoot.effectiveSource)
            }

            Loader {
                id: gifLoader
                anchors.fill: parent; active: false
                sourceComponent: gifPlayerComp
                onLoaded: {
                    if (item) {
                        if (item.contentReady) item.contentReady.connect(videoRoot._relayReady)
                        item.sourceFile = videoRoot.sourceFile
                    }
                }
            }

            Loader {
                id: videoLoader
                anchors.fill: parent; active: false
                sourceComponent: videoPlayerComp
                onLoaded: {
                    if (item) {
                        if (item.contentReady) item.contentReady.connect(videoRoot._relayReady)
                        item.sourceFile = videoRoot.sourceFile
                        if (videoRoot.effectiveSource)
                            item._setSource(videoRoot.effectiveSource)
                    }
                }
            }
        }
    }

    // ── GIF player ───────────────────────────────────────────────────────────
    Component {
        id: gifPlayerComp
        Item {
            id: gifRoot
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()
            property bool _signalled: false

            AnimatedImage {
                id: gifImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: false; asynchronous: true
                source: gifRoot.sourceFile ? "file://" + gifRoot.sourceFile : ""
                playing: !root.videoPaused
                visible: status === AnimatedImage.Ready

                onStatusChanged: {
                    if (status === AnimatedImage.Ready && !gifRoot._signalled) {
                        gifRoot._signalled = true; gifRoot.contentReady()
                    } else if (status === AnimatedImage.Error && !gifRoot._signalled) {
                        gifRoot._signalled = true; gifRoot.contentReady()
                    }
                }

                Rectangle {
                    anchors.fill: parent; color: "black"
                    visible: gifImg.status !== AnimatedImage.Ready
                }
            }
        }
    }

    // ── Video player ─────────────────────────────────────────────────────────
    Component {
        id: videoPlayerComp
        Item {
            id: vidRoot
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()
            property bool _signalled: false

            function _setSource(src) {
                if (!src) { videoPlayer.source = ""; return }
                vidRoot._signalled = false
                videoReadyPoll.running = true
                videoPlayer.source = "file://" + src
            }

            Video {
                id: videoPlayer
                anchors.fill: parent
                loops: MediaPlayer.Infinite
                autoPlay: true
                muted: true
                fillMode: VideoOutput.PreserveAspectCrop

                onPlaybackStateChanged: {
                    if (!vidRoot._signalled &&
                        (playbackState === MediaPlayer.PlayingState ||
                         playbackState === MediaPlayer.Loaded)) {
                        vidRoot._signalled = true
                        videoReadyPoll.running = false
                        vidRoot.contentReady()
                    }
                    if (root.videoPaused && playbackState === MediaPlayer.PlayingState)
                        pause()
                    else if (!root.videoPaused && playbackState !== MediaPlayer.PlayingState
                             && source != undefined && source != "")
                        play()
                }
            }

            Timer {
                id: videoReadyPoll
                interval: 60; repeat: true
                onTriggered: {
                    if (!vidRoot._signalled &&
                        (videoPlayer.status === MediaPlayer.Loaded ||
                         videoPlayer.status === MediaPlayer.Buffered)) {
                        vidRoot._signalled = true
                        running = false
                        vidRoot.contentReady()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent; color: "black"
                visible: videoPlayer.status !== MediaPlayer.Loaded &&
                         videoPlayer.status !== MediaPlayer.Buffered
            }
        }
    }
}

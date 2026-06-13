import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../"

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "brain-shell:wallpaper"
    exclusionMode: ExclusionMode.Ignore
    color: Theme.background

    readonly property string currentPath: WallpaperService.currentWall || ""
    property string _effectivePath: ""
    property bool _waitingForCache: false

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
    onVideoPausedChanged: {
        _updateVideoPauseState()
    }
    function _updateVideoPauseState() {
        var activeLoader = (root._activeLayer === 0) ? wallLoaderA : wallLoaderB
        var item = activeLoader.item
        if (!item) return
        var ft = root.getFileType(activeLoader._wallSource)
        if (ft === 'gif') {
            var gifItem = _findAnimatedImage(item)
            if (gifItem && gifItem.hasOwnProperty('playing'))
                gifItem.playing = !videoPaused
        } else if (ft === 'video') {
            var v = _findChildVideo(item)
            if (!v) return
            if (videoPaused && v.playbackState === MediaPlayer.PlayingState) v.pause()
            else if (!videoPaused && v.playbackState !== MediaPlayer.PlayingState) v.play()
        }
    }
    function _findAnimatedImage(parent) {
        for (var i = 0; i < parent.children.length; i++) {
            var c = parent.children[i]
            if (c.hasOwnProperty('playing') && c.hasOwnProperty('speed')) return c
            var f = _findAnimatedImage(c); if (f) return f
        }
        return null
    }
    function _findChildVideo(parent) {
        for (var i = 0; i < parent.children.length; i++) {
            var c = parent.children[i]
            if (c.hasOwnProperty('playbackState') && c.hasOwnProperty('loops')) return c
            var f = _findChildVideo(c); if (f) return f
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  CROSSFADE WALLPAPER SYSTEM  (signal-driven, no polling)
    //
    //  Two-layer architecture:
    //    - layerA / layerB alternate as "current" and "next"
    //    - Loader.onLoaded → stabilizeTimer (100ms for first-frame paint)
    //    - Then crossfade: current opacity → 0, next opacity → 1
    //    - Subtle zoom (1.0→1.03) on the NEW layer for a polished reveal
    //    - After fade, old layer is unloaded to free GPU resources
    // ═══════════════════════════════════════════════════════════════════════════
    property int  _activeLayer: 0       // 0 = layerA active, 1 = layerB active
    property bool _swapping:    false   // true during an active swap
    property string _lastPath:  ""

    // ── Resolve effective (possibly cached) path for video wallpapers ─────
    function _resolvePath(src) {
        if (!src) return
        var ft = root.getFileType(src)
        if (ft === 'video' && VideoWallpaperService) {
            root._waitingForCache = true
            VideoWallpaperService.getEffectivePath(src, function(p) {
                root._effectivePath = p || src
                root._waitingForCache = false
            })
        } else {
            root._effectivePath = src
            root._waitingForCache = false
        }
    }

    onCurrentPathChanged: {
        if (!root.currentPath) return
        if (root.currentPath === root._lastPath) return   // same wallpaper
        root._lastPath = root.currentPath
        root._resolvePath(root.currentPath)
        root._beginSwap()
    }

    // ── Initiate a wallpaper swap ─────────────────────────────────────────
    function _beginSwap() {
        if (root._swapping) return

        var nextLoader = (root._activeLayer === 0) ? wallLoaderB : wallLoaderA
        var currLayer  = (root._activeLayer === 0) ? layerA : layerB
        var nextLayer  = (root._activeLayer === 0) ? layerB : layerA

        var currLoader = (root._activeLayer === 0) ? wallLoaderA : wallLoaderB
        var isInitial  = !currLoader.item || currLoader._wallSource === ""

        // Already loaded this source in the inactive loader? → fast crossfade
        if (!isInitial && nextLoader._wallSource === root.currentPath && nextLoader.item) {
            root._swapping = true
            root._stabilizeAndFade(currLayer, nextLayer)
            return
        }

        // Request the new wallpaper in the hidden loader
        root._swapping = true
        nextLoader._wallSource = root.currentPath
        nextLoader.active = true

        // Store context for when the loader finishes
        _stabilizeTimer._currLayer = currLayer
        _stabilizeTimer._nextLayer = nextLayer
        _stabilizeTimer._isInitial = isInitial
    }

    // ── Called by Loader.onLoaded — the outer container exists ────────────
    function _onNextLoaderReady(loader) {
        if (!root._swapping) return
        // The Loader's item is created. Now wait for the inner media
        // (Image/Video/AnimatedImage) to signal it's truly ready.
        // Start a safety timeout in case the signal never fires.
        _readyTimeoutTimer.restart()
    }

    // ── Called by the wallpaper component when the actual media is ready ──
    function _onContentReady() {
        if (!root._swapping) return
        _readyTimeoutTimer.stop()
        _stabilizeTimer.restart()
    }

    // Safety timeout: if contentReady never fires, fade anyway after 2.5s
    Timer {
        id: _readyTimeoutTimer
        interval: 2500
        onTriggered: {
            if (root._swapping) {
                console.warn("[Wallpaper] contentReady timeout — forcing crossfade")
                _stabilizeTimer.restart()
            }
        }
    }

    Timer {
        id: _stabilizeTimer
        interval: 80   // short delay after media ready → let GPU paint first frame
        property var _currLayer: null
        property var _nextLayer: null
        property bool _isInitial: false

        onTriggered: {
            root._stabilizeAndFade(_currLayer, _nextLayer)
        }
    }

    function _stabilizeAndFade(currLayer, nextLayer) {
        if (currLayer) {
            // Normal crossfade: old fades out, new fades in with subtle zoom
            crossfadeAnim.currLayer = currLayer
            crossfadeAnim.nextLayer = nextLayer
            crossfadeAnim.isInitial  = false
            // Reset next layer scale before animating in
            nextLayer.scale = 0.97
            crossfadeAnim.restart()
        } else {
            // Initial load: just fade in, no zoom, no fade-out
            nextLayer.opacity = 0.0
            nextLayer.scale   = 1.0
            fadeInOnlyAnim.targetLayer = nextLayer
            fadeInOnlyAnim.restart()
        }
    }

    // ── Full crossfade animation (fade + subtle zoom reveal) ──────────────
    ParallelAnimation {
        id: crossfadeAnim
        property var currLayer: null
        property var nextLayer: null
        property bool isInitial: false

        // Old layer: fade out + slight scale down
        SequentialAnimation {
            NumberAnimation {
                target: crossfadeAnim.currLayer; property: "opacity"
                to: 0.0; duration: 380; easing.type: Easing.InOutCubic
            }
        }
        // New layer: fade in + gentle zoom-in (0.97→1.0)
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: crossfadeAnim.nextLayer; property: "opacity"
                    to: 1.0; duration: 380; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: crossfadeAnim.nextLayer; property: "scale"
                    to: 1.0; duration: 420; easing.type: Easing.OutBack
                }
            }
        }

        onStopped: root._finishSwap()
    }

    // ── Initial-load fade-in only (no old layer, no zoom) ─────────────────
    NumberAnimation {
        id: fadeInOnlyAnim
        property var targetLayer: null
        target: fadeInOnlyAnim.targetLayer; property: "opacity"
        to: 1.0; duration: 300; easing.type: Easing.OutCubic

        onStopped: root._finishSwap()
    }

    // ── Cleanup after crossfade completes ─────────────────────────────────
    function _finishSwap() {
        // Swap active layer
        root._activeLayer = (root._activeLayer === 0) ? 1 : 0

        // Unload the old loader to free GPU resources
        var oldLoader = (root._activeLayer === 0) ? wallLoaderB : wallLoaderA
        oldLoader.active = false
        oldLoader._wallSource = ""

        root._swapping = false
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  LAYER A
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        id: layerA
        anchors.fill: parent
        opacity: root._activeLayer === 0 ? 1.0 : 0.0
        scale: 1.0
        Behavior on opacity { enabled: false }
        Behavior on scale   { enabled: false }

        Loader {
            id: wallLoaderA
            anchors.fill: parent
            asynchronous: true
            active: root._activeLayer === 0
            property string _wallSource: ""

            sourceComponent: {
                if (!_wallSource) return null
                var ft = root.getFileType(_wallSource)
                if (ft === 'image') return staticImageComponent
                return videoComponent
            }

            onLoaded: {
                if (item) {
                    // Connect signal BEFORE setting source (avoids race condition
                    // where media loads before listener is attached)
                    if (item.contentReady) item.contentReady.connect(root._onContentReady)
                    item.sourceFile = _wallSource
                }
                root._onNextLoaderReady(wallLoaderA)
            }

            Binding {
                target: wallLoaderA.item; property: "sourceFile"
                value: wallLoaderA._wallSource
                when: wallLoaderA.item !== null && wallLoaderA._wallSource !== ""
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  LAYER B
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        id: layerB
        anchors.fill: parent
        opacity: root._activeLayer === 1 ? 1.0 : 0.0
        scale: 1.0
        Behavior on opacity { enabled: false }
        Behavior on scale   { enabled: false }

        Loader {
            id: wallLoaderB
            anchors.fill: parent
            asynchronous: true
            active: root._activeLayer === 1
            property string _wallSource: ""

            sourceComponent: {
                if (!_wallSource) return null
                var ft = root.getFileType(_wallSource)
                if (ft === 'image') return staticImageComponent
                return videoComponent
            }

            onLoaded: {
                if (item) {
                    if (item.contentReady) item.contentReady.connect(root._onContentReady)
                    item.sourceFile = _wallSource
                }
                root._onNextLoaderReady(wallLoaderB)
            }

            Binding {
                target: wallLoaderB.item; property: "sourceFile"
                value: wallLoaderB._wallSource
                when: wallLoaderB.item !== null && wallLoaderB._wallSource !== ""
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  STATIC IMAGE COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: staticImageComponent
        Item {
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()

            Image {
                id: img
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true; mipmap: true; cache: false
                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                visible: status === Image.Ready
                sourceSize.width: 3840; sourceSize.height: 2160
                onStatusChanged: {
                    if (status === Image.Ready) parent.contentReady()
                }

                Rectangle {
                    anchors.fill: parent; color: Theme.background
                    visible: img.status !== Image.Ready
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  VIDEO + GIF COMPONENT  (delegates to GIF or Video sub-loader)
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: videoComponent
        Item {
            id: videoRoot
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()

            // Relays inner component's contentReady upward
            function _relayReady() { videoRoot.contentReady() }

            onSourceFileChanged: {
                if (!sourceFile) return
                var ft = root.getFileType(sourceFile)
                if (ft === 'gif') { gifLoader.active = true; videoLoader.active = false }
                else { gifLoader.active = false; videoLoader.active = true }
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
                Binding { target: gifLoader.item; property: "sourceFile"; value: videoRoot.sourceFile; when: gifLoader.item !== null }
            }
            Loader {
                id: videoLoader
                anchors.fill: parent; active: false
                sourceComponent: videoPlayerComp
                onLoaded: {
                    if (item) {
                        if (item.contentReady) item.contentReady.connect(videoRoot._relayReady)
                        item.sourceFile = videoRoot.sourceFile
                    }
                }
                Binding { target: videoLoader.item; property: "sourceFile"; value: videoRoot.sourceFile; when: videoLoader.item !== null }
            }
        }
    }

    // ── GIF sub-component ────────────────────────────────────────────────────
    Component {
        id: gifPlayerComp
        Item {
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()
            AnimatedImage {
                id: gifImg
                anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                cache: false; asynchronous: true
                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                playing: !root.videoPaused
                visible: status === AnimatedImage.Ready
                onStatusChanged: {
                    if (status === AnimatedImage.Ready) parent.contentReady()
                }
                Rectangle {
                    anchors.fill: parent; color: Theme.background
                    visible: gifImg.status !== AnimatedImage.Ready
                }
            }
        }
    }

    // ── Video sub-component ──────────────────────────────────────────────────
    Component {
        id: videoPlayerComp
        Item {
            anchors.fill: parent
            property string sourceFile: ""
            signal contentReady()

            Video {
                id: vid
                anchors.fill: parent
                source: {
                    if (!parent.sourceFile) return ""
                    var p = root._effectivePath || parent.sourceFile
                    return p ? "file://" + p : ""
                }
                loops: MediaPlayer.Infinite; autoPlay: true; muted: true
                fillMode: VideoOutput.PreserveAspectCrop
            }

            // Poll video status until ready (onStatusChanged may not be available
            // on all QtMultimedia / Quickshell Video implementations)
            Timer {
                id: videoReadyPoll
                interval: 60; repeat: true; running: parent.sourceFile !== ""
                onTriggered: {
                    if (vid.status === MediaPlayer.Loaded || vid.status === MediaPlayer.Buffered) {
                        running = false
                        parent.contentReady()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent; color: Theme.background
                visible: vid.status !== MediaPlayer.Loaded && vid.status !== MediaPlayer.Buffered
            }
        }
    }
}

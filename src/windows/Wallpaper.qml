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
        var item = wallImageLoader.item
        if (!item) return
        var ft = getFileType(wallImageContainer.source)
        if (ft === 'gif') {
            if (item.hasOwnProperty('playing')) item.playing = !videoPaused
        } else if (ft === 'video') {
            var v = _findChildVideo(item)
            if (!v) return
            if (videoPaused && v.playbackState === MediaPlayer.PlayingState) v.pause()
            else if (!videoPaused && v.playbackState !== MediaPlayer.PlayingState) v.play()
        }
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
    //  CONTAINER + LOADER  (NothingLess pattern — Loader destroys old on type
    //  change, Binding + Connections keep sourceFile in sync)
    // ═══════════════════════════════════════════════════════════════════════════
    Item {
        id: wallImageContainer
        anchors.fill: parent
        property string source: root.currentPath
        property string previousSource: ""

        onSourceChanged: {
            if (!source) return
            var ft = root.getFileType(source)
            if (ft === 'video' && VideoWallpaperService) {
                root._waitingForCache = true
                VideoWallpaperService.getEffectivePath(source, function(p) {
                    root._effectivePath = p || source
                    root._waitingForCache = false
                })
            } else {
                root._effectivePath = source
                root._waitingForCache = false
            }
        }

        // ── Transition animation (scale + opacity pulse) ─────────────────────
        SequentialAnimation {
            id: transitionAnimation
            ParallelAnimation {
                NumberAnimation { target: wallImageContainer; property: "scale"; to: 1.02; duration: 280; easing.type: Easing.OutCubic }
                NumberAnimation { target: wallImageContainer; property: "opacity"; to: 0.4; duration: 280; easing.type: Easing.OutCubic }
            }
            ParallelAnimation {
                NumberAnimation { target: wallImageContainer; property: "scale"; to: 1.0; duration: 380; easing.type: Easing.InOutCubic }
                NumberAnimation { target: wallImageContainer; property: "opacity"; to: 1.0; duration: 380; easing.type: Easing.InOutCubic }
            }
        }

        // ── Media Loader — picks component by file type ──────────────────────
        Loader {
            id: wallImageLoader
            anchors.fill: parent
            asynchronous: true
            sourceComponent: {
                if (!wallImageContainer.source) return null
                var ft = root.getFileType(wallImageContainer.source)
                if (ft === 'image') return staticImageComponent
                return videoComponent  // GIF + video share same wrapper
            }

            onLoaded: {
                if (item) item.sourceFile = wallImageContainer.source
                if (wallImageContainer.previousSource !== ""
                    && wallImageContainer.source !== wallImageContainer.previousSource) {
                    transitionAnimation.restart()
                }
                wallImageContainer.previousSource = wallImageContainer.source
            }

            Binding {
                target: wallImageLoader.item
                property: "sourceFile"
                value: wallImageContainer.source
                when: wallImageLoader.item !== null
            }

            Connections {
                target: wallImageContainer
                function onSourceChanged() {
                    if (wallImageLoader.item && wallImageLoader.item.sourceFile !== wallImageContainer.source) {
                        wallImageLoader.item.sourceFile = wallImageContainer.source
                    }
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
            anchors.fill: parent
            property string sourceFile: ""
            Image {
                id: img
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true; mipmap: true; cache: false
                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                visible: status === Image.Ready
                sourceSize.width: 3840; sourceSize.height: 2160
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
                onLoaded: { if (item) item.sourceFile = videoRoot.sourceFile }
                Binding { target: gifLoader.item; property: "sourceFile"; value: videoRoot.sourceFile; when: gifLoader.item !== null }
            }
            Loader {
                id: videoLoader
                anchors.fill: parent; active: false
                sourceComponent: videoPlayerComp
                onLoaded: { if (item) item.sourceFile = videoRoot.sourceFile }
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
            AnimatedImage {
                id: gifImg
                anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                cache: false; asynchronous: true
                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                playing: !root.videoPaused
                visible: status === AnimatedImage.Ready
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
            Rectangle {
                anchors.fill: parent; color: Theme.background
                visible: vid.status !== MediaPlayer.Loaded && vid.status !== MediaPlayer.Buffered
            }
        }
    }
}

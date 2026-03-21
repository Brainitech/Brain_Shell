import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../"
import "../../components"

// Rounded corners strategy:
//   Only the background visuals (image + gradient) need clipping to the radius.
//   Text and controls sit on top as normal items — they never reach the corners.
//
//   bgSource (opacity:0, layer.enabled:true) — rasterised but not drawn directly.
//     Qt docs: opacity:0 items ARE still rasterised so layer texture is populated.
//   bgMask   (visible:false, layer.enabled:true) — rounded rect shape.
//   MultiEffect composites bgSource masked by bgMask → clipped background.
//   All interactive items live in the normal scene tree above it.

Item {
    id: root

    // ── MPRIS ─────────────────────────────────────────────────────────────────
    readonly property var player: Mpris.players.values.length > 0
                                  ? Mpris.players.values[0] : null

    readonly property bool   isPlaying: root.player?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string artUrl:    root.player?.trackArtUrl ?? ""

    readonly property string title: {
        var t = root.player?.trackTitle
        return (t && t !== "") ? t : "Nothing Playing"
    }
    readonly property string artist: {
        var a = root.player?.trackArtists
        if (!a) return ""
        if (typeof a === "string") return a
        if (typeof a.join === "function") return a.join(", ")
        return a.toString()
    }

    readonly property real length:   root.player?.length   ?? 0
    readonly property real position: root.player?.position ?? 0

    property real _pos: 0
    onPositionChanged: root._pos = position

    Timer {
        interval: 1000; running: root.isPlaying; repeat: true
        onTriggered: {
            if (root.length > 0)
                root._pos = Math.min(root._pos + 1, root.length)
        }
    }

    function _fmt(sec) {
        var s = Math.floor(sec)
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    readonly property real _progress: root.length > 0 ? root._pos / root.length : 0

    // ── Cava — only runs while a music player is playing ─────────────────────
    // Detect music vs other media via trackLength > 0 and isPlaying.
    // Cava reads system audio so it always has signal; we just gate the bar
    // updates to avoid showing video playback in the music visualiser.
    readonly property int _cavaBars: 32

    property var _bars: (function() {
        var a = []; for (var i = 0; i < 32; i++) a.push(0); return a
    })()

    // Zero bars whenever the selected player stops
    onIsPlayingChanged: {
        if (!isPlaying) {
            var a = []; for (var i = 0; i < 32; i++) a.push(0)
            _bars = a
        }
    }

    Process {
        id: cavaProc
        command: [
            "bash", "-c",
            "mkdir -p /tmp/brain_shell && " +
            "printf '[general]\\nbars = 32\\nframerate = 30\\nnoise_reduction = 77\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 59\\nframe_delimiter = 10\\n' " +
            "> /tmp/brain_shell/cava_player.ini && " +
            "exec cava -p /tmp/brain_shell/cava_player.ini 2>/dev/null"
        ]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                // Only update bars when music is actually playing
                if (!root.isPlaying) return
                var t = line.trim()
                if (t === "") return
                if (t.endsWith(";")) t = t.slice(0, -1)
                var parts = t.split(";")
                if (parts.length !== root._cavaBars) return
                var bars = []
                for (var i = 0; i < parts.length; i++)
                    bars.push(parseInt(parts[i]) || 0)
                root._bars = bars
            }
        }
    }

    // ── Background visuals — opacity:0 so Qt rasterises but doesn't draw ─────
    Item {
        id: bgSource
        anchors.fill:  parent
        opacity:       0        // invisible to user, still rasterised for MultiEffect
        layer.enabled: true

        // Art image source for blur
        Item {
            id: artSource
            anchors.fill:  parent
            layer.enabled: true
            Image {
                anchors.fill: parent
                source:   root.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth:   true
            }
        }

        // Blurred art
        MultiEffect {
            source:       artSource
            anchors.fill: parent
            visible:      root.artUrl !== ""
            opacity:      root.artUrl !== "" ? 1 : 0
            blurEnabled:  true
            blur:         0.5
            blurMax:      32
            saturation:   0.2
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        // Gradient overlay — heavier at bottom for readability
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.38) }
                GradientStop { position: 0.4; color: Qt.rgba(0,0,0,0.50) }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.88) }
            }
        }
    }

    // Mask shape — rounded rect, layer.enabled so MultiEffect reads its alpha
    Rectangle {
        id: bgMask
        anchors.fill:  parent
        radius:        Theme.cornerRadius
        visible:       false
        layer.enabled: true
    }

    // Clipped background composite — drawn first, below all interactive content
    MultiEffect {
        source:           bgSource
        anchors.fill:     parent
        maskEnabled:      true
        maskSource:       bgMask
        maskThresholdMin: 0.5
        maskSpreadAtMin:  1.0
    }

    // ── Track name + artist — top, centered ───────────────────────────────────
    Column {
        anchors {
            left:  parent.left;  leftMargin:  14
            right: parent.right; rightMargin: 14
            top:   parent.top;   topMargin:   16
        }
        spacing: 4
        Text {
            width: parent.width
            text:  root.title
            font.pixelSize: 18; font.weight: Font.Bold
            color: "#ffffff"; elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            width:   parent.width
            text:    root.artist
            visible: root.artist !== ""
            font.pixelSize: 13
            color: Qt.rgba(1,1,1,0.55); elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Bottom stack: controls → progress → cava ─────────────────────────────
    Column {
        anchors {
            left:   parent.left;   leftMargin:   14
            right:  parent.right;  rightMargin:  14
            bottom: parent.bottom; bottomMargin: 10
        }
        spacing: 6

        // Controls: prev · play/pause · next
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28
            Repeater {
                model: [ { key: "prev" }, { key: "play" }, { key: "next" } ]
                delegate: Rectangle {
                    required property var  modelData
                    required property int  index
                    readonly property bool isPlay: modelData.key === "play"
                    readonly property string dispIcon: {
                        if (modelData.key === "prev") return "\u23EE"
                        if (modelData.key === "next") return "\u23ED"
                        return root.isPlaying ? "\u23F8" : "\u23F5"
                    }
                    width:  isPlay ? 44 : 36; height: isPlay ? 44 : 36
                    radius: height / 2
                    color: isPlay
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                           : cH.hovered ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.06)
                    border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: parent.dispIcon
                        font.pixelSize: isPlay ? 18 : 14
                        color: isPlay ? Theme.active : Qt.rgba(1,1,1,0.7)
                    }
                    HoverHandler { id: cH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!root.player) return
                            switch (modelData.key) {
                                case "play":
                                    if (root.player.canTogglePlaying)
                                        root.player.isPlaying = !root.player.isPlaying
                                    break
                                case "prev":
                                    if (root.player.canGoPrevious) root.player.previous()
                                    break
                                case "next":
                                    if (root.player.canGoNext) root.player.next()
                                    break
                            }
                        }
                    }
                }
            }
        }

        // Progress bar + timestamps
        Column {
            width: parent.width; spacing: 3
            Item {
                width: parent.width; height: 6
                Rectangle {
                    anchors.fill: parent; radius: height / 2
                    color: Qt.rgba(1,1,1,0.2)
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (root.player && root.length > 0) {
                                var f = mouse.x / width
                                root.player.position = f * root.length
                                root._pos = f * root.length
                            }
                        }
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width:  Math.max(radius * 2, parent.width * root._progress)
                        radius: parent.radius; color: Theme.active
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }
            Item {
                width: parent.width; height: 14
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root._pos)
                    font.pixelSize: 9; font.family: "JetBrains Mono"
                    color: Qt.rgba(1,1,1,0.4)
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root.length)
                    font.pixelSize: 9; font.family: "JetBrains Mono"
                    color: Qt.rgba(1,1,1,0.4)
                }
            }
        }

        // Cava bars
        Item {
            width: parent.width; height: 32
            Row {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                spacing: 2
                readonly property real barW: Math.max(1, (parent.width - spacing * (root._cavaBars - 1)) / root._cavaBars)
                Repeater {
                    model: root._bars
                    delegate: Item {
                        required property int modelData
                        required property int index
                        width: parent.barW; height: 32
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width:  parent.width
                            height: Math.max(2, (modelData / 100) * 32)
                            radius: width / 2
                            color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25 + (modelData / 100) * 0.65)
                            Behavior on height { NumberAnimation { duration: 50; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }

    // Border drawn on top of everything
    Rectangle {
        anchors.fill: parent
        radius:       Theme.cornerRadius
        color:        "transparent"
        border.color: Qt.rgba(1,1,1,0.08)
        border.width: 1
    }
}

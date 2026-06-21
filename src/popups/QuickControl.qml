import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../shapes"
import "../components"
import "../services"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow

    // ── Context-Aware Scaling ─────────────────────────────────────────────────
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    // ── Config ────────────────────────────────────────────────────────────────
    readonly property int fw: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int fh: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int popupWidth:  Math.round(180 * root.localScale) // Thinner than the 300px AudioPopup

    color:   "transparent"
    visible: slide.windowVisible
    mask:    Region { item: maskProxy }

    // ── Position: Right Center ────────────────────────────────────────────────
    anchor.window:  anchorWindow
    anchor.rect: Qt.rect(
        anchorWindow.width - root.fw,
        anchorWindow.height/2,
        0,
        0
    )
    anchor.gravity: Edges.Right

    Item {
        id:      maskProxy
        x:       root.popupWidth - sizer.width
        y:       ((root.popupHeight - sizer.height) / 2) - root.fh
        width:   sizer.width
        height:  sizer.height
    }

    implicitWidth:  popupWidth
    implicitHeight: popupHeight

    // ── Audio State ───────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // ── Brightness State ──────────────────────────────────────────────────────
    property real _bVal:  0.72
    property int  _bMax:  100
    property bool _bBusy: false

    Process {
        id: brightRead
        command: ["bash", "-c", "brightnessctl -m"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(",")
                if (parts.length >= 5) {
                    var cur = parseInt(parts[2])
                    var max = parseInt(parts[4])
                    if (max > 0) {
                        root._bMax = max
                        root._bVal = cur / max
                    }
                }
            }
        }
    }

    Process {
        id: brightWrite
        command: ["bash", "-c", "brightnessctl set " + (Math.round(root._bVal * root._bMax) <= 0 ? 2 : Math.round(root._bVal * root._bMax))]
        running: false
        onRunningChanged: if (!running) root._bBusy = false
    }

    Timer {
        id: bDebounce
        interval: 50; repeat: false
        onTriggered: { root._bBusy = true; brightWrite.running = true }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: if (!root._bBusy) brightRead.running = true
    }

    Component.onCompleted: brightRead.running = true

    function setBrightness(v) {
        root._bVal = Math.max(0.0, Math.min(1.0, v))
        bDebounce.restart()
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    PopupSlide {
        id: slide
        anchors.fill:     parent
        edge:             "right"
        open:             Popups.quickOpen
        hoverEnabled:     !Popups.audioAllowHover && Popups.quickAllowHover
        triggerHovered:   Popups.quickTriggerHovered
        onCloseRequested: Popups.quickOpen = false

        Item {
            id: sizer
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            width:  root.popupWidth
            height: root.popupHeight

            Behavior on width { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

            PopupShape {
                id: bg
                anchors.fill: parent
                attachedEdge: "right"
                color:        Theme.background
                radius:       Theme.cornerRadius
                flareWidth:   root.fw
                flareHeight:  root.fh
            }

            // ── Sliders Layout ────────────────────────────────────────────────
            Row {
                anchors {
                    fill:         parent
                    topMargin:    root.fh + 30
                    leftMargin:   8
                    rightMargin:  8
                }
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                // Audio Slider
                ChannelColumn {
                    icon: {
                        if (!root.sink?.ready)            return "󰕾"
                        if (root.sink.audio.muted)        return "󰖁"
                        if (root.sink.audio.volume > 0.6) return "󰕾"
                        if (root.sink.audio.volume > 0.2) return "󰖀"
                        return "󰕿"
                    }
                    value:  root.sink?.ready ? root.sink.audio.volume : 0
                    muted:  root.sink?.audio.muted ?? false
                    active: root.sink?.ready ?? false

                    onVolumeChanged: function(v) {
                        if (root.sink?.ready) root.sink.audio.volume = v
                    }
                    onMuteToggled: {
                        if (root.sink?.ready) root.sink.audio.muted = !root.sink.audio.muted
                    }
                }

                // Brightness Slider
                ChannelColumn {
                    localScale: root.localScale
                    icon:   "󰃠"
                    value:  root._bVal
                    muted:  false
                    active: true

                    onVolumeChanged: function(v) {
                        root.setBrightness(v)
                    }
                }
            }
        }
    }

    // ── Reusable ChannelColumn Component ──────────────────────────────────────
    component ChannelColumn: Item {
        id: col

        property real localScale: 1.0
        property string label:  ""
        property string icon:   ""
        property real   value:  0.0
        property bool   muted:  false
        property bool   active: false

        readonly property int trackHeight: Math.round(180 * root.localScale)
        readonly property int barW:        Math.round(22 * root.localScale)
        readonly property int thumbD:      barW - Math.round(6 * root.localScale)

        signal volumeChanged(real value)
        signal muteToggled()

        implicitWidth:  inner.implicitWidth
        implicitHeight: inner.implicitHeight

        readonly property string pctText: active ? Math.round(value * 100) + "%" : "--%"

        Column {
            id: inner
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(12 * root.localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           col.pctText
                color:          col.muted ? Qt.rgba(1,1,1,0.25) : Theme.text
                font.pixelSize: Math.round(13 * root.localScale)
                font.bold:      true
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW
                height: col.trackHeight

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: width / 2
                    color:  Qt.rgba(1,1,1,0.08)

                    // Fill bar
                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: Math.max(radius * 2, parent.height * col.value)
                        radius: parent.radius
                        color:  col.muted ? Qt.rgba(1,1,1,0.15) : Theme.active
                        Behavior on color  { ColorAnimation  { duration: Anim.mediumFast} }
                        Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic} }
                    }

                    // Thumb
                    Rectangle {
                        id: thumb
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  col.thumbD
                        height: width
                        radius: width / 2
                        color:  col.muted ? Qt.rgba(1,1,1,0.3) : "#ffffff"
                        y: {
                            var travel = track.height - height
                            return Math.max(0, Math.min(travel, (1.0 - col.value) * travel))
                        }
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                    }

                    // Drag to change value
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.SizeVerCursor
                        function calc(my) {
                            var travel = track.height - thumb.height
                            return Math.max(0.0, Math.min(1.0, 1.0 - (my - thumb.height / 2) / travel))
                        }
                        onPressed:         col.volumeChanged(calc(mouseY))
                        onPositionChanged: if (pressed) col.volumeChanged(calc(mouseY))
                    }

                    // Scroll wheel to change value
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            var step = 0.05
                            var delta = event.angleDelta.y > 0 ? step : -step
                            col.volumeChanged(Math.max(0.0, Math.min(1.0, col.value + delta)))
                        }
                    }
                }
            }

            // Icon & Mute Toggle
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW + Math.round(16 * root.localScale)
                height: Math.round(28 * root.localScale)
                radius: Math.round(Theme.cornerRadius * root.localScale)
                color:  col.muted
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                            : Qt.rgba(1,1,1,0.06)
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }

                Text {
                    anchors.centerIn: parent
                    text:           col.icon
                    font.pixelSize: Math.round(14 * root.localScale)
                    color:          col.muted ? Theme.active : Qt.rgba(1,1,1,0.55)
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                }

                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: muteHov.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                }
                HoverHandler { id: muteHov; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: col.muteToggled()}
            }

            // Label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:            col.label
                color:           Qt.rgba(1,1,1,0.3)
                font.pixelSize:  Math.round(10 * root.localScale)
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                elide:           Text.ElideRight
                width:           col.barW + Math.round(50 * root.localScale)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

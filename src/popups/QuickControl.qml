import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import "../services"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int popupWidth:  Math.round(180 * root.localScale)

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.quickPinned = true
    }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property real _bVal: BrightnessService.brightness / 100






    Item {
        id: slide
        anchors.fill: parent
        clip: true
        

        Row {
            anchors.centerIn: parent
            spacing: Math.round(8 * root.localScale)
            
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

            ChannelColumn {
                localScale: root.localScale
                icon:   "󰃠"
                value:  root._bVal
                muted:  false
                active: true
                onVolumeChanged: function(v) {
                    BrightnessService.setBrightness(Math.round(v * 100))
                }
            }
        }
    }

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
                color:          col.muted ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.25) : Theme.text
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
                    color:  Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08)

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: Math.max(radius * 2, parent.height * col.value)
                        radius: parent.radius
                        color:  col.muted ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.15) : Theme.active
                        Behavior on color  { ColorAnimation  { duration: Anim.mediumFast} }
                        Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic} }
                    }

                    Rectangle {
                        id: thumb
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  col.thumbD
                        height: width
                        radius: width / 2
                        color:  col.muted ? Theme.subtext : Theme.text
                        y: {
                            var travel = track.height - height
                            return Math.max(0, Math.min(travel, (1.0 - col.value) * travel))
                        }
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                    }

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

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW + Math.round(16 * root.localScale)
                height: Math.round(28 * root.localScale)
                radius: Math.round(Theme.cornerRadius * root.localScale)
                color:  col.muted
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                            : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.06)
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }

                Text {
                    anchors.centerIn: parent
                    text:           col.icon
                    font.pixelSize: Math.round(14 * root.localScale)
                    color:          col.muted ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.55)
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                }

                Rectangle {
                HoverHandler { id: muteHov }
                    anchors.fill: parent; radius: parent.radius
                    color: muteHov.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.05) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                }

                MouseArea { anchors.fill: parent; onClicked: col.muteToggled()}
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:            col.label
                color:           Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.3)
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

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../shapes"
import "../"

// Audio popup — attached to the center of the right Border, grows leftward.
// PopupShape attachedEdge: "right" — right edge melts into the border.

PopupWindow {
    id: root

    required property var anchorWindow   // right Border PanelWindow

    // ── Hover-to-open config ─────────────────────────────────────────────────
    property bool openOnHover: true
    property int  closeDelay:  180

    property bool popupHovered: false

    visible: Popups.audioOpen
             || (openOnHover && (Popups.audioTriggerHovered || popupHovered))

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: {
            if (!Popups.audioTriggerHovered && !root.popupHovered)
                Popups.audioOpen = false
        }
    }

    Connections {
        target: Popups
        function onAudioTriggerHoveredChanged() {
            if (!Popups.audioTriggerHovered && !root.popupHovered)
                closeTimer.restart()
            else
                closeTimer.stop()
        }
    }

    onPopupHoveredChanged: {
        if (!popupHovered && !Popups.audioTriggerHovered)
            closeTimer.restart()
        else
            closeTimer.stop()
    }

    // ── Dimensions ───────────────────────────────────────────────────────────
    readonly property int popupWidth:  200
    readonly property int popupHeight: 360

    color:          "transparent"
    implicitWidth:  popupWidth
    implicitHeight: popupHeight

    // ── Anchor ───────────────────────────────────────────────────────────────
    // anchor.gravity: Edges.Left → the popup's RIGHT EDGE sits at anchor.rect.x
    // within the border window (which is exactly Theme.cornerRadius = 17 px wide).
    // Setting x = Theme.cornerRadius places the popup's right edge at the
    // screen edge, flush with where the border strip is drawn — zero gap.
    anchor.window: anchorWindow
    anchor.rect: Qt.rect(
        Theme.cornerRadius,
        anchorWindow.height / 2,
        0,
        popupHeight
    )
    anchor.gravity: Edges.Left

    // ── PipeWire ─────────────────────────────────────────────────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // ── Background ───────────────────────────────────────────────────────────
    PopupShape {
        id: bg
        anchors.fill: parent
        attachedEdge: "right"
        color:        Theme.background
        radius:       Theme.cornerRadius
        flareWidth:   Theme.cornerRadius
        flareHeight:  Theme.cornerRadius
    }

    // ── Hover on popup ────────────────────────────────────────────────────────
    HoverHandler {
        onHoveredChanged: root.popupHovered = hovered
    }

    // ── Content ──────────────────────────────────────────────────────────────
    Item {
        anchors {
            fill:         parent
            topMargin:    12
            bottomMargin: 12
            leftMargin:   12
            rightMargin:  bg.flareWidth + 6
        }

        Row {
            anchors.fill: parent
            spacing: 0

            ChannelColumn {
                width:  parent.width / 2
                height: parent.height
                label:  "Output"
                icon: {
                    if (!root.sink?.ready)            return "󰕾"
                    if (root.sink.audio.muted)         return "󰖁"
                    if (root.sink.audio.volume > 0.6)  return "󰕾"
                    if (root.sink.audio.volume > 0.2)  return "󰖀"
                    return "󰕿"
                }
                value:  root.sink?.ready ? root.sink.audio.volume : 0
                muted:  root.sink?.audio.muted ?? false
                active: root.sink?.ready ?? false

                onVolumeChanged: function(v) {
                    if (root.sink?.ready) root.sink.audio.volume = v
                }
                onMuteToggled: {
                    if (root.sink?.ready)
                        root.sink.audio.muted = !root.sink.audio.muted
                }
            }

            ChannelColumn {
                width:  parent.width / 2
                height: parent.height
                label:  "Input"
                icon:   root.source?.audio.muted ? "󰍭" : "󰍬"
                value:  root.source?.ready ? root.source.audio.volume : 0
                muted:  root.source?.audio.muted ?? false
                active: root.source?.ready ?? false

                onVolumeChanged: function(v) {
                    if (root.source?.ready) root.source.audio.volume = v
                }
                onMuteToggled: {
                    if (root.source?.ready)
                        root.source.audio.muted = !root.source.audio.muted
                }
            }
        }
    }

    // ── ChannelColumn ─────────────────────────────────────────────────────────
    component ChannelColumn: Item {
        id: col

        property string label:  ""
        property string icon:   ""
        property real   value:  0.0
        property bool   muted:  false
        property bool   active: false

        // ── Tweak this to resize the slider bars ──────────────────────────
        readonly property int trackHeight: 200
        // ─────────────────────────────────────────────────────────────────

        readonly property int barW:   22
        readonly property int thumbD: barW - 6

        signal volumeChanged(real value)
        signal muteToggled()

        readonly property string pctText:
            active ? Math.round(value * 100) + "%" : "--%"

        // Whole stack is vertically centered inside the column item
        Column {
            anchors.centerIn: parent
            spacing: 8

            // Percentage text
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           col.pctText
                color:          col.muted ? Qt.rgba(1,1,1,0.25) : Theme.text
                font.pixelSize: 13
                font.bold:      true
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Track — fixed height
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW
                height: col.trackHeight

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: width / 2
                    color:  Qt.rgba(1,1,1,0.08)

                    // Fill grows from bottom
                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left:   parent.left
                            right:  parent.right
                        }
                        height: Math.max(radius * 2,
                                         parent.height * col.value)
                        radius: parent.radius
                        color:  col.muted ? Qt.rgba(1,1,1,0.15) : Theme.active

                        Behavior on color  { ColorAnimation  { duration: 150 } }
                        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
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
                            return Math.max(0, Math.min(travel,
                                (1.0 - col.value) * travel
                            ))
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeVerCursor

                        function calc(my) {
                            var travel = track.height - thumb.height
                            return Math.max(0.0, Math.min(1.0,
                                1.0 - (my - thumb.height / 2) / travel
                            ))
                        }
                        onPressed:         col.volumeChanged(calc(mouseY))
                        onPositionChanged: if (pressed) col.volumeChanged(calc(mouseY))
                    }
                }
            }

            // Mute button
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW + 32
                height: 28
                radius: Theme.cornerRadius

                color: col.muted
                       ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                       : Qt.rgba(1,1,1,0.06)

                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text:           col.icon
                        font.pixelSize: 13
                        color:          col.muted ? Theme.active : Qt.rgba(1,1,1,0.55)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        text:           col.muted ? "Muted" : "Mute"
                        font.pixelSize: 11
                        color:          col.muted ? Theme.active : Qt.rgba(1,1,1,0.4)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    color:        muteHov.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                HoverHandler { id: muteHov; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: col.muteToggled() }
            }

            // Channel label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           col.label
                color:          Qt.rgba(1,1,1,0.3)
                font.pixelSize: 10
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }
        }
    }
}

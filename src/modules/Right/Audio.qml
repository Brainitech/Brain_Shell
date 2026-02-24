import QtQuick
import Quickshell.Services.Pipewire
import "../../components"
import "../../"

Item {
    id: root

    // ── Config ────────────────────────────────────────────────────────────────
    property bool showPercentage: false   // always show %; false = hover only

    implicitWidth:  row.implicitWidth + 6
    implicitHeight: row.implicitHeight

    // ── Pipewire ──────────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink

    // Guard null — PwObjectTracker crashes if objects contains null
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // ── Icon: plain Unicode symbols, no Nerd Font required ────────────────────
    // High "▊"  Med "▌"  Low "▍"  Muted "✕"  Not ready "–"
    readonly property string icon: {
        if (!sink?.ready)            return "󰕾"
        if (sink.audio.muted)        return "󰖁"
        if (sink.audio.volume > 0.6) return "󰕾"
        if (sink.audio.volume > 0.2) return "󰖀"
        return "▍"
    }

    readonly property int pct: sink?.ready ? Math.round(sink.audio.volume * 100) : 0

    // ── Hover → show trigger state for AudioPopup hover-to-open ──────────────
    HoverHandler {
        id: hov
        onHoveredChanged: Popups.audioTriggerHovered = hovered
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: iconText
            text:           root.icon
            color:          hov.hovered ? Theme.active : Theme.text
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            text:           root.pct + "%"
            color:          hov.hovered ? Theme.active : Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            visible:        root.showPercentage || hov.hovered
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    // ── Left click — toggle popup ─────────────────────────────────────────────
    MouseArea {
        anchors.fill:        parent
        acceptedButtons:     Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // Right click — mute toggle, no popup
                if (root.sink?.ready)
                    root.sink.audio.muted = !root.sink.audio.muted
            } else {
                // Left click — toggle popup
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
            }
        }
    }
}

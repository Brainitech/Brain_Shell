import QtQuick
import Quickshell.Services.Pipewire
import "../../components"
import "../../"
import "../../theme"

Item {
    id: root

    property bool showPercentage: false

    implicitWidth:  row.implicitWidth + 6
    implicitHeight: row.implicitHeight

    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    readonly property string icon: {
        if (!sink?.ready)            return "󰕾"
        if (sink.audio.muted)        return "󰝟"
        if (sink.audio.volume > 0.6) return "󰕾"
        if (sink.audio.volume > 0.2) return "󰖀"
        return "󰕿"
    }

    readonly property int pct: sink?.ready ? Math.round(sink.audio.volume * 100) : 0

    HoverHandler {
        id: hov
    }

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

        Item {
            id: pctWrapper
            property bool show: root.showPercentage || hov.hovered
            implicitWidth: show ? pctText.implicitWidth + 2 : 0
            implicitHeight: pctText.implicitHeight
            clip: true
            anchors.verticalCenter: parent.verticalCenter
            Behavior on implicitWidth { NumberAnimation { duration: Anim.standardNormal; easing: Anim.standard } }
        
            Text {
                id: pctText
                text:           root.pct + "%"
                color:          hov.hovered ? Theme.active : Theme.text
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }

    MouseArea {
        anchors.fill:        parent
        acceptedButtons:     Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (root.sink?.ready)
                    root.sink.audio.muted = !root.sink.audio.muted
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
            }
        }
    }
}

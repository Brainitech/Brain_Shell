import QtQuick
import Quickshell
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupWidth:  Math.round(420 * root.localScale)
    readonly property int popupHeight: Math.round(560 * root.localScale)
        



    

    // ── Content ────────────────────────────────────────────
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.popupWidth
        height: root.popupHeight

        Item {
            anchors.fill: parent

            opacity: (SurfaceState.activeContent === "clipboard") ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic } }
            onOpacityChanged: {
                if (opacity === 1) historyTab.grabFocus()
            }

            TapHandler {
                onTapped: {
                    SurfaceState.open("bottomRight", "clipboard")
                    Popups.clipboardPinned = true
                }
            }

            HistoryTab {
                id: historyTab
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.localScale)
                localScale: root.localScale
            }
        }
    }
}
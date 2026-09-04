import QtQuick
import Quickshell
import "../services"
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

        
    readonly property var pageHeights: ({
        "power":       Math.round(270 * root.localScale),
        "performance": Math.round(190 * root.localScale),
        "stats":       Math.round(250 * root.localScale)
    })
    readonly property var pageWidths: ({
        "power":       Math.round(220 * root.localScale),
        "performance": Math.round(260 * root.localScale),
        "stats":       Math.round(390 * root.localScale)
    })

    readonly property int contentWidth:  pageWidths[page]  ?? Math.round(220 * root.localScale)
    readonly property int contentHeight: pageHeights[page] ?? Math.round(220 * root.localScale)

    readonly property int targetWidth: contentWidth
    readonly property int targetHeight: contentHeight
    readonly property int popupWidth: targetWidth
    readonly property int popupHeight: targetHeight

    property string page: "power"

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()
    MouseArea {
        anchors.fill: parent
        onClicked: Popups.archMenuPinned = true
    }

    Item {
        id: slide
        anchors.fill: parent
        clip: true

        Item {
            anchors {
                fill:         parent
                leftMargin:   Math.round(8 * root.localScale)
                rightMargin:  Math.round(8 * root.localScale)
                topMargin:    Math.round(8 * root.localScale)
                bottomMargin: Math.round(8 * root.localScale)
            }
            
            //── Page content ──────────────────────────────────────────
            Item {
                anchors.centerIn: parent
                width:  root.contentWidth - Math.round(16 * root.localScale)
                height: root.contentHeight - Math.round(16 * root.localScale)
                clip:   true

                PopupPage {
                    anchors.fill: parent
                    visible: root.page === "power"

                    PowerMenu {
                        localScale: root.localScale
                        width: parent.width
                    }
                }
            }
        }
    }
}

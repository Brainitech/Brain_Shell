import QtQuick
import "../../components"
import "../../"

Item {
    id: root
    property real localScale: 1.0
    height: parent.height

    // The TopBar State handles expanding the notch for notifications/network/toasts
    implicitWidth: contentRow.implicitWidth

    implicitHeight: parent.height

    // ── Normal content — fades out when any right popup opens ─────────────────
    Row {
        id: contentRow
        anchors.right: parent.right
        anchors.rightMargin: SurfaceState.isRightExpanded ? Math.round(-20 * localScale) : 0
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: Math.round(6 * localScale)

        opacity: SurfaceState.isRightExpanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }
        Behavior on anchors.rightMargin { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }

        Network{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Audio{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Battery{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Clock{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        SysTray{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Notifications{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

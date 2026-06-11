import QtQuick
import Quickshell
import Quickshell.Wayland
import "../shapes"
import "../theme"

/*!
    ScreenCorners.qml — rounded screen corner masks.
    Uses 4 tiny PanelWindows (one per corner) at WlrLayer.Overlay.
    Each window is only cornerRadius × cornerRadius pixels, so clicks
    pass through normally everywhere except the actual corner area.
*/
Item {
    id: root

    // Accept screen from Variants delegate without being a PanelWindow itself
    property var screen: null

    readonly property int cornerRadius: Theme.cornerRadius
    readonly property color fillColor: Theme.background

    PanelWindow {
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "brain-shell:corners-tl"
        WlrLayershell.layer: WlrLayer.Overlay
        implicitWidth: cornerRadius; implicitHeight: cornerRadius
        anchors { top: true; left: true }
        RoundCorner {
            anchors.fill: parent
            size: cornerRadius
            maskColor: fillColor
            corner: RoundCorner.Corner.TopLeft
        }
    }

    PanelWindow {
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "brain-shell:corners-tr"
        WlrLayershell.layer: WlrLayer.Overlay
        implicitWidth: cornerRadius; implicitHeight: cornerRadius
        anchors { top: true; right: true }
        RoundCorner {
            anchors.fill: parent
            size: cornerRadius
            maskColor: fillColor
            corner: RoundCorner.Corner.TopRight
        }
    }

    PanelWindow {
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "brain-shell:corners-bl"
        WlrLayershell.layer: WlrLayer.Overlay
        implicitWidth: cornerRadius; implicitHeight: cornerRadius
        anchors { bottom: true; left: true }
        RoundCorner {
            anchors.fill: parent
            size: cornerRadius
            maskColor: fillColor
            corner: RoundCorner.Corner.BottomLeft
        }
    }

    PanelWindow {
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "brain-shell:corners-br"
        WlrLayershell.layer: WlrLayer.Overlay
        implicitWidth: cornerRadius; implicitHeight: cornerRadius
        anchors { bottom: true; right: true }
        RoundCorner {
            anchors.fill: parent
            size: cornerRadius
            maskColor: fillColor
            corner: RoundCorner.Corner.BottomRight
        }
    }
}

import QtQuick
import "../theme"

/*!
    Surface — Material 3 elevated surface wrapper.

    Wraps content with a StyledRect at a given elevation level.
    Elevation maps to background opacity + subtle shadow.

    Usage:
        Surface {
            elevation: 1
            width: 200; height: 100
            Text { anchors.centerIn: parent; text: "Hello" }
        }
*/
Item {
    id: root

    // Elevation 0-4 per M3 spec
    property int elevation: 0
    property string variant: "surface"
    property bool enableBorder: true

    readonly property real _elevationOpacity: {
        switch (elevation) {
            case 0: return 0.0;
            case 1: return 0.05;
            case 2: return 0.08;
            case 3: return 0.11;
            case 4: return 0.14;
            default: return 0.0;
        }
    }

    StyledRect {
        id: bg
        anchors.fill: parent
        variant: root.variant
        enableBorder: root.enableBorder
        backgroundOpacity: root._elevationOpacity > 0 ? root._elevationOpacity : -1
    }
}

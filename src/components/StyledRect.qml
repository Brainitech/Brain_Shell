import QtQuick
import Quickshell.Widgets
import "../theme"

/*!
    StyledRect — themed container with Material 3-inspired variants.

    Replaces the repeated Rectangle pattern across Brain_Shell:
        Rectangle { radius: 9; color: Qt.rgba(1,1,1,0.06); border... }

    Usage:
        StyledRect {
            variant: "popup"
            anchors.fill: parent
            // children go here
        }

    Variants: "transparent", "bg", "popup", "focus", "primary", "secondary",
              "error", "surface", "surfaceVariant", "bar"
*/
ClippingRectangle {
    id: root

    required property string variant

    property bool enableBorder: true
    property real backgroundOpacity: -1  // -1 = use variant default

    antialiasing: true
    clip: true

    readonly property var _config: {
        switch (variant) {
            case "transparent": return { color: "transparent", border: "transparent", opacity: 0 };
            case "bg":          return { color: Theme.background, border: Theme.border, opacity: 1.0 };
            case "popup":       return { color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.98), border: Qt.rgba(1,1,1,0.12), opacity: 1.0 };
            case "focus":       return { color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14), border: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35), opacity: 1.0 };
            case "primary":     return { color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18), border: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30), opacity: 1.0 };
            case "secondary":   return { color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.15), border: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.25), opacity: 1.0 };
            case "error":       return { color: Qt.rgba(0.957, 0.263, 0.416, 0.15), border: Qt.rgba(0.957, 0.263, 0.416, 0.35), opacity: 1.0 };
            case "surface":     return { color: Qt.rgba(1,1,1,0.06), border: Qt.rgba(1,1,1,0.10), opacity: 1.0 };
            case "surfaceVariant": return { color: Qt.rgba(1,1,1,0.04), border: Qt.rgba(1,1,1,0.08), opacity: 1.0 };
            case "bar":         return { color: Theme.background, border: "transparent", opacity: 1.0 };
            default:            return { color: Theme.background, border: Qt.rgba(1,1,1,0.10), opacity: 1.0 };
        }
    }

    color: _config.color
    radius: Theme.cornerRadius
    border.color: enableBorder ? _config.border : "transparent"
    border.width: enableBorder ? 1 : 0
    opacity: backgroundOpacity >= 0 ? backgroundOpacity : _config.opacity

    Behavior on color {
        enabled: Anim.animationsEnabled
        ColorAnimation { duration: Anim.standardSmall }
    }
    Behavior on border.color {
        enabled: Anim.animationsEnabled
        ColorAnimation { duration: Anim.standardSmall }
    }
    Behavior on opacity {
        enabled: Anim.animationsEnabled
        NumberAnimation { duration: Anim.standardSmall; easing.type: Anim.easing("standard").type }
    }
}

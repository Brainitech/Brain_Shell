pragma Singleton
import QtQuick
import "../"
import "."

QtObject {
    id: root

    // ── Color loader — watches matugen output and updates live ────────────────
    // Use a unique ID to avoid namespace collision with the 'Colors' singleton
    property var _loader: ColorLoader {
        id: internalLoader
        overrideMode: PrefsService.dynamicThemeOverride
    }

    // ── Colors — bound to loader, update automatically when matugen runs ──────
    property color background: Qt.rgba(internalLoader.background.r, internalLoader.background.g, internalLoader.background.b, PrefsService.bgOpacity)
    property color active:     internalLoader.active
    property color text:       internalLoader.text
    property color subtext:    internalLoader.subtext
    property color icon:       internalLoader.icon
    property color border:     internalLoader.border
    property color iconFont:   internalLoader.iconFont

    // --- Workspace Visuals ---
    property color wsBackground: "#20000000"
    property color wsActive:     text
    property color wsOccupied:   Qt.rgba(text.r, text.g, text.b, 0.7)
    property color wsEmpty:      Qt.rgba(text.r, text.g, text.b, 0.25)
    property color wsOverlay:    Qt.rgba(background.r, background.g, background.b, 0.85)
    property color wsUrgent:     "#fa6b94" //active
}

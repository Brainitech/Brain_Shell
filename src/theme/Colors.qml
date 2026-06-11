pragma Singleton
import QtQuick
import "."

QtObject {
    id: root

    // ── Color loader — watches matugen output and updates live ────────────────
    // Use a unique ID to avoid namespace collision with the 'Colors' singleton
    property var _loader: ColorLoader { id: internalLoader }

    // ── Colors — bound to loader, update automatically when matugen runs ──────
    property color background: internalLoader.background
    property color active:     internalLoader.active
    property color text:       internalLoader.text
    property color subtext:    internalLoader.subtext
    property color icon:       internalLoader.icon
    property color border:     internalLoader.border
    property color iconFont:   internalLoader.iconFont

    // --- Workspace Visuals ---
    property color wsBackground: "#20000000"
    property color wsActive:     "#FFFFFF"
    property color wsOccupied:   "#80FFFFFF"
    property color wsEmpty:      "#30FFFFFF"
    property color wsOverlay:    "#CC1e1e2e"
    property color wsUrgent:     "#fa6b94"
}

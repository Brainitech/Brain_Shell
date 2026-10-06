/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
    property color error:      PrefsService.darkMode ? "#f87171" : "#cc0000"
    property color errorSolid: "#d9534f"
    property color card:       PrefsService.darkMode ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(0, 0, 0, 0.045)
    property color cardHover:  PrefsService.darkMode ? Qt.rgba(1, 1, 1, 0.085) : Qt.rgba(0, 0, 0, 0.085)

    // Network stats rate colors
    readonly property color netUpload:   PrefsService.darkMode ? "#90ef90" : "#15803d"
    readonly property color netDownload: PrefsService.darkMode ? "#a6d0f7" : "#1d4ed8"

    // --- Workspace Visuals ---
    property color wsBackground: "#20000000"
    property color wsActive:     text
    property color wsOccupied:   Qt.rgba(text.r, text.g, text.b, 0.7)
    property color wsEmpty:      Qt.rgba(text.r, text.g, text.b, 0.25)
    property color wsOverlay:    Qt.rgba(background.r, background.g, background.b, 0.85)
    property color wsUrgent:     "#fa6b94" //active
}

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

import QtQuick
import Quickshell
import "../../"

Rectangle {
    id: root

    property real localScale: 1.0

    readonly property string sym: PrefsService.wsSymbols || "none"
    readonly property string symStyle: (PrefsService.wsSymbolStyle === "badges") ? "badges" : "floating"

    readonly property real baseItemHeight: (sym === "none")
        ? Math.round(Theme.wsDotSize * localScale)
        : (symStyle === "badges" ? Math.round(16 * localScale) : Math.round(18 * localScale))

    readonly property real actualPadding: (sym === "none")
        ? Math.round(Theme.wsPadding * localScale)
        : Math.round(4 * localScale)

    readonly property real actualSpacing: (sym === "none")
        ? Math.round(Theme.wsSpacing * localScale)
        : Math.round(4 * localScale)

    // High-contrast text calculation against dynamic theme colors
    function getContrastColor(bg, isSubtle) {
        if (!bg) return "#f5f7fa"
        var lum = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b
        if (isSubtle) {
            return lum > 0.55 ? "#40454f" : "#cbd3df"
        }
        return lum > 0.55 ? "#101216" : "#ffffff"
    }

    // --- 1. Capsule Container ---
    color: (PrefsService.wsShowCapsule !== false) ? Theme.wsBackground : "transparent"
    radius: Math.round(Theme.wsRadius * localScale)

    Behavior on color { ColorAnimation { duration: Anim.normal } }

    // Auto-size
    width: workspaceRow.width + Math.round(root.actualPadding * 2)
    height: Math.round(root.baseItemHeight) + Math.round(root.actualPadding * 2)

    // --- 2. State & Scroll Cooldown ---
    readonly property bool isScratchpad: WM.isScratchpad
    property bool scrollBusy: false

    Timer {
        id: scrollCooldown
        interval: 300
        repeat: false
        onTriggered: root.scrollBusy = false
    }

    // --- Dynamic vs Static length model ---
    readonly property var workspaceList: {
        var isNiri = WM.detectedCompositor === "Niri"
        var mode = isNiri ? "dynamic" : (PrefsService.wsMode || "static")
        if (mode === "occupied") {
            var rawWs = WM.workspaces || []
            var ids = []
            for (var i = 0; i < rawWs.length; i++) {
                var wid = rawWs[i] ? rawWs[i].id : 0
                if (wid > 0 && ids.indexOf(wid) === -1) {
                    ids.push(wid)
                }
            }
            var focused = WM.focusedWorkspaceId
            if (focused > 0 && ids.indexOf(focused) === -1) {
                ids.push(focused)
            }
            ids.sort(function(a, b) { return a - b })
            return ids.length > 0 ? ids : [1]
        } else if (mode === "dynamic") {
            var rawWsDyn = WM.workspaces || []
            var maxId = Math.max(WM.focusedWorkspaceId || 1, 1)
            for (var j = 0; j < rawWsDyn.length; j++) {
                var dId = rawWsDyn[j] ? rawWsDyn[j].id : 0
                if (typeof dId === "number" && dId > maxId) {
                    maxId = dId
                }
            }
            var dynList = []
            for (var k = 1; k <= maxId; k++) {
                dynList.push(k)
            }
            return dynList
        } else {
            var count = Math.max(1, PrefsService.wsCount || 10)
            var staticList = []
            for (var m = 1; m <= count; m++) {
                staticList.push(m)
            }
            return staticList
        }
    }

    // --- Symbol mapping function ---
    function getSymbol(id) {
        var s = PrefsService.wsSymbols || "none"
        if (s === "numbers") {
            return id.toString()
        } else if (s === "kanji") {
            var kanji = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
            return kanji[id - 1] || id.toString()
        } else if (s === "roman") {
            var roman = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
            return roman[id - 1] || id.toString()
        } else if (s === "icons") {
            var icons = ["󰎤", "󰎧", "󰎪", "󰎭", "󰎱", "󰎳", "󰎶", "󰎹", "󰎼", "󰎿"]
            return icons[id - 1] || "󰍹"
        }
        return ""
    }

    // --- Wheel: cycle through workspaces ---
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (root.scrollBusy) return
            root.scrollBusy = true
            scrollCooldown.restart()
            var dir = (event.angleDelta.y < 0 ? 1 : -1) * (PrefsService.wsInvertScroll ? -1 : 1)
            WM.cycleWorkspace(dir)
        }
    }

    // --- 3. Workspace Indicators ---
    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Math.round(root.actualSpacing)

        // Logic: Fade out dots when Scratchpad is active
        opacity: root.isScratchpad ? 0 : 1
        scale:   root.isScratchpad ? 0.8 : 1
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        Behavior on scale   { NumberAnimation { duration: Anim.normal } }

        Repeater {
            model: root.workspaceList
            delegate: Rectangle {
                id: dot

                readonly property int wsId: modelData
                property var ws: (WM.workspaces || []).find(w => w.id === wsId)
                property bool isActive: WM.focusedWorkspaceId === wsId
                property bool isOccupied: ws !== undefined
                property bool isUrgent:   ws !== undefined && !!ws.urgent

                readonly property string shape: PrefsService.wsShape || "circle"

                height: Math.round(root.baseItemHeight)

                radius: {
                    if (shape === "square") return 0
                    if (shape === "rounded" || root.symStyle === "badges") return Math.round(4 * root.localScale)
                    return height / 2
                }

                width: {
                    // ── Case 1: Pure Geometric Shapes (No Symbols) ──
                    if (root.sym === "none") {
                        if (dot.shape === "circle") {
                            return dot.isActive ? Math.round(Theme.wsActiveWidth * root.localScale) : height
                        } else if (dot.shape === "pill") {
                            var inactivePill = Math.round(height * 1.6)
                            return dot.isActive ? Math.round(Theme.wsActiveWidth * root.localScale) : inactivePill
                        } else if (dot.shape === "rounded") {
                            var inactiveRounded = Math.round(height * 1.3)
                            return dot.isActive ? Math.round(Theme.wsActiveWidth * root.localScale) : inactiveRounded
                        } else if (dot.shape === "square") {
                            return dot.isActive ? Math.round(Theme.wsActiveWidth * root.localScale) : height
                        }
                        return dot.isActive ? Math.round(Theme.wsActiveWidth * root.localScale) : height
                    }

                    // ── Case 2: Floating Text ──
                    if (root.symStyle === "floating") {
                        if (dot.isActive) {
                            return Math.max(Math.round(22 * root.localScale), Math.round(symbolText.implicitWidth + 12 * root.localScale))
                        }
                        return Math.max(Math.round(16 * root.localScale), Math.round(symbolText.implicitWidth + 8 * root.localScale))
                    }

                    // ── Case 3: Badges ──
                    if (dot.isActive) {
                        return Math.max(Math.round(22 * root.localScale), Math.round(symbolText.implicitWidth + 10 * root.localScale))
                    }
                    return Math.max(height, Math.round(symbolText.implicitWidth + 6 * root.localScale))
                }

                color: {
                    if (root.sym !== "none" && root.symStyle === "floating" && !dot.isActive) {
                        return "transparent"
                    }
                    if (dot.isActive)   return Theme.wsActive
                    if (dot.isUrgent)   return Theme.wsUrgent
                    if (dot.isOccupied) return Theme.wsOccupied
                    return Theme.wsEmpty
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Anim.normal
                        easing.type: Anim.outBack
                        easing.overshoot: Anim.globalOvershoot
                        easing.amplitude: Anim.globalAmplitude
                        easing.period: Anim.globalPeriod
                    }
                }
                Behavior on color { ColorAnimation { duration: Anim.normal } }

                Text {
                    id: symbolText
                    anchors.centerIn: parent
                    text: root.getSymbol(dot.wsId)
                    renderType: Text.NativeRendering
                    visible: root.sym !== "none" && text !== ""
                    font.pixelSize: {
                        if (root.symStyle === "floating") return Math.max(10, Math.round(11 * root.localScale))
                        return Math.max(9, Math.round(10 * root.localScale))
                    }
                    font.bold: dot.isActive

                    color: {
                        if (root.symStyle === "floating" && !dot.isActive) {
                            if (dot.isUrgent)   return Theme.wsUrgent
                            if (dot.isOccupied) return Theme.text
                            return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                        }
                        if (dot.isActive)   return root.getContrastColor(Theme.wsActive, false)
                        if (dot.isUrgent)   return root.getContrastColor(Theme.wsUrgent, false)
                        if (dot.isOccupied) return root.getContrastColor(Theme.wsOccupied, false)
                        return root.getContrastColor(Theme.wsEmpty, true)
                    }

                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                }

                // --- Urgent pulse ---
                SequentialAnimation {
                    running: dot.isUrgent && !dot.isActive
                    loops:   Animation.Infinite

                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.35
                        duration: Anim.slower
                        easing.type: Anim.inOutSine
                    }
                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.0
                        duration: Anim.slower
                        easing.type: Anim.inOutSine
                    }
                }

                // Reset scale when no longer urgent or active
                onIsUrgentChanged: {
                    if (!isUrgent) scale = 1.0
                }
                onIsActiveChanged: {
                    if (isActive) scale = 1.0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WM.switchWorkspace(dot.wsId)
                }
            }
        }
    }

    // --- 4. Scratchpad Overlay ---
    Rectangle {
        id: overlay
        anchors.fill: parent
        radius: root.radius
        color: Theme.wsOverlay
        z: 99

        // Logic: Fade in overlay when Scratchpad is active
        visible: opacity > 0
        opacity: root.isScratchpad ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Anim.normal } }

        Text {
            anchors.centerIn: parent
            text: ""
            color: Theme.text
            font.pixelSize: Math.round(14 * root.localScale)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: WM.toggleScratchpad("magic")
        }
    }
}

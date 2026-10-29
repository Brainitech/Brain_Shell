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
import Quickshell
import "../../"

Item {
    id: root

    // ── Compositor Detection ───────────────────────────────────────────────────
    function _hasEnv(name) {
        var val = Quickshell.env(name)
        return typeof val === "string" && val.trim() !== ""
    }

    readonly property string detectedCompositor: {
        var forced = Quickshell.env("BRAIN_SHELL_WM")
        if (typeof forced === "string" && forced.trim() !== "") {
            var f = forced.trim().toLowerCase()
            if (f === "niri") return "Niri"
            if (f === "sway") return "Sway"
            if (f === "hyprland") return "Hyprland"
            return forced
        }
        if (root._hasEnv("NIRI_SOCKET")) return "Niri"
        if (root._hasEnv("SWAYSOCK")) return "Sway"
        if (root._hasEnv("HYPRLAND_INSTANCE_SIGNATURE")) return "Hyprland"
        var desk = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toString().toLowerCase()
        if (desk.indexOf("niri") !== -1) return "Niri"
        if (desk.indexOf("sway") !== -1) return "Sway"
        if (desk.indexOf("hyprland") !== -1) return "Hyprland"
        return "Hyprland"
    }

    // ── Backend Provider ──────────────────────────────────────────────────────
    Loader {
        id: backendLoader
        source: root.detectedCompositor === "Niri" ? "NiriBackend.qml" : "HyprlandBackend.qml"
    }

    readonly property var backend: backendLoader.item

    // ── Identity ──────────────────────────────────────────────────────────────
    readonly property string name: backend ? backend.name : "Unknown"
    readonly property bool isSupported: backend ? backend.isSupported : false
    readonly property string configProvider: backend ? backend.configProvider : "conf"

    Component.onCompleted: {
        console.log("[WM] Compositor detected:", root.detectedCompositor, "| Backend:", root.name, "| Supported:", root.isSupported)
    }

    // ── Signals ───────────────────────────────────────────────────────────────
    signal activeWindowChanged(string title, string initialTitle, string windowClass)
    signal workspaceChanged()
    signal scratchpadChanged(bool active)
    signal dismissRequested()
    signal configReloaded()

    Connections {
        target: root.backend
        function onActiveWindowChanged(title, initialTitle, windowClass) {
            root.activeWindowChanged(title, initialTitle, windowClass)
        }
        function onWorkspaceChanged() {
            root.workspaceChanged()
        }
        function onScratchpadChanged(active) {
            root.scratchpadChanged(active)
        }
        function onDismissRequested() {
            root.dismissRequested()
        }
        function onConfigReloaded() {
            root.configReloaded()
        }
    }

    // ── Monitors & Displays ───────────────────────────────────────────────────
    readonly property string focusedMonitorName: backend ? backend.focusedMonitorName : ""

    // ── Screen & Window Picking ───────────────────────────────────────────────
    function pickWindowCommand() {
        return backend ? backend.pickWindowCommand() : ""
    }

    function pickRegionCommand() {
        return backend ? backend.pickRegionCommand() : ""
    }

    // ── Workspaces ────────────────────────────────────────────────────────────
    readonly property var workspaces: (backend && backend.workspaces) ? backend.workspaces : []
    readonly property var focusedWorkspace: backend ? backend.focusedWorkspace : null
    readonly property int focusedWorkspaceId: backend ? backend.focusedWorkspaceId : 1
    readonly property bool isScratchpad: backend ? backend.isScratchpad : false

    function switchWorkspace(id, isSpecialToggle = false) {
        if (backend) backend.switchWorkspace(id, isSpecialToggle)
    }

    function toggleScratchpad(name = "magic") {
        if (backend) backend.toggleScratchpad(name)
    }

    function cycleWorkspace(direction = 1) {
        if (backend) backend.cycleWorkspace(direction)
    }

    // ── Window Tracking ───────────────────────────────────────────────────────
    readonly property string activeTitle: backend ? backend.activeTitle : ""
    readonly property string activeInitialTitle: backend ? backend.activeInitialTitle : ""
    readonly property string activeClass: backend ? backend.activeClass : ""

    function refreshActiveWindow() {
        if (backend) backend.refreshActiveWindow()
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    readonly property var availableLayouts: backend ? backend.availableLayouts : []
    readonly property string currentLayout: backend ? backend.currentLayout : ""
    readonly property string numWindows: backend ? backend.numWindows : ""

    function setLayout(name) {
        if (backend) backend.setLayout(name)
    }

    function cycleLayout(step = 1) {
        if (backend) backend.cycleLayout(step)
    }

    function refreshLayout() {
        if (backend) backend.refreshLayout()
    }

    function toggleOverview() {
        if (backend && backend.toggleOverview) backend.toggleOverview()
    }

    // ── Appearance ────────────────────────────────────────────────────────────
    function setActiveBorderColor(color) {
        if (backend) backend.setActiveBorderColor(color)
    }

    function setLayerBlur(namespace, enabled, alpha = 0.1) {
        if (backend) backend.setLayerBlur(namespace, enabled, alpha)
    }

    // ── Night Light ───────────────────────────────────────────────────────────
    readonly property bool nightLightOn: backend ? backend.nightLightOn : false

    function setNightLight(enabled, temp = "5600") {
        if (backend) backend.setNightLight(enabled, temp)
    }

    function toggleNightLight(temp = "5600") {
        if (backend) backend.toggleNightLight(temp)
    }

    function checkNightLight() {
        if (backend) backend.checkNightLight()
    }

    // ── Displays & Gaps ───────────────────────────────────────────────────────
    function powerCycleDisplays() {
        if (backend) backend.powerCycleDisplays()
    }

    readonly property int gapsIn: backend ? backend.gapsIn : 5
    readonly property int gapsOut: backend ? backend.gapsOut : 10

    function setGaps(inVal, outVal) {
        if (backend) backend.setGaps(inVal, outVal)
    }

    // ── Screen Shader ─────────────────────────────────────────────────────────
    readonly property string defaultShaderPaths: (backend && backend.defaultShaderPaths) ? backend.defaultShaderPaths : (Paths.configDir + "/shaders")
    readonly property string currentScreenShader: backend ? backend.currentScreenShader : ""

    function checkScreenShader() {
        if (backend) backend.checkScreenShader()
    }

    function setScreenShader(name, shaderPaths) {
        if (backend) backend.setScreenShader(name, shaderPaths)
    }

    // ── Keybinds ──────────────────────────────────────────────────────────────
    function setKeybindCaptureSubmap(enabled) {
        if (backend) backend.setKeybindCaptureSubmap(enabled)
    }

    function focusUrgentOrLast() {
        if (backend) backend.focusUrgentOrLast()
    }

    readonly property var rawKeybinds: backend ? backend.rawKeybinds : []

    function loadRawKeybinds() {
        if (backend) backend.loadRawKeybinds()
    }

    function wouldConflictCompositor(action, mods, key) {
        return backend ? backend.wouldConflictCompositor(action, mods, key) : ""
    }

    function writeKeybindFiles(keybinds) {
        if (backend) backend.writeKeybindFiles(keybinds)
    }

    function reloadConfig() {
        if (backend) backend.reloadConfig()
    }

    // ── Lock Screen ───────────────────────────────────────────────────────────
    function lockScreen() {
        if (backend) backend.lockScreen()
    }
}

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
import Quickshell.Io
import "wm"

QtObject {
    id: root

    property bool nightLightOn: false

    readonly property string backendBinary: {
        return (WM.currentCompositor === "Hyprland") ? "hyprsunset" : "wlsunset"
    }

    property Process nlCheckProc: Process {
        command: ["bash", "-c", "pgrep -x hyprsunset || pgrep -x wlsunset"]
        running: false
        onExited: function(code) {
            root.nightLightOn = (code === 0)
        }
    }

    property Process nlProc: Process {
        command: []
        running: false
    }

    property Process nlKillProc: Process {
        command: ["bash", "-c", "pkill -x hyprsunset || pkill -x wlsunset"]
        running: false
        onExited: function(code) {
            root.nightLightOn = false
        }
    }

    function checkNightLight() {
        nlCheckProc.running = false
        nlCheckProc.running = true
    }

    function setNightLight(enabled, temp = "5600") {
        if (enabled) {
            nlProc.command = [root.backendBinary, "-t", String(temp)]
            nlProc.running = false
            nlProc.running = true
            root.nightLightOn = true
        } else {
            nlKillProc.running = false
            nlKillProc.running = true
            root.nightLightOn = false
        }
    }

    function toggleNightLight(temp = "5600") {
        setNightLight(!root.nightLightOn, temp)
    }

    Component.onCompleted: {
        checkNightLight()
    }
}

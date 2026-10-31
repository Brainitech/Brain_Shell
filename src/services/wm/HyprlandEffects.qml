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
import Quickshell.Io
import "../../"

Item {
    id: root

    property bool isSupported: true

    // ── Layer Blur ────────────────────────────────────────────────────────────
    property Process blurProc: Process {
        command: []
        running: false
    }

    function setLayerBlur(namespace, enabled, alpha = 0.1) {
        if (!root.isSupported) return
        blurProc.command = enabled
            ? ["hyprctl", "eval", `hl.layer_rule({ match = { namespace = '${namespace}' }, blur = true, ignore_alpha = ${alpha} })`]
            : ["hyprctl", "eval", `hl.layer_rule({ match = { namespace = '${namespace}' }, blur = false })`]
        blurProc.running = false
        blurProc.running = true
    }

    // ── Screen Shader ─────────────────────────────────────────────────────────
    readonly property string defaultShaderPaths: Paths.configDir + "/shaders " + Paths.userDataDir + "/shaders ~/.config/hypr/shaders ~/.local/share/hypr/shaders /usr/share/hyprshade/shaders"
    property string currentScreenShader: ""

    property Process shaderCheckProc: Process {
        command: [
            "bash", "-c",
            "hyprctl getoption decoration:screen_shader -j 2>/dev/null | python3 -c \"" +
            "import sys,json,os; d=json.load(sys.stdin); " +
            "s=d.get('str','').strip(); print('' if s in ('','[[EMPTY]]') else os.path.splitext(os.path.basename(s))[0])\""
        ]
        running: false
        stdout: StdioCollector {
            id: shaderCollector
            onStreamFinished: {
                root.currentScreenShader = shaderCollector.text.trim()
            }
        }
    }

    function checkScreenShader() {
        if (!shaderCheckProc.running) shaderCheckProc.running = true
    }

    property Process shaderApplyProc: Process {
        running: false
        onExited: function() {
            root.checkScreenShader()
        }
    }

    function setScreenShader(name, shaderPaths) {
        var damageCmd = " && hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })' && hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"

        if (!name || name === "" || name === root.currentScreenShader) {
            var offCmd = "hyprctl eval \"hl.config({ decoration = { screen_shader = '' } })\""
            shaderApplyProc.command = ["bash", "-c", offCmd + damageCmd]
            root.currentScreenShader = ""
        } else {
            var resolveCmd =
                "TARGET=$(find " + shaderPaths +
                " -maxdepth 1 -type f \\( -name '" + name + ".glsl' -o -name '" + name + ".frag' \\)" +
                " 2>/dev/null | head -n 1); "
            var onCmd = "if [ -n \"$TARGET\" ]; then hyprctl eval \"hl.config({ decoration = { screen_shader = '$TARGET' } })\"" + damageCmd + "; fi"
            shaderApplyProc.command = ["bash", "-c", resolveCmd + onCmd]
            root.currentScreenShader = name
        }
        shaderApplyProc.running = false
        shaderApplyProc.running = true
    }

    Component.onCompleted: {
        if (root.isSupported) {
            root.checkScreenShader()
        }
    }
}

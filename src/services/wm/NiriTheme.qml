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
import "../../utils"

Item {
    id: root

    property bool isSupported: true
    property int gapsOut: 10
    property string activeBorderColor: "#bec8ce"

    property Process themeWriteProc: Process {
        running: false
    }

    function writeNiriTheme() {
        if (!root.isSupported) return
        var themePath = Paths.configDir + "/BrainShell-niri-theme.kdl"
        var kdl = "layout {\n" +
                  "    gaps " + root.gapsOut + "\n" +
                  "    border {\n" +
                  "        active-color \"" + root.activeBorderColor + "\"\n" +
                  "    }\n" +
                  "    focus-ring {\n" +
                  "        active-color \"" + root.activeBorderColor + "\"\n" +
                  "    }\n" +
                  "}\n"
        var escaped = kdl.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        themeWriteProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + themePath + "')\" && " +
            "printf '%s' '" + escaped + "' > '" + themePath + "' && " +
            "(niri msg action load-config-file 2>/dev/null || true)"
        ]
        themeWriteProc.running = false
        themeWriteProc.running = true
    }

    function setActiveBorderColor(color) {
        if (!color || !root.isSupported) return
        var hex = String(color).trim()
        if (hex.charAt(0) !== "#") hex = "#" + hex
        root.activeBorderColor = hex
        writeNiriTheme()
    }
}

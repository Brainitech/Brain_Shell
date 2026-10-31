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

Item {
    id: root

    property bool isSupported: true

    property Process actionProc: Process {
        command: []
        running: false
    }

    function setActiveBorderColor(color) {
        if (!root.isSupported || !color) return
        let cleanCol = String(color).replace('#', '')
        actionProc.command = [
            "bash", "-c",
            "hyprctl eval 'hl.config({ general = { [\"col.active_border\"] = { colors = { \"rgb(" + cleanCol + ")\" } } } })'"
        ]
        actionProc.running = false
        actionProc.running = true
    }
}

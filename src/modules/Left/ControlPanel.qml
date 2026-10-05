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
import "../../components"
import "../../"

IconBtn {
    id: rootBtn
    text: ""
    textColor: "#1793d1"

    Process {
        id: osProcess
        command: ["bash", "-c", "source /etc/os-release && echo $ID"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let osId = text.trim().toLowerCase()
                let defaultSize = Math.round(16 * rootBtn.localScale)
                let smallSize = Math.round(14 * rootBtn.localScale)

                if (osId === "arch") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#1793d1"
                    rootBtn.fontSize = smallSize
                } else if (osId === "nixos") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#5277C3"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "manjaro") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#35bf5c"
                    rootBtn.fontSize = smallSize
                } else if (osId === "garuda") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#f94416"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "endeavouros") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#7f71ad"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "cachyos") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#00fde8"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "artix") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#00fde8"
                    rootBtn.fontSize = smallSize 
                } else {
                    rootBtn.text = ""
                    rootBtn.textColor = "#dfe7ec"
                    rootBtn.fontSize = defaultSize
                }
            }
        }
    }

    onClicked: {
        if (!Popups.archMenuOpen) {
            SurfaceState.open("leftCenter", "archMenu")
            Popups.archMenuPinned = true
        } else {
            SurfaceState.close()
        }
    }
}

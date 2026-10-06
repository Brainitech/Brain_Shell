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
import Quickshell.Io
import Quickshell

QtObject {
    id: root
    
    property int brightness: 0
    signal externalBrightnessChanged(int val)
    
    function setBrightness(v) {
        if (v < 1) v = 1
        brightWrite.command = ["brightnessctl", "set", v + "%"]
        brightWrite.running = true
        root.brightness = v
    }
    
    property var brightRead: Process {
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(',')
                if (parts.length >= 4) {
                    var pctStr = parts[3]
                    var val = parseInt(pctStr.replace('%', ''))
                    if (!isNaN(val)) {
                        if (root.brightness !== val) {
                            root.brightness = val
                            root.externalBrightnessChanged(val)
                        }
                    }
                }
            }
        }
    }
    
    property var brightWrite: Process {
        command: []
        running: false
        onRunningChanged: if (!running) root.brightRead.running = true
    }
    
    property var pollTimer: Timer {
        interval: 200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!brightWrite.running) {
                root.brightRead.running = false
                root.brightRead.running = true
            }
        }
    }
}

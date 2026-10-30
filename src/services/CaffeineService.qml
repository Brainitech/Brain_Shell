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

QtObject {
    id: root

    property bool caffeineOn: false

    property var caffeineCheck: Process {
        command: ["bash", "-c", "pgrep -f 'systemd-inhibit.*Caffeine'"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                if (l.trim() !== "") root.caffeineOn = true
            }
        }
    }

    property var caffeineProc: Process {
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Brain Shell", "--why=Caffeine mode", "sleep", "infinity"]
        running: false
    }

    property var caffeineKill: Process {
        command: ["bash", "-c", "pkill -f 'systemd-inhibit.*Caffeine'"]
        running: false
        onRunningChanged: if (!running) root.caffeineOn = false
    }

    function check() {
        caffeineCheck.running = false
        caffeineCheck.running = true
    }

    function toggle() {
        if (root.caffeineOn) {
            caffeineProc.running = false
            caffeineKill.running = false
            caffeineKill.running = true
        } else {
            caffeineProc.running = true
            root.caffeineOn = true
        }
    }

    property var pollTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Component.onCompleted: {
        root.check()
    }
}

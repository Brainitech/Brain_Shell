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
import "../state"
import "../"

Item {
    id: root

    property string _flagPath: Quickshell.env("HOME") + "/.config/Brain_Shell/.v0.2.0_migrated"
    property string _scriptPath: Quickshell.env("HOME") + "/.local/src/Brain_Shell/src/scripts/migrate_v0.2.0.sh"

    property bool isMigrating: false

    property bool isLegacyPath: Qt.resolvedUrl(".").toString().indexOf(".local/src/Brain_Shell") !== -1

    Process {
        id: checkerProc
        command: ["bash", "-c", "[ -f '" + root._flagPath + "' ]"]
        running: false
        onExited: function(code) {
            if (code !== 0) {
                root.isMigrating = true
                migratorProc.running = true
            }
        }
    }

    Process {
        id: migratorProc
        command: ["bash", root._scriptPath]
        running: false
        onExited: function(code) {
            root.isMigrating = false
            if (code === 0) {
                Popups.showConfirm(
                    "v0.2.0 Migration Complete",
                    "Your configuration was successfully backed up and migrated to the new v0.2.0 modular architecture.\n\nSince v0.2.0 was just installed, a system logout is strictly required to apply the new Hyprland configurations, or Brain Shell will not function correctly.",
                    "Logout Now",
                    "logout",
                    "", // gfxMode
                    "Quit Brain Shell",
                    "quit"
                )
            } else if (code === 2) {
                // Silently recovered flag
            } else {
                Popups.showConfirm(
                    "Migration Failed",
                    "The v0.2.0 migration script failed to execute properly. Please check the logs.",
                    "Quit Brain Shell",
                    "quit",
                    "",
                    "Ignore",
                    ""
                )
            }
        }
    }

    Component.onCompleted: {
        if (root.isLegacyPath) {
            checkerProc.running = true
        }
    }
}

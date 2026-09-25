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
            Popups.showConfirm(
                "v0.2.0 Migration Complete",
                "Your configuration was successfully backed up and migrated to the new v0.2.0 modular architecture.\n\nSince v0.2.0 was just installed, a system logout is strictly required to apply the new Hyprland configurations, or Brain Shell will not function correctly.",
                "Logout Now",
                "logout",
                "", // gfxMode
                "Quit Brain Shell",
                "quit"
            )
        }
    }

    Component.onCompleted: {
        checkerProc.running = true
    }
}

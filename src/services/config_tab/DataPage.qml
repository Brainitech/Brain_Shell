import Quickshell
import QtQuick
import Quickshell.Io
import "../../"
import "../../components"

Item {
    id: root
    property real localScale: 1.0

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + Math.round(40 * localScale)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: Math.round(32 * localScale)
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * localScale)

            // Group 1: Preferences
            SettingsGroup {
                localScale: root.localScale
                title: "Preferences"
                description: "Shell configuration and visual settings."

                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Shell Preferences"
                    description: "Wipe Brain_Shell preferences"
                    buttonText: "Wipe"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Reset Preferences?", "Are you sure you want to delete all preferences?", "Confirm", "reset_shell")
                    }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Wallpaper Preferences"
                    description: "Wipe customized wallpaper settings."
                    buttonText: "Wipe"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Reset Wallpaper Settings?", "Are you sure you want to delete wallpaper config?", "Confirm", "reset_wallpaper")
                    }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Profile Avatar"
                    description: "Clear custom avatar path."
                    buttonText: "Reset"
                    destructive: true
                    onClicked: {
                        PrefsService.customAvatarPath = ""
                        PrefsService.saveConfig()
                    }
                }
            }

            // Group 2: User Content
            SettingsGroup {
                localScale: root.localScale
                title: "User Content"
                description: "Personal data created within the shell."

                SettingsButton {
                    id: exportBtn
                    localScale: root.localScale
                    text: "Export Tasks"
                    description: "Copy current Kanban board to ~/Documents/."
                    buttonText: "Export"
                    onClicked: {
                        _proc.pendingCmd = ["bash", "-c", "cp ~/.config/Brain_Shell/src/user_data/tasks.json ~/Documents/brain_shell_tasks_backup_$(date +%s).json && notify-send 'Tasks Exported' 'Tasks successfully backed up to ~/Documents/' --icon=document-save"]
                        _proc.running = true
                        exportBtn.buttonText = "✓"
                        exportTickTimer.start()
                    }
                    Timer {
                        id: exportTickTimer
                        interval: 2000
                        onTriggered: exportBtn.buttonText = "Export"
                    }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Clear Task Board"
                    description: "Wipe all current tasks from the Kanban board."
                    buttonText: "Clear"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Clear Tasks?", "Are you sure you want to wipe the Kanban board?", "Confirm", "clear_tasks")
                    }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Wipe Entire Clipboard"
                    description: "Permanently delete all clipboard history and saved pins."
                    buttonText: "Wipe"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Wipe Clipboard?", "Permanently delete all copied text and pins?", "Confirm", "wipe_cliphist")
                    }
                }
            }

            // Group 3: System Cache
            SettingsGroup {
                localScale: root.localScale
                title: "System Cache"
                description: "Temporary data used to speed up the shell."

                SettingsButton {
                    localScale: root.localScale
                    text: "Rebuild App Index"
                    description: "Force rescan of installed applications."
                    buttonText: "Rebuild"
                    onClicked: {
                        _proc.pendingCmd = ["bash", "-c", "nohup bash -c 'sleep 0.5; pkill qs; qs' >/dev/null 2>&1 &"] 
                        _proc.running = true
                    }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Clear Shell Cache"
                    description: "Wipe all temporary shell cache."
                    buttonText: "Wipe"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Clear Cache?", "Wipe all temporary cached files?", "Confirm", "clear_cache")
                    }
                }
            }

            // Group 4: Factory Reset
            SettingsGroup {
                localScale: root.localScale
                title: "Factory Reset"
                description: "Extreme measure to restore defaults."

                SettingsButton {
                    localScale: root.localScale
                    text: "Factory Reset Shell"
                    description: "Wipe all settings and user data"
                    buttonText: "Reset All"
                    destructive: true
                    onClicked: {
                        Popups.showConfirm("Factory Reset?", "Wipe all settings and user data?", "Confirm", "factory_reset")
                    }
                }
            }
        }
    }

    Process {
        id: _proc
        property var pendingCmd: []
        command: pendingCmd
        running: false
    }
}

import QtQuick
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

            // System Cache
            SettingsGroup {
                localScale: root.localScale
                title: "System Cache"
                description: "Temporary data used to speed up the shell."

                SettingsButton {
                    localScale: root.localScale
                    text: "Rebuild App Index"
                    description: "Force rescan of installed applications (.desktop files)."
                    buttonText: "Rebuild"
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Clear Icon Cache"
                    description: "Flush cached icons to resolve missing or corrupted images."
                    buttonText: "Clear"
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Clear Shell Cache"
                    description: "Wipe ~/.cache/brain-shell/ (requires shell restart)."
                    buttonText: "Wipe"
                    destructive: true
                }
            }

            // Clipboard
            SettingsGroup {
                localScale: root.localScale
                title: "Clipboard History"
                description: "Database managed by cliphist."

                SettingsButton {
                    localScale: root.localScale
                    text: "Wipe Clipboard Database"
                    description: "Permanently delete all copied text and images."
                    buttonText: "Wipe"
                    destructive: true
                }
            }

            // User Data
            SettingsGroup {
                localScale: root.localScale
                title: "User Data & Preferences"
                description: "Individual settings files stored in user_data/."

                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Animation Preferences"
                    description: "Deletes animation_prefs.json."
                    buttonText: "Reset"
                    destructive: true
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Profile Preferences"
                    description: "Deletes profile_prefs.json."
                    buttonText: "Reset"
                    destructive: true
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Clear Task Board"
                    description: "Deletes all kanban tasks (tasks.json)."
                    buttonText: "Clear"
                    destructive: true
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Reset Custom Keybinds"
                    description: "Deletes keybinds.json."
                    buttonText: "Reset"
                    destructive: true
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Factory Reset Shell"
                    description: "Wipe ALL JSON preferences and restart the shell."
                    buttonText: "Reset All"
                    destructive: true
                }
            }
        }
    }
}

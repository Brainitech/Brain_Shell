import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
import "../../"
Item {
    id: root
    property real localScale: 1.0
    
    // Replaced local path validator with SettingsButton's built-in validation.

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

            SettingsGroup {
                localScale: root.localScale
                title: "Profile & Identity"
                description: "Customize how you appear in the dashboard."

                SettingsButton {
                    localScale: root.localScale
                    text: "Custom Avatar"
                    description: "Custom profile picture. Leave blank to use wallpaper."
                    inputType: "text"
                    validateAs: "image"
                    inputText: PrefsService.customAvatarPath
                    buttonText: inputText !== "" ? inputText : "Browse..."
                    onInputAccepted: function(txt) {
                        PrefsService.customAvatarPath = txt
                        PrefsService.saveConfig()
                    }
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "System Preferences"
                description: "Global shell behavior and options."

                ToggleButton {
                    localScale: root.localScale
                    text: "Boot into Focus Mode"
                    description: "Start the shell with notches and gaps hidden for maximum workspace."
                    checked: PrefsService.bootFocusMode
                    onCheckedChanged: {
                        if (checked !== PrefsService.bootFocusMode) {
                            PrefsService.bootFocusMode = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Auto-check for Updates"
                    description: "Periodically check the remote repository for shell updates."
                    checked: UpdateService.autoUpdate
                    onCheckedChanged: {
                        if (checked !== UpdateService.autoUpdate) {
                            UpdateService.autoUpdate = checked
                            UpdateService._saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                    SettingsButton {
                        localScale: root.localScale
                        text: "Default Dashboard Tab"
                        description: "Which view opens when you launch the dashboard."
                        inputType: "options"
                        options: ["Home", "System", "Tasks", "Apps", "Config"]
                        selectedOption: PrefsService.defaultDashboardTab
                        buttonText: selectedOption
                        onOptionSelected: function(opt) {
                            PrefsService.defaultDashboardTab = opt
                            PrefsService.saveConfig()
                        }
                    }
                SettingsDivider { localScale: root.localScale }
                    SettingsButton {
                        localScale: root.localScale
                        text: "Default Audio Tab"
                        description: "Which view opens when you launch the audio popup."
                        inputType: "options"
                        options: ["Output", "Input", "Mixers"]
                        selectedOption: PrefsService.defaultAudioTab
                        buttonText: selectedOption
                        onOptionSelected: function(opt) {
                            PrefsService.defaultAudioTab = opt
                            PrefsService.saveConfig()
                        }
                    }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Media & Capture"
                description: "Settings for screen recording."

                SettingsButton {
                    localScale: root.localScale
                    text: "Save Directory"
                    description: "Directory for saved media files."
                    inputType: "text"
                    buttonText: inputText !== "" ? inputText : "Browse..."
                    inputText: ScreenRecService.saveDir
                    validateAs: "dir"
                    onInputAccepted: function(txt) {
                        if (txt === "") return
                        ScreenRecService.saveDir = txt
                        ScreenRecService.saveConfig()
                    }
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Date & Time"

                ToggleButton {
                    localScale: root.localScale
                    text: "Use 24-Hour Time"
                    description: "Switch clock displays from 12h (AM/PM) to 24h format."
                    checked: PrefsService.use24HourTime
                    onCheckedChanged: {
                        if (checked !== PrefsService.use24HourTime) {
                            PrefsService.use24HourTime = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
            }
        }
    }
}

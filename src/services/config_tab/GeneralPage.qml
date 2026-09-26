import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
import "../../"
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
                    description: "Start the shell with notches hidden for a expanded workspace."
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
                    text: "Allow notches to expand on hover in focus mode"
                    description: "When disabled, notches cannot be shown in focus mode."
                    checked: PrefsService.focusModeHoverExpand
                    onCheckedChanged: {
                        if (checked !== PrefsService.focusModeHoverExpand) {
                            PrefsService.focusModeHoverExpand = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Auto-check for Updates"
                    description: "Periodically check the remote repository for shell updates."
                    checked: PrefsService.autoUpdate
                    onCheckedChanged: {
                        if (checked !== PrefsService.autoUpdate) {
                            PrefsService.autoUpdate = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                    SettingsButton {
                        localScale: root.localScale
                        text: "Default Dashboard Tab"
                        description: "Which view opens when you launch the dashboard via click/hover."
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
                        description: "Which view opens when you launch the audio popup via click/hover."
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
                    inputText: PrefsService.screenrecSaveDir
                    validateAs: "dir"
                    onInputAccepted: function(txt) {
                        if (txt === "") return
                        PrefsService.screenrecSaveDir = txt
                        PrefsService.saveConfig()
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

            SettingsGroup {
                localScale: root.localScale
                title: "Top Bar Widgets"
                description: "Customize the visibility of widget elements in the top bar."

                ToggleButton {
                    localScale: root.localScale
                    text: "Always Show Battery Percentage"
                    description: "Keep the battery percentage visible at all times."
                    checked: PrefsService.alwaysShowBatteryPercentage
                    onCheckedChanged: {
                        if (checked !== PrefsService.alwaysShowBatteryPercentage) {
                            PrefsService.alwaysShowBatteryPercentage = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Always Show Volume Percentage"
                    description: "Keep the volume percentage visible at all times."
                    checked: PrefsService.alwaysShowVolumePercentage
                    onCheckedChanged: {
                        if (checked !== PrefsService.alwaysShowVolumePercentage) {
                            PrefsService.alwaysShowVolumePercentage = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
            }
        }
    }
}

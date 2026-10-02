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
                    description: "Image file path (~/ or absolute). Leave blank to use wallpaper."
                    placeholder: "~/Pictures/avatar.png"
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
                title: "Workspace & Focus Mode"
                description: "Window rules, shell concealment, and workspace expansion."

                ToggleButton {
                    localScale: root.localScale
                    text: "Boot into Focus Mode"
                    description: "Start the shell with notches hidden for an expanded workspace."
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
                    description: "When disabled, notches cannot be revealed via hover while in focus mode."
                    checked: PrefsService.focusModeHoverExpand
                    onCheckedChanged: {
                        if (checked !== PrefsService.focusModeHoverExpand) {
                            PrefsService.focusModeHoverExpand = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Navigation & Default Views"
                description: "Initial tabs selected when launching shell panels."

                SettingsButton {
                    localScale: root.localScale
                    text: "Default Dashboard Tab"
                    description: "Initial view opened when launching the dashboard."
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
                    description: "Initial view opened when launching the audio panel."
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
                title: "Top Bar Widgets"
                description: "Visibility and active modules in the top notch bar."

                ToggleButton {
                    localScale: root.localScale
                    text: "Always Show Battery Percentage"
                    description: "Keep numeric battery percentage visible at all times."
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
                    description: "Keep numeric volume percentage visible at all times."
                    checked: PrefsService.alwaysShowVolumePercentage
                    onCheckedChanged: {
                        if (checked !== PrefsService.alwaysShowVolumePercentage) {
                            PrefsService.alwaysShowVolumePercentage = checked
                            PrefsService.saveConfig()
                        }
                    }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Center Notch Visualizer"
                    description: "Show audio visualizer bars in the center notch."
                    checked: PrefsService.enableVisualiser
                    defaultValue: true
                    onToggled: {
                        PrefsService.enableVisualiser = checked
                        PrefsService.saveConfig()
                    }
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Date & Time"
                description: "Clock presentation and time display preferences."

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
                title: "Media & Recording"
                description: "Capture directories and media file handling."

                SettingsButton {
                    localScale: root.localScale
                    text: "Save Directory"
                    description: "Directory path (~/ or absolute) for recordings and snapshots."
                    placeholder: "~/Videos/screen_recordings"
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
                title: "System & Maintenance"
                description: "Shell updates and background synchronization."

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
            }
        }
    }
}

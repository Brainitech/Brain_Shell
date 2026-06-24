import QtQuick
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
                    description: "Select an image to override your profile picture in the dashboard."
                    buttonText: "Browse..."
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
                    checked: false
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Auto-check for Updates"
                    description: "Periodically check the remote repository for shell updates."
                    checked: true
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Default Dashboard Tab"
                    description: "Which view opens when you launch the dashboard."
                    buttonText: "Home"
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Default Audio Tab"
                    description: "Which view opens when you launch the audio popup."
                    buttonText: "Output"
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Media & Capture"
                description: "Settings for screen recording and screenshots."

                SettingsButton {
                    localScale: root.localScale
                    text: "Save Directory"
                    description: "Where media files are saved (e.g. ~/Videos)."
                    buttonText: "Select..."
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Record Audio by Default"
                    description: "Include system audio when starting a screen recording."
                    checked: false
                }
            }

            SettingsGroup {
                localScale: root.localScale
                title: "Date & Time"

                ToggleButton {
                    localScale: root.localScale
                    text: "Use 24-Hour Time"
                    description: "Switch clock displays from 12h (AM/PM) to 24h format."
                    checked: false
                }
            }
        }
    }
}

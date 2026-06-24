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
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * localScale)

            // Animations
            SettingsGroup {
                localScale: root.localScale
                title: "Animations"
                description: "Control the speed and feel of the interface."

                SettingsButton {
                    localScale: root.localScale
                    text: "Animation Style"
                    description: "Global transition style (Slide, Parallax, None)."
                    buttonText: Anim.style
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Easing Curve"
                    description: "The mathematical curve for animations."
                    buttonText: Anim.curveStyle
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Animation Speed"
                    description: "Speed multiplier. Lower is faster."
                    from: 0.5; to: 2.0; stepSize: 0.1; value: Anim.speedMultiplier
                    valueSuffix: "x"
                }
            }

            // Sizing & Borders
            SettingsGroup {
                localScale: root.localScale
                title: "Sizing & Borders"

                ToggleButton {
                    localScale: root.localScale
                    text: "Top Bar Visibility"
                    description: "Show or hide the main top bar."
                    checked: Theme.barEnabled
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Border Width"
                    description: "Thickness of panel borders."
                    from: 0; to: 5; stepSize: 1; value: Theme.borderWidth
                    valueSuffix: "px"
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Container Roundness"
                    description: "Corner radius of windows and popups."
                    from: 0; to: 32; stepSize: 2; value: Theme.cornerRadius
                    valueSuffix: "px"
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Notch Roundness"
                    description: "Corner radius of the top bar notches."
                    from: 0; to: 32; stepSize: 2; value: Theme.notchRadius
                    valueSuffix: "px"
                }
            }

            // Popup Behavior
            SettingsGroup {
                localScale: root.localScale
                title: "Popup Behavior"
                description: "Trigger conditions and delays for popups."

                ToggleButton {
                    id: globalHoverToggle
                    localScale: root.localScale
                    text: "Hover-to-Open Mode"
                    description: "Popups open on hover instead of requiring a click."
                    checked: false
                }
                
                Item {
                    width: parent.width
                    height: globalHoverToggle.checked ? hoverContentCol.height : 0
                    clip: true
                    
                    Behavior on height {
                        NumberAnimation { 
                            duration: Anim.fast
                            easing.type: Anim.globalCurve 
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(2 * localScale)
                        color: Qt.rgba(1, 1, 1, 0.1)
                        radius: Math.round(1 * localScale)
                        anchors.leftMargin: Math.round(12 * localScale)
                    }

                    Column {
                        id: hoverContentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(24 * localScale)
                        spacing: Math.round(4 * localScale)
                        
                        SettingsDivider { localScale: root.localScale }
                        
                        ToggleButton {
                            localScale: root.localScale
                            text: "Dashboard Hover"
                            description: "Dashboard expands when hovering top edge."
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Network Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Audio Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Quick Settings Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Arch Menu Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Notifications Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Clipboard Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Wallpaper Hover"
                            checked: false
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Open Delay"
                            description: "Time before a popup opens when hovered."
                            from: 0; to: 1000; stepSize: 50; value: 150
                            valueSuffix: "ms"
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Close Delay"
                            description: "Time before a popup closes after the mouse leaves."
                            from: 0; to: 1000; stepSize: 50; value: 300
                            valueSuffix: "ms"
                        }
                    }
                }
            }

            // Appearance
            SettingsGroup {
                localScale: root.localScale
                title: "Appearance"

                ToggleButton {
                    localScale: root.localScale
                    text: "Dynamic Theme Override"
                    description: "Bypass wallpaper-derived colors in favor of a static theme."
                    checked: false
                }
            }
        }
    }
}

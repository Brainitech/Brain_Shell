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
                    inputType: "options"
                    options: ["slide", "parallax", "none"]
                    selectedOption: Anim.style
                    buttonText: selectedOption
                    defaultValue: "slide"
                    onOptionSelected: function(opt) { if (opt !== Anim.style) Anim.setStyle(opt) }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Easing Curve"
                    description: "The mathematical curve for animations."
                    inputType: "options"
                    options: ["smooth", "spring", "linear", "cinematic"]
                    selectedOption: Anim.curveStyle
                    buttonText: selectedOption
                    defaultValue: "smooth"
                    onOptionSelected: function(opt) { if (opt !== Anim.curveStyle) Anim.setCurve(opt) }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Animation Speed"
                    description: "Speed multiplier. Higher is faster."
                    from: 0.1; to: 2.0; stepSize: 0.1; value: Anim.speedMultiplier
                    defaultValue: 1.0
                    onValueChanged: { if (value !== Anim.speedMultiplier) Anim.setSpeedMultiplier(value) }
                    valueSuffix: "x"
                }
            }

            // Sizing & Borders
            Item {
                width: parent.width
                height: sizingGroup.height

                SettingsGroup {
                    id: sizingGroup
                    localScale: root.localScale
                    title: "Sizing & Borders"
                    opacity: 0.3
                    enabled: false

                    SettingsSlider {
                        localScale: root.localScale
                        text: "Border Width"
                        description: "Thickness of panel borders."
                        from: 0; to: 10; stepSize: 1; value: PrefsService.borderWidth
                        defaultValue: 6
                        onValueChanged: { if (value !== PrefsService.borderWidth) { PrefsService.borderWidth = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                    SettingsDivider { localScale: root.localScale }
                    SettingsSlider {
                        localScale: root.localScale
                        text: "Container Roundness"
                        description: "Corner radius of windows and popups."
                        from: 0; to: 32; stepSize: 2; value: PrefsService.cornerRadius
                        defaultValue: 17
                        onValueChanged: { if (value !== PrefsService.cornerRadius) { PrefsService.cornerRadius = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                    SettingsDivider { localScale: root.localScale }
                    SettingsSlider {
                        localScale: root.localScale
                        text: "Notch Roundness"
                        description: "Corner radius of the top bar notches."
                        from: 0; to: 32; stepSize: 2; value: PrefsService.notchRadius
                        defaultValue: 15
                        onValueChanged: { if (value !== PrefsService.notchRadius) { PrefsService.notchRadius = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                }

                Text {
                    anchors.centerIn: sizingGroup
                    anchors.verticalCenterOffset: Math.round(12 * root.localScale)
                    text: "WORK IN PROGRESS"
                    color: Theme.text
                    font.pixelSize: Math.round(20 * root.localScale)
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    style: Text.Outline
                    styleColor: Theme.background
                }
            }

            // Popup Behavior
            SettingsGroup {
                id: popupGroup
                localScale: root.localScale
                title: "Popup Behavior"
                description: "Trigger conditions and delays for popups."

                property bool dropdownExpanded: false
                Component.onCompleted: dropdownExpanded = PrefsService.globalHoverMode

                Item {
                    width: parent.width
                    height: globalHoverToggle.height

                    ToggleButton {
                        id: globalHoverToggle
                        width: parent.width
                        localScale: root.localScale
                        text: "Hover-to-Open Mode"
                        description: "Popups open on hover instead of requiring a click."
                        checked: PrefsService.globalHoverMode
                        defaultValue: false
                        onToggled: { 
                            PrefsService.globalHoverMode = checked; 
                            if (checked) popupGroup.dropdownExpanded = true;
                            PrefsService.saveConfig(); 
                        }
                    }

                    Rectangle {
                        visible: PrefsService.globalHoverMode
                        width: Math.round(28 * localScale)
                        height: Math.round(28 * localScale)
                        radius: Math.round(6 * localScale)
                        anchors {
                            right: parent.right
                            rightMargin: Math.round(84 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        color: chevronHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: popupGroup.dropdownExpanded ? "▲" : "▼"
                            color: Theme.text
                            font.pixelSize: Math.round(10 * localScale)
                        }

                        HoverHandler { id: chevronHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: popupGroup.dropdownExpanded = !popupGroup.dropdownExpanded
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: (globalHoverToggle.checked && popupGroup.dropdownExpanded) ? hoverContentCol.height : 0
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
                            text: "Dashboard"
                            description: "Dashboard expands when hovering top edge."
                            checked: PrefsService.hoverDashboard
                            defaultValue: false
                            onToggled: { PrefsService.hoverDashboard = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Network"
                            checked: PrefsService.hoverNetwork
                            defaultValue: false
                            onToggled: { PrefsService.hoverNetwork = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            id: audioHoverToggle
                            localScale: root.localScale
                            text: "Audio"
                            checked: PrefsService.hoverAudio
                            Binding on checked { value: PrefsService.hoverAudio; restoreMode: Binding.RestoreBinding }
                            defaultValue: false
                            onToggled: { 
                                PrefsService.hoverAudio = checked; 
                                if (checked) PrefsService.hoverQuick = false;
                                PrefsService.saveConfig();
                                audioHoverToggle.checked = Qt.binding(function() { return PrefsService.hoverAudio });
                            }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            id: quickHoverToggle
                            localScale: root.localScale
                            text: "Quick Controls"
                            checked: PrefsService.hoverQuick
                            enabled: !PrefsService.hoverAudio
                            opacity: PrefsService.hoverAudio ? 0.4 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
                            Binding on checked { value: PrefsService.hoverQuick; restoreMode: Binding.RestoreBinding }
                            defaultValue: true
                            onToggled: { 
                                PrefsService.hoverQuick = checked; 
                                PrefsService.saveConfig();
                                quickHoverToggle.checked = Qt.binding(function() { return PrefsService.hoverQuick });
                            }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Power Menu"
                            checked: PrefsService.hoverArchMenu
                            defaultValue: false
                            onToggled: { PrefsService.hoverArchMenu = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Notifications"
                            checked: PrefsService.hoverNotifications
                            defaultValue: false
                            onToggled: { PrefsService.hoverNotifications = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Clipboard"
                            checked: PrefsService.hoverClipboard
                            defaultValue: false
                            onToggled: { PrefsService.hoverClipboard = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Wallpaper Picker"
                            checked: PrefsService.hoverWallpaper
                            defaultValue: false
                            onToggled: { PrefsService.hoverWallpaper = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Open Delay"
                            description: "Time before a popup opens when hovered."
                            from: 0; to: 1000; stepSize: 50; value: PrefsService.hoverOpenDelay
                            defaultValue: 150
                            onValueChanged: { if (value !== PrefsService.hoverOpenDelay) { PrefsService.hoverOpenDelay = value; PrefsService.saveConfig() } }
                            valueSuffix: "ms"
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Close Delay"
                            description: "Time before a popup closes after the mouse leaves."
                            from: 0; to: 1000; stepSize: 50; value: PrefsService.hoverCloseDelay
                            defaultValue: 300
                            onValueChanged: { if (value !== PrefsService.hoverCloseDelay) { PrefsService.hoverCloseDelay = value; PrefsService.saveConfig() } }
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
                    checked: PrefsService.dynamicThemeOverride
                    defaultValue: false
                    onToggled: { PrefsService.dynamicThemeOverride = checked; PrefsService.saveConfig() }
                }
            }
        }
    }
}

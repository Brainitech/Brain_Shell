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
import "../../../components"
import "../../../"

Item {
    id: root
    property real localScale: 1.0

    width: parent ? parent.width : 400
    height: popupGroup.height

    SettingsGroup {
        id: popupGroup
        width: parent.width
        localScale: root.localScale
        title: "Popup & Shell Behavior"
        description: "Trigger conditions, hover delays, and auto-popups."

        property bool dropdownExpanded: false

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
                useOverrideReset: true
                overrideResetVisible: checked && (
                    PrefsService.hoverDashboard !== false ||
                    PrefsService.hoverNetwork !== false ||
                    PrefsService.hoverAudio !== false ||
                    PrefsService.hoverQuick !== true ||
                    PrefsService.hoverArchMenu !== false ||
                    PrefsService.hoverNotifications !== false ||
                    PrefsService.hoverClipboard !== false ||
                    PrefsService.hoverWallpaper !== false ||
                    PrefsService.hoverOpenDelay !== 150 ||
                    PrefsService.hoverCloseDelay !== 300
                )
                onResetTriggered: {
                    PrefsService.hoverDashboard = false;
                    PrefsService.hoverNetwork = false;
                    PrefsService.hoverAudio = false;
                    PrefsService.hoverQuick = true;
                    PrefsService.hoverArchMenu = false;
                    PrefsService.hoverNotifications = false;
                    PrefsService.hoverClipboard = false;
                    PrefsService.hoverWallpaper = false;
                    PrefsService.hoverOpenDelay = 150;
                    PrefsService.hoverCloseDelay = 300;
                    PrefsService.saveConfig();
                }
                onToggled: { 
                    PrefsService.globalHoverMode = checked; 
                    if (checked) popupGroup.dropdownExpanded = true;
                    else popupGroup.dropdownExpanded = false;
                    PrefsService.saveConfig(); 
                }
            }

            Rectangle {
                visible: PrefsService.globalHoverMode
                width: Math.round(28 * root.localScale)
                height: Math.round(28 * root.localScale)
                radius: Math.round(6 * root.localScale)
                anchors {
                    right: parent.right
                    rightMargin: Math.round(84 * root.localScale)
                    verticalCenter: parent.verticalCenter
                }
                color: chevronHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: popupGroup.dropdownExpanded ? "▲" : "▼"
                    color: Theme.text
                    font.pixelSize: Math.round(10 * root.localScale)
                }

                HoverHandler { id: chevronHover; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupGroup.dropdownExpanded = !popupGroup.dropdownExpanded
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
                    easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.round(2 * root.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                radius: Math.round(1 * root.localScale)
                anchors.leftMargin: Math.round(12 * root.localScale)
            }

            Column {
                id: hoverContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Math.round(24 * root.localScale)
                spacing: Math.round(4 * root.localScale)

                SettingsDivider { localScale: root.localScale }

                ToggleButton {
                    localScale: root.localScale
                    text: "Dashboard"
                    description: "Dashboard expands when hovering top edge."
                    checked: PrefsService.hoverDashboard
                    onToggled: { PrefsService.hoverDashboard = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Network"
                    checked: PrefsService.hoverNetwork
                    onToggled: { PrefsService.hoverNetwork = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    id: audioHoverToggle
                    localScale: root.localScale
                    text: "Audio"
                    checked: PrefsService.hoverAudio
                    Binding on checked { value: PrefsService.hoverAudio; restoreMode: Binding.RestoreBinding }
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
                    onToggled: { PrefsService.hoverArchMenu = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Notifications"
                    checked: PrefsService.hoverNotifications
                    onToggled: { PrefsService.hoverNotifications = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Clipboard"
                    checked: PrefsService.hoverClipboard
                    onToggled: { PrefsService.hoverClipboard = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                ToggleButton {
                    localScale: root.localScale
                    text: "Wallpaper Picker"
                    checked: PrefsService.hoverWallpaper
                    onToggled: { PrefsService.hoverWallpaper = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Hover Open Delay"
                    description: "Time before a popup opens when hovered."
                    from: 0; to: 1000; stepSize: 50; value: PrefsService.hoverOpenDelay
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

        SettingsDivider { localScale: root.localScale }

        ToggleButton {
            localScale: root.localScale
            text: "QuickControl OSD"
            description: "Automatically pop out QuickControl when volume/brightness changes."
            checked: PrefsService.enableOsd
            defaultValue: true
            onToggled: { PrefsService.enableOsd = checked; PrefsService.saveConfig() }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsSlider {
            localScale: root.localScale
            text: "OSD Duration"
            description: "Time the OSD stays open before automatically closing."
            from: 0.5; to: 5.0; stepSize: 0.1; value: PrefsService.osdDuration
            defaultValue: 2.5
            onValueChanged: { if (Math.abs(value - PrefsService.osdDuration) > 0.01) { PrefsService.osdDuration = value; PrefsService.saveConfig() } }
            valueSuffix: "s"
            opacity: PrefsService.enableOsd ? 1.0 : 0.4
            enabled: PrefsService.enableOsd
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

    }
}

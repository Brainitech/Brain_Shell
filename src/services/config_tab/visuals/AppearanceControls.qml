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
    signal requestColorPick(string targetProp)

    width: parent ? parent.width : 400
    height: appearanceGroup.height

    SettingsGroup {
        id: appearanceGroup
        width: parent.width
        localScale: root.localScale
        title: "Theming & Appearance"
        description: "Surface transparency, background blur, and custom theme presets."

        property bool dropdownExpanded: false
        Component.onCompleted: dropdownExpanded = PrefsService.dynamicThemeOverride

        SettingsSlider {
            localScale: root.localScale
            text: "Background Opacity"
            description: "Transparency level of main window and popup backgrounds."
            from: 0.1; to: 1.0; stepSize: 0.05; value: PrefsService.bgOpacity
            defaultValue: 1.0
            onValueChanged: { if (Math.abs(value - PrefsService.bgOpacity) > 0.001) { PrefsService.bgOpacity = value; PrefsService.saveConfig() } }
            valueSuffix: ""
            formatValue: function(v) { return Math.round(v * 100) + "%" }
        }

        ToggleButton {
            id: blurToggle
            width: parent.width
            localScale: root.localScale
            text: "Background Blur"
            description: PrefsService.bgOpacity >= 0.95 ? "Disabled — opacity must be below 95%." : "Enable blur effect behind transparent backgrounds."
            checked: PrefsService.bgBlur
            Binding on checked { value: PrefsService.bgBlur; restoreMode: Binding.RestoreBinding }
            enabled: PrefsService.bgOpacity < 0.95
            opacity: PrefsService.bgOpacity >= 0.95 ? 0.4 : 1.0
            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
            defaultValue: false
            onToggled: { 
                PrefsService.bgBlur = checked; 
                PrefsService.saveConfig();
                blurToggle.checked = Qt.binding(function() { return PrefsService.bgBlur });
            }
        }

        SettingsDivider { localScale: root.localScale }

        Item {
            width: parent.width
            height: dynamicThemeToggle.height

            ToggleButton {
                id: dynamicThemeToggle
                width: parent.width
                localScale: root.localScale
                text: "Dynamic Theme Override"
                description: "Bypass wallpaper-derived colors in favor of a static theme."
                checked: PrefsService.dynamicThemeOverride
                defaultValue: false
                onToggled: { 
                    PrefsService.dynamicThemeOverride = checked; 
                    if (checked) appearanceGroup.dropdownExpanded = true;
                    PrefsService.saveConfig(); 
                }
            }

            Rectangle {
                visible: PrefsService.dynamicThemeOverride
                width: Math.round(28 * root.localScale)
                height: Math.round(28 * root.localScale)
                radius: Math.round(6 * root.localScale)
                anchors {
                    right: parent.right
                    rightMargin: Math.round(84 * root.localScale)
                    verticalCenter: parent.verticalCenter
                }
                color: themeChevHover.hovered ? Theme.cardHover : Theme.card
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: appearanceGroup.dropdownExpanded ? "▲" : "▼"
                    color: Theme.text
                    font.pixelSize: Math.round(10 * root.localScale)
                }

                HoverHandler { id: themeChevHover; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appearanceGroup.dropdownExpanded = !appearanceGroup.dropdownExpanded
                }
            }
        }

        Item {
            width: parent.width
            height: (dynamicThemeToggle.checked && appearanceGroup.dropdownExpanded) ? themeContentCol.height : 0
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
                id: themeContentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Math.round(24 * root.localScale)
                anchors.rightMargin: Math.round(8 * root.localScale)
                spacing: Math.round(8 * root.localScale)

                SettingsDivider { localScale: root.localScale }

                ThemePresetGrid {
                    localScale: root.localScale
                }

                SettingsDivider { localScale: root.localScale }

                Text {
                    text: "INDIVIDUAL OVERRIDES"
                    color: Theme.subtext
                    font.pixelSize: Math.round(10 * root.localScale)
                    font.weight: Font.Bold
                    leftPadding: Math.round(2 * root.localScale)
                }

                SettingsButton {
                    localScale: root.localScale
                    text: "Background Color"
                    description: "Main background (" + (PrefsService.overrideBg !== "" ? PrefsService.overrideBg : "Default") + ")"
                    swatchColor: PrefsService.overrideBg !== "" ? PrefsService.overrideBg : Theme.background
                    onClicked: root.requestColorPick("bg")
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Active Accent Color"
                    description: "Primary highlight (" + (PrefsService.overrideActive !== "" ? PrefsService.overrideActive : "Default") + ")"
                    swatchColor: PrefsService.overrideActive !== "" ? PrefsService.overrideActive : Theme.active
                    onClicked: root.requestColorPick("active")
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Text Color"
                    description: "Primary typography (" + (PrefsService.overrideText !== "" ? PrefsService.overrideText : "Default") + ")"
                    swatchColor: PrefsService.overrideText !== "" ? PrefsService.overrideText : Theme.text
                    onClicked: root.requestColorPick("text")
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Subtext Color"
                    description: "Secondary labels (" + (PrefsService.overrideSubtext !== "" ? PrefsService.overrideSubtext : "Default") + ")"
                    swatchColor: PrefsService.overrideSubtext !== "" ? PrefsService.overrideSubtext : Theme.subtext
                    onClicked: root.requestColorPick("subtext")
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Border Color"
                    description: "Surface outline (" + (PrefsService.overrideBorder !== "" ? PrefsService.overrideBorder : "Default") + ")"
                    swatchColor: PrefsService.overrideBorder !== "" ? PrefsService.overrideBorder : Theme.border
                    onClicked: root.requestColorPick("border")
                }
            }
        }
    }
}

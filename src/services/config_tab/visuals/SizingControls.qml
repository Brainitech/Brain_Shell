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
    height: sizingGroup.height

    SettingsGroup {
        id: sizingGroup
        width: parent.width
        localScale: root.localScale
        title: "Surface & Window Styling"
        description: "Panel border thickness, corner roundness, and shell layout architecture."

        SettingsButton {
            localScale: root.localScale
            text: "Shell Layout"
            description: "Choose between classic morphing border frame and detached floating pills."
            inputType: "options"
            options: ["border", "floating"]
            selectedOption: PrefsService.shellLayout
            buttonText: selectedOption
            defaultValue: "border"
            onOptionSelected: function(opt) {
                if (opt !== PrefsService.shellLayout) {
                    PrefsService.shellLayout = opt
                    PrefsService.saveConfig()
                }
            }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsSlider {
            id: borderWidthSlider
            localScale: root.localScale
            text: "Border Width"
            description: PrefsService.isFloating
                         ? "Disabled — border frame is eliminated in floating mode."
                         : "Thickness of panel borders."
            from: 0; to: 10; stepSize: 1
            value: PrefsService.isFloating ? 0 : PrefsService.borderWidth
            defaultValue: PrefsService.isFloating ? 0 : 6
            enabled: !PrefsService.isFloating
            opacity: PrefsService.isFloating ? 0.4 : 1.0
            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
            formatValue: function(v) {
                if (PrefsService.isFloating) return "0px (N/A)"
                return Math.round(v) + "px"
            }
            onValueChanged: {
                if (!PrefsService.isFloating && value !== PrefsService.borderWidth) {
                    PrefsService.borderWidth = value
                    PrefsService.saveConfig()
                }
            }
            valueSuffix: "px"
        }

        Connections {
            target: PrefsService
            function onIsFloatingChanged() {
                borderWidthSlider.value = Qt.binding(function() {
                    return PrefsService.isFloating ? 0 : PrefsService.borderWidth
                })
            }
            function onBorderWidthChanged() {
                if (!PrefsService.isFloating && borderWidthSlider.value !== PrefsService.borderWidth) {
                    borderWidthSlider.value = PrefsService.borderWidth
                }
            }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsSlider {
            localScale: root.localScale
            text: "Global Roundness"
            description: "Global corner radius for popups, notches, and borders."
            from: 0; to: 20; stepSize: 2; value: PrefsService.cornerRadius
            defaultValue: 17
            onValueChanged: { if (value !== PrefsService.cornerRadius) { PrefsService.cornerRadius = value; PrefsService.saveConfig() } }
            valueSuffix: "px"
        }

        // Floating Shell Configuration Section
        Item {
            width: parent.width
            height: visible ? floatingCol.height : 0
            visible: PrefsService.isFloating
            clip: true

            Behavior on height { NumberAnimation { duration: Anim.fast; easing.type: Anim.globalCurve } }

            Column {
                id: floatingCol
                width: parent.width
                spacing: Math.round(4 * root.localScale)

                SettingsDivider { localScale: root.localScale }

                SettingsSlider {
                    localScale: root.localScale
                    text: "Edge Gap"
                    description: "Distance between floating pills and screen edges."
                    from: 4; to: 24; stepSize: 2; value: PrefsService.floatingGap
                    defaultValue: 8
                    onValueChanged: { if (value !== PrefsService.floatingGap) { PrefsService.floatingGap = value; PrefsService.saveConfig() } }
                    valueSuffix: "px"
                }

                SettingsDivider { localScale: root.localScale }

                SettingsSlider {
                    localScale: root.localScale
                    text: "Pill Height"
                    description: "Height of the three top floating pill bars."
                    from: 32; to: 56; stepSize: 2; value: PrefsService.floatingBarHeight
                    defaultValue: 40
                    onValueChanged: { if (value !== PrefsService.floatingBarHeight) { PrefsService.floatingBarHeight = value; PrefsService.saveConfig() } }
                    valueSuffix: "px"
                }
            }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsButton {
            localScale: root.localScale
            text: "Slider Style"
            description: "Visual appearance of volume and brightness channel sliders."
            inputType: "options"
            options: ["Capsule", "Glow", "Outline", "Ring", "Dynamic", "Segmented"]
            selectedOption: {
                switch (PrefsService.sliderStyle) {
                    case "glow": return "Glow"
                    case "outline": return "Outline"
                    case "ring": return "Ring"
                    case "dynamic": return "Dynamic"
                    case "segmented": return "Segmented"
                    case "capsule":
                    default: return "Capsule"
                }
            }
            buttonText: selectedOption
            defaultValue: "Capsule"
            onOptionSelected: function(opt) {
                var s = opt.toLowerCase()
                if (s !== PrefsService.sliderStyle) {
                    PrefsService.sliderStyle = s
                    PrefsService.saveConfig()
                }
            }
        }
    }
}

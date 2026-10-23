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
    height: wsGroup.height

    readonly property bool isNiri: WM.detectedCompositor === "Niri"

    SettingsGroup {
        id: wsGroup
        width: parent.width
        localScale: root.localScale
        title: "Workspaces"
        description: "Layout mode, indicator shapes, and workspace symbol styles."

        SettingsButton {
            localScale: root.localScale
            text: "Display Mode"
            description: root.isNiri
                ? "Locked to Dynamic mode for Niri compositor."
                : "Static (fixed count), Dynamic (up to active), or Occupied (only populated)."
            inputType: "options"
            options: root.isNiri ? ["Dynamic"] : ["Static", "Dynamic", "Occupied"]
            selectedOption: root.isNiri ? "Dynamic" : (PrefsService.wsMode ? (PrefsService.wsMode.charAt(0).toUpperCase() + PrefsService.wsMode.slice(1).toLowerCase()) : "Static")
            buttonText: selectedOption
            defaultValue: root.isNiri ? "Dynamic" : "Static"
            enabled: !root.isNiri
            opacity: root.isNiri ? 0.6 : 1.0
            onOptionSelected: function(opt) {
                if (!root.isNiri) {
                    PrefsService.wsMode = opt.toLowerCase()
                    PrefsService.saveConfig()
                }
            }
        }

        SettingsDivider {
            localScale: root.localScale
            visible: !root.isNiri && (PrefsService.wsMode === "static")
        }

        SettingsSlider {
            localScale: root.localScale
            visible: !root.isNiri && (PrefsService.wsMode === "static")
            text: "Static Workspace Count"
            description: "Total number of workspaces displayed when in Static mode."
            from: 3
            to: 15
            stepSize: 1
            value: PrefsService.wsCount || 10
            defaultValue: 10
            onValueChanged: {
                if (value !== PrefsService.wsCount) {
                    PrefsService.wsCount = Math.round(value)
                    PrefsService.saveConfig()
                }
            }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsButton {
            localScale: root.localScale
            text: "Indicator Shape"
            description: "Circle (round dots), Pill (capsules), Rounded (squircles), or Square."
            inputType: "options"
            options: ["Circle", "Pill", "Rounded", "Square"]
            selectedOption: PrefsService.wsShape ? (PrefsService.wsShape.charAt(0).toUpperCase() + PrefsService.wsShape.slice(1).toLowerCase()) : "Circle"
            buttonText: selectedOption
            defaultValue: "Circle"
            onOptionSelected: function(opt) {
                PrefsService.wsShape = opt.toLowerCase()
                PrefsService.saveConfig()
            }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsButton {
            localScale: root.localScale
            text: "Workspace Symbols"
            description: "Render numbers, kanji, roman numerals, or icons."
            inputType: "options"
            options: ["None", "Numbers", "Kanji", "Roman", "Icons"]
            selectedOption: PrefsService.wsSymbols ? (PrefsService.wsSymbols.charAt(0).toUpperCase() + PrefsService.wsSymbols.slice(1).toLowerCase()) : "None"
            buttonText: selectedOption
            defaultValue: "None"
            onOptionSelected: function(opt) {
                PrefsService.wsSymbols = opt.toLowerCase()
                PrefsService.saveConfig()
            }
        }

        SettingsDivider {
            localScale: root.localScale
            visible: PrefsService.wsSymbols !== "none"
        }

        SettingsButton {
            localScale: root.localScale
            visible: PrefsService.wsSymbols !== "none"
            text: "Symbol Style"
            description: "Floating (clean symbol overlay) or Badges (compact container chip)."
            inputType: "options"
            options: ["Floating", "Badges"]
            selectedOption: {
                var st = PrefsService.wsSymbolStyle || "floating"
                if (st === "badges") return "Badges"
                return "Floating"
            }
            buttonText: selectedOption
            defaultValue: "Floating"
            onOptionSelected: function(opt) {
                PrefsService.wsSymbolStyle = (opt === "Badges") ? "badges" : "floating"
                PrefsService.saveConfig()
            }
        }

        SettingsDivider { localScale: root.localScale }

        ToggleButton {
            localScale: root.localScale
            text: "Show Capsule Background"
            description: "Display the pill-shaped background capsule behind workspace indicators."
            checked: PrefsService.wsShowCapsule !== undefined ? PrefsService.wsShowCapsule : true
            defaultValue: true
            onCheckedChanged: {
                if (checked !== PrefsService.wsShowCapsule) {
                    PrefsService.wsShowCapsule = checked
                    PrefsService.saveConfig()
                }
            }
        }

        SettingsDivider { localScale: root.localScale }

        ToggleButton {
            localScale: root.localScale
            text: "Invert Scroll Direction"
            description: "Reverse the wheel scroll direction when cycling through workspaces."
            checked: PrefsService.wsInvertScroll || false
            defaultValue: false
            onCheckedChanged: {
                if (checked !== PrefsService.wsInvertScroll) {
                    PrefsService.wsInvertScroll = checked
                    PrefsService.saveConfig()
                }
            }
        }
    }
}

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
import "../../../"

Item {
    id: root
    property real localScale: 1.0

    width: parent ? parent.width : 400
    height: presetMainCol.height

    readonly property var categories: [
        {
            name: "MODERN PASTEL / DARK",
            presets: [
                {
                    name: "Catppuccin",
                    bg: "#1e1e2e",
                    active: "#cba6f7",
                    text: "#cdd6f4",
                    subtext: "#a6adc8",
                    border: "#45475a"
                },
                {
                    name: "Tokyo Night",
                    bg: "#1a1b26",
                    active: "#7aa2f7",
                    text: "#c0caf5",
                    subtext: "#9aa5ce",
                    border: "#414868"
                },
                {
                    name: "Rosé Pine",
                    bg: "#191724",
                    active: "#eb6f92",
                    text: "#e0def4",
                    subtext: "#908caa",
                    border: "#403d52"
                }
            ]
        },
        {
            name: "RETRO & WARM EARTH",
            presets: [
                {
                    name: "Gruvbox",
                    bg: "#282828",
                    active: "#fe8019",
                    text: "#ebdbb2",
                    subtext: "#d5c4a1",
                    border: "#504945"
                },
                {
                    name: "Everforest",
                    bg: "#2d353b",
                    active: "#a7c080",
                    text: "#d3c6aa",
                    subtext: "#9da9a0",
                    border: "#475258"
                },
                {
                    name: "Kanagawa",
                    bg: "#1f1f28",
                    active: "#7e9cd8",
                    text: "#dcd7ba",
                    subtext: "#727169",
                    border: "#363646"
                }
            ]
        },
        {
            name: "VIBRANT & NEON",
            presets: [
                {
                    name: "Synthwave",
                    bg: "#262335",
                    active: "#ff7edb",
                    text: "#36f9f6",
                    subtext: "#848bbd",
                    border: "#493963"
                },
                {
                    name: "Dracula",
                    bg: "#282a36",
                    active: "#bd93f9",
                    text: "#f8f8f2",
                    subtext: "#bfbfbf",
                    border: "#6272a4"
                },
                {
                    name: "Monokai",
                    bg: "#272822",
                    active: "#a6e22e",
                    text: "#f8f8f2",
                    subtext: "#75715e",
                    border: "#3e3d32"
                }
            ]
        },
        {
            name: "CLASSIC & TERMINAL",
            presets: [
                {
                    name: "Nord",
                    bg: "#2e3440",
                    active: "#88c0d0",
                    text: "#eceff4",
                    subtext: "#d8dee9",
                    border: "#4c566a"
                },
                {
                    name: "One Dark",
                    bg: "#282c34",
                    active: "#61afef",
                    text: "#abb2bf",
                    subtext: "#5c6370",
                    border: "#3e4451"
                },
                {
                    name: "Solarized",
                    bg: "#002b36",
                    active: "#268bd2",
                    text: "#839496",
                    subtext: "#586e75",
                    border: "#073642"
                }
            ]
        }
    ]

    Column {
        id: presetMainCol
        width: parent.width
        spacing: Math.round(10 * root.localScale)

        Repeater {
            model: root.categories

            Column {
                id: categoryCol
                required property var modelData
                readonly property var categoryData: modelData
                width: parent.width
                spacing: Math.round(6 * root.localScale)

                Text {
                    text: categoryData.name
                    color: Theme.subtext
                    font.pixelSize: Math.round(10 * root.localScale)
                    font.weight: Font.Bold
                    leftPadding: Math.round(2 * root.localScale)
                }

                Grid {
                    id: catGrid
                    width: parent.width
                    columns: 3
                    columnSpacing: Math.round(8 * root.localScale)
                    rowSpacing: Math.round(10 * root.localScale)

                    readonly property real cellWidth: Math.floor((width - (columns - 1) * columnSpacing) / columns)

                    Repeater {
                        model: categoryData.presets

                        Item {
                            id: presetDelegate
                            required property var modelData
                            readonly property var presetData: modelData
                            width: catGrid.cellWidth
                            height: presetCol.height

                            readonly property bool isSelected:
                                PrefsService.overrideBg.toLowerCase() === presetData.bg.toLowerCase() &&
                                PrefsService.overrideActive.toLowerCase() === presetData.active.toLowerCase() &&
                                PrefsService.overrideText.toLowerCase() === presetData.text.toLowerCase() &&
                                PrefsService.overrideSubtext.toLowerCase() === presetData.subtext.toLowerCase() &&
                                PrefsService.overrideBorder.toLowerCase() === presetData.border.toLowerCase()

                            Column {
                                id: presetCol
                                width: parent.width
                                spacing: Math.round(5 * root.localScale)

                                Rectangle {
                                    id: presetRect
                                    width: parent.width
                                    height: Math.round(34 * root.localScale)
                                    radius: Math.round(8 * root.localScale)
                                    color: presetDelegate.isSelected
                                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                                        : (cardHover.hovered ? Theme.cardHover : Theme.card)
                                    border.color: presetDelegate.isSelected
                                        ? Theme.active
                                        : (cardHover.hovered ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.35))
                                    border.width: presetDelegate.isSelected ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                                    Behavior on border.color { ColorAnimation { duration: Anim.fast } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Math.round(4 * root.localScale)

                                        Repeater {
                                            model: [presetData.bg, presetData.active, presetData.text, presetData.subtext, presetData.border]

                                            Rectangle {
                                                required property var modelData
                                                width: Math.round(12 * root.localScale)
                                                height: width
                                                radius: width / 2
                                                color: modelData
                                                border.color: Qt.rgba(0, 0, 0, 0.35)
                                                border.width: 1
                                            }
                                        }
                                    }
                                }

                                Text {
                                    id: presetLabel
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: presetData.name
                                    color: presetDelegate.isSelected ? Theme.active : (cardHover.hovered ? Theme.text : Theme.subtext)
                                    font.pixelSize: Math.round(11 * root.localScale)
                                    font.weight: presetDelegate.isSelected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                }
                            }

                            HoverHandler {
                                id: cardHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    PrefsService.overrideBg = presetData.bg;
                                    PrefsService.overrideActive = presetData.active;
                                    PrefsService.overrideText = presetData.text;
                                    PrefsService.overrideSubtext = presetData.subtext;
                                    PrefsService.overrideBorder = presetData.border;
                                    PrefsService.overrideIcon = presetData.text;
                                    PrefsService.overrideIconFont = presetData.active;
                                    PrefsService.saveConfig();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

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

    // Each preset exposes dark and light color variants side-by-side on a single tile.
    // The tile is split diagonally: dark mode fills the upper-left triangle, light mode
    // fills the lower-right triangle, separated by a thin hairline slash.
    readonly property var categories: [
        {
            name: "MODERN PASTEL / DARK",
            presets: [
                {
                    name: "Catppuccin",
                    dark:  { bg: "#1e1e2e", active: "#cba6f7", text: "#cdd6f4", subtext: "#a6adc8", border: "#45475a" },
                    light: { bg: "#eff1f5", active: "#8839ef", text: "#4c4f69", subtext: "#6c6f85", border: "#ccd0da" }
                },
                {
                    name: "Tokyo Night",
                    dark:  { bg: "#1a1b26", active: "#7aa2f7", text: "#c0caf5", subtext: "#9aa5ce", border: "#414868" },
                    light: { bg: "#d5d6db", active: "#2e7de9", text: "#3760bf", subtext: "#6172b0", border: "#9699a3" }
                },
                {
                    name: "Rosé Pine",
                    dark:  { bg: "#191724", active: "#eb6f92", text: "#e0def4", subtext: "#908caa", border: "#403d52" },
                    light: { bg: "#faf4ed", active: "#b4637a", text: "#575279", subtext: "#797593", border: "#dfdad9" }
                }
            ]
        },
        {
            name: "RETRO & WARM EARTH",
            presets: [
                {
                    name: "Gruvbox",
                    dark:  { bg: "#282828", active: "#fe8019", text: "#ebdbb2", subtext: "#d5c4a1", border: "#504945" },
                    light: { bg: "#fbf1c7", active: "#d65d0e", text: "#3c3836", subtext: "#665c54", border: "#bdae93" }
                },
                {
                    name: "Everforest",
                    dark:  { bg: "#2d353b", active: "#a7c080", text: "#d3c6aa", subtext: "#9da9a0", border: "#475258" },
                    light: { bg: "#fdf6e3", active: "#8da101", text: "#5c6a72", subtext: "#708089", border: "#e0dcc7" }
                },
                {
                    name: "Kanagawa",
                    dark:  { bg: "#1f1f28", active: "#7e9cd8", text: "#dcd7ba", subtext: "#727169", border: "#363646" },
                    light: { bg: "#f2ecbc", active: "#4a7a96", text: "#545464", subtext: "#9098a4", border: "#c8c093" }
                }
            ]
        },
        {
            name: "VIBRANT & NEON",
            presets: [
                {
                    name: "Synthwave",
                    dark:  { bg: "#262335", active: "#ff7edb", text: "#36f9f6", subtext: "#848bbd", border: "#493963" },
                    light: { bg: "#faf0ff", active: "#c743a3", text: "#2d0e4d", subtext: "#7a4fa8", border: "#d9b3f0" }
                },
                {
                    name: "Dracula",
                    dark:  { bg: "#282a36", active: "#bd93f9", text: "#f8f8f2", subtext: "#bfbfbf", border: "#6272a4" },
                    light: { bg: "#f8f8f2", active: "#6272a4", text: "#282a36", subtext: "#44475a", border: "#bd93f9" }
                },
                {
                    name: "Monokai",
                    dark:  { bg: "#272822", active: "#a6e22e", text: "#f8f8f2", subtext: "#75715e", border: "#3e3d32" },
                    light: { bg: "#fafaf8", active: "#52a828", text: "#272822", subtext: "#75715e", border: "#c2c1b3" }
                }
            ]
        },
        {
            name: "CLASSIC & TERMINAL",
            presets: [
                {
                    name: "Nord",
                    dark:  { bg: "#2e3440", active: "#88c0d0", text: "#eceff4", subtext: "#d8dee9", border: "#4c566a" },
                    light: { bg: "#eceff4", active: "#5e81ac", text: "#2e3440", subtext: "#4c566a", border: "#d8dee9" }
                },
                {
                    name: "One Dark",
                    dark:  { bg: "#282c34", active: "#61afef", text: "#abb2bf", subtext: "#5c6370", border: "#3e4451" },
                    light: { bg: "#fafafa", active: "#4078f2", text: "#383a42", subtext: "#696c77", border: "#d3d3d3" }
                },
                {
                    name: "Solarized",
                    dark:  { bg: "#002b36", active: "#268bd2", text: "#839496", subtext: "#586e75", border: "#073642" },
                    light: { bg: "#fdf6e3", active: "#268bd2", text: "#657b83", subtext: "#93a1a1", border: "#eee8d5" }
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

                            readonly property var dark: presetData.dark
                            readonly property var light: presetData.light

                            readonly property bool isDarkSelected:
                                PrefsService.overrideBg.toLowerCase() === dark.bg.toLowerCase() &&
                                PrefsService.overrideActive.toLowerCase() === dark.active.toLowerCase()

                            readonly property bool isLightSelected:
                                PrefsService.overrideBg.toLowerCase() === light.bg.toLowerCase() &&
                                PrefsService.overrideActive.toLowerCase() === light.active.toLowerCase()

                            readonly property bool isSelected: isDarkSelected || isLightSelected

                            Column {
                                id: presetCol
                                width: parent.width
                                spacing: Math.round(5 * root.localScale)

                                // Tile Layout Structure
                                Item {
                                    id: tileRoot
                                    width: parent.width
                                    height: Math.round(42 * root.localScale)
                                    clip: true

                                    // 1. Base Layer: Diagonal Split Canvas
                                    Canvas {
                                        id: splitCanvas
                                        anchors.fill: parent
                                        
                                        canvasSize: Qt.size(width, height)
                                        
                                        property string darkBg:  presetDelegate.dark.bg
                                        property string lightBg: presetDelegate.light.bg
                                        property int r: Math.round(8 * root.localScale)

                                        onDarkBgChanged:  requestPaint()
                                        onLightBgChanged: requestPaint()
                                        onWidthChanged:   requestPaint()
                                        onHeightChanged:  requestPaint()

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            
                                            // Utilize precise local references to ensure paint dimensions 
                                            // match the fully realized geometry state.
                                            var w = splitCanvas.width;
                                            var h = splitCanvas.height;
                                            var rad = splitCanvas.r;

                                            // Fully wipe internal context state on dynamic resizes
                                            ctx.reset();
                                            ctx.clearRect(0, 0, w, h);

                                            ctx.beginPath();
                                            ctx.moveTo(rad, 0);
                                            ctx.lineTo(w - rad, 0);
                                            ctx.arcTo(w, 0, w, rad, rad);
                                            ctx.lineTo(w, h - rad);
                                            ctx.arcTo(w, h, w - rad, h, rad);
                                            ctx.lineTo(rad, h);
                                            ctx.arcTo(0, h, 0, h - rad, rad);
                                            ctx.lineTo(0, rad);
                                            ctx.arcTo(0, 0, rad, 0, rad);
                                            ctx.closePath();
                                            ctx.clip();

                                            // Dark variant — upper-left triangle
                                            ctx.beginPath();
                                            ctx.moveTo(0, 0);
                                            ctx.lineTo(w, 0);
                                            ctx.lineTo(0, h);
                                            ctx.closePath();
                                            ctx.fillStyle = darkBg;
                                            ctx.fill();

                                            // Light variant — lower-right triangle
                                            ctx.beginPath();
                                            ctx.moveTo(w, 0);
                                            ctx.lineTo(w, h);
                                            ctx.lineTo(0, h);
                                            ctx.closePath();
                                            ctx.fillStyle = lightBg;
                                            ctx.fill();

                                            // Diagonal hairline divider
                                            ctx.beginPath();
                                            ctx.moveTo(0, h);
                                            ctx.lineTo(w, 0);
                                            ctx.strokeStyle = "rgba(0,0,0,0.25)";
                                            ctx.lineWidth = 1;
                                            ctx.stroke();
                                        }
                                    }

                                    Row {
                                        id: darkSwatches
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.leftMargin: Math.round(5 * root.localScale)
                                        anchors.topMargin: Math.round(6 * root.localScale)
                                        spacing: Math.round(3 * root.localScale)

                                        Repeater {
                                            model: [presetDelegate.dark.border, presetDelegate.dark.active, presetDelegate.dark.text]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: Math.round(9 * root.localScale)
                                                height: width
                                                radius: width / 2
                                                color: modelData
                                                border.color: Qt.rgba(0, 0, 0, 0.3)
                                                border.width: 1
                                            }
                                        }
                                    }

                                    Row {
                                        id: lightSwatches
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.rightMargin: Math.round(5 * root.localScale)
                                        anchors.bottomMargin: Math.round(6 * root.localScale)
                                        spacing: Math.round(3 * root.localScale)

                                        Repeater {
                                            model: [presetDelegate.light.border, presetDelegate.light.active, presetDelegate.light.text]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: Math.round(9 * root.localScale)
                                                height: width
                                                radius: width / 2
                                                color: modelData
                                                border.color: Qt.rgba(0, 0, 0, 0.3)
                                                border.width: 1
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.round(8 * root.localScale) // Directly locks identical structural shape
                                        
                                        color: presetDelegate.isSelected
                                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                                            : (cardHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent")
                                            
                                        border.color: presetDelegate.isSelected
                                            ? Theme.active
                                            : (cardHover.hovered ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.35))
                                            
                                        border.width: presetDelegate.isSelected ? 2 : 1

                                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                                        Behavior on border.color { ColorAnimation { duration: Anim.fast } }
                                        Behavior on border.width  { NumberAnimation { duration: Anim.fast } }
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
                                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                                }
                            }

                            HoverHandler {
                                id: cardHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                id: tileClickArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: function(mouse) {
                                    var isUpperLeft = (mouse.x / width + mouse.y / height) < 1.0;
                                    var variant = isUpperLeft ? presetDelegate.dark : presetDelegate.light;
                                    
                                    PrefsService.overrideBg      = variant.bg;
                                    PrefsService.overrideActive  = variant.active;
                                    PrefsService.overrideText    = variant.text;
                                    PrefsService.overrideSubtext = variant.subtext;
                                    PrefsService.overrideBorder  = variant.border;
                                    PrefsService.overrideIcon      = variant.text;
                                    PrefsService.overrideIconFont  = variant.active;
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
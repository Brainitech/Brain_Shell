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

import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../"
import "../../components"
import "../../components/sliders"
import "../"

// Right column — brightness slider + scrollable quick-settings grid.

StatCard {
    id: root
    padding: 0
    focus: true

    property real localScale: 1.0

    // ─────────────────────────────────────────────────────────────────────────
    //  Focus Mode  (hyprctl gaps)
    // ─────────────────────────────────────────────────────────────────────────
    property int _savedGapsIn: 5
    property int _savedGapsOut: 10

    function _focusToggle() {
        if (ShellState.focusMode) {
            WM.setGaps(root._savedGapsIn, root._savedGapsOut)
            ShellState.focusMode = false
        } else {
            root._savedGapsIn = WM.gapsIn > 0 ? WM.gapsIn : 5
            root._savedGapsOut = PrefsService.outerGaps > 0 ? PrefsService.outerGaps : (WM.gapsOut > 0 ? WM.gapsOut : 10)
            WM.setGaps(0, 10)
            ShellState.focusMode = true
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Theme Mode Process
    // ─────────────────────────────────────────────────────────────────────────
    property var sysThemeProc: Process {}

    // ─────────────────────────────────────────────────────────────────────────
    //  Hotspot Manager Component
    // ─────────────────────────────────────────────────────────────────────────
    QuickHotspotManager {
        id: hotspotManager
        wifiOn: WifiService.wifiOn
        onWifiStateChanged: function(on) {
            WifiService.setWifiState(on)
        }
        onRequestWifiPoll: WifiService.poll()
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  UI
    // ─────────────────────────────────────────────────────────────────────────
    Column {
        anchors { fill: parent; margins: Math.round(12 * localScale) }
        spacing: 0

        // ── Integrated Brightness Slider ──────────────────────────────────────
        QuickBrightnessSlider {
            width: parent.width
            localScale: root.localScale
        }

        Rectangle {
            width: parent.width; height: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        }
        Item { width: parent.width; height: Math.round(8 * localScale) }

        Text {
            id: qsLbl; width: parent.width
            text: "QUICK SETTINGS"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold
            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
        }
        Item { width: parent.width; height: Math.round(8 * localScale) }

        // ── Tile grid ─────────────────────────────────────────────────────────
        Item {
            width:  parent.width
            height: root.height - Math.round(12 * localScale) - Math.round(52 * localScale) - 1 - Math.round(8 * localScale) - qsLbl.height - Math.round(8 * localScale)

            Flickable {
                id: flick
                anchors.fill:   parent
                contentWidth:   width
                contentHeight:  tileGrid.implicitHeight + Math.round(8 * localScale)
                clip:           true
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: tileGrid
                    width: flick.width
                    columns: 2; spacing: Math.round(6 * localScale)

                    readonly property real btnW: (width - spacing) / 2
                    readonly property real btnH: btnW * 0.85

                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: WifiService.wifiOn && !hotspotManager.hotspotOn
                        icon: (WifiService.wifiOn && !hotspotManager.hotspotOn) ? "󰤨" : "󰤭"; label: "Wi-Fi"
                        sublabel: (WifiService.wifiOn && !hotspotManager.hotspotOn) && WifiService.wifiSSID !== "" ? WifiService.wifiSSID : (hotspotManager.hotspotOn ? "Used by Hotspot" : "")
                        onToggled: WifiService.toggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: BluetoothService.btOn; icon: BluetoothService.btOn ? "󰂱" : "󰂲"; label: "Bluetooth"
                        sublabel: BluetoothService.btOn && BluetoothService.btDevice !== "" ? BluetoothService.btDevice : ""
                        onToggled: BluetoothService.toggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: AirplaneService.airplaneOn; icon: "󰀝"; label: "Airplane Mode"
                        onToggled: AirplaneService.toggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: hotspotManager.hotspotOn || hotspotManager.hotspotBusy
                        icon: "󰀃"
                        label: "Hotspot"
                        sublabel: hotspotManager.hotspotLabel
                        onToggled: hotspotManager.toggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: WM.nightLightOn; icon: "󰖐"; label: "Night Light"
                        onToggled: WM.toggleNightLight()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: CaffeineService.caffeineOn; icon: "󰅶"; label: "Caffeine"
                        onToggled: CaffeineService.toggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: ShellState.focusMode
                        icon: ShellState.focusMode ? "󱃕" : "󰍻"; label: "Focus Mode"
                        onToggled: root._focusToggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: ShellState.dnd; icon: ShellState.dnd ? "󰂛" : "󰂚"
                        label: "Do Not Disturb"
                        onToggled: ShellState.dnd = !ShellState.dnd
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on:    ShellState.screenRecord || ScreenRecService.recording
                        icon:  ScreenRecService.recording ? "⏹" : "󰻂"
                        label: ScreenRecService.recording ? "Recording" : "Screen Capture"
                        onToggled: {
                            if (ScreenRecService.recording) {
                                ScreenRecService.stopRecording()
                            } else if (ShellState.screenRecord) {
                                ScreenRecService.cancelSetup()
                            } else {
                                capturePicker.toggle()
                            }
                        }
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on:       filterPicker.currentFilter !== ""
                        icon:     "󱡓"
                        label:    "Filter"
                        sublabel: filterPicker.currentFilter !== "" ? filterPicker.currentFilter : ""
                        onToggled: filterPicker.open()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: ColorPickerService.picking
                        icon: "󰈊"
                        label: "Picker"
                        sublabel: ColorPickerService.format
                        onToggled: ColorPickerService.pick()
                        onRightToggled: ColorPickerService.cycleFormat()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: PrefsService.darkMode
                        icon: PrefsService.darkMode ? "󰔎" : "󰖨"
                        label: "Theme Mode"
                        sublabel: PrefsService.darkMode ? "Dark Scheme" : "Light Scheme"
                        onToggled: {
                            PrefsService.darkMode = !PrefsService.darkMode
                            PrefsService.saveConfig()
                            sysThemeProc.command = ["bash", "-c", "gsettings set org.gnome.desktop.interface color-scheme " + (PrefsService.darkMode ? "'prefer-dark'" : "'prefer-light'")]
                            sysThemeProc.running = false; sysThemeProc.running = true
                            if (WallpaperService.currentWall !== "") {
                                WallpaperService.apply(WallpaperService.currentWall)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Floating Subcomponent Pickers ─────────────────────────────────────────
    QuickFilterPicker {
        id: filterPicker
        localScale: root.localScale
    }

    QuickScreenCapturePicker {
        id: capturePicker
        localScale: root.localScale
    }

    TapHandler {
        enabled: filterPicker.isOpen || capturePicker.isOpen
        onTapped: {
            filterPicker.close()
            capturePicker.close()
        }
    }
}

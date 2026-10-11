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
    //  Wi-Fi
    // ─────────────────────────────────────────────────────────────────────────
    property bool   wifiOn:   false
    property string wifiSSID: ""

    Process { id: wifiRadioRead; command: ["bash", "-c", "nmcli radio wifi"]; running: false
        stdout: SplitParser { onRead: function(l) {
            root.wifiOn = l.trim() === "enabled"
            ShellState.wifiOn = root.wifiOn && !ShellState.hotspot
        } } }
    Process { id: wifiSSIDRead
        command: ["bash", "-c",
            "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser { onRead: function(l) { root.wifiSSID = l.trim() } } }
    Process { id: wifiToggleProc; command: []; running: false
        onRunningChanged: if (!running) _wifiPoll() }
    function _wifiPoll() {
        wifiRadioRead.running = false; wifiRadioRead.running = true
        wifiSSIDRead.running  = false; wifiSSIDRead.running  = true
    }
    function _wifiToggle() {
        if (hotspotManager.hotspotOn || hotspotManager.hotspotBusy) return
        root.wifiOn = !root.wifiOn
        ShellState.wifiOn = root.wifiOn
        wifiToggleProc.command = ["bash", "-c",
            "nmcli radio wifi " + (root.wifiOn ? "on" : "off")]
        wifiToggleProc.running = false
        wifiToggleProc.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Bluetooth
    // ─────────────────────────────────────────────────────────────────────────
    property bool   btOn:     false
    property string btDevice: ""

    Process { id: btPowerRead
        command: ["bash", "-c",
            "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser { onRead: function(l) {
            root.btOn = l.trim() === "yes"
            ShellState.btPowered = root.btOn
        } } }
    Process { id: btDeviceRead
        command: ["bash", "-c",
            "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser { onRead: function(l) {
            root.btDevice = l.trim()
            ShellState.btConnected = (root.btDevice !== "")
        } } }
    Process { id: btToggleProc; command: []; running: false
        onRunningChanged: if (!running) {
            _btPoll()
            ShellState.btPowered = root.btOn
            if (!root.btOn) ShellState.btConnected = false
        }
    }        
    function _btPoll() {
        btPowerRead.running  = false; btPowerRead.running  = true
        btDeviceRead.running = false; btDeviceRead.running = true
    }
    function _btToggle() {
        var turningOn = !root.btOn
        root.btOn = turningOn
        ShellState.btPowered = turningOn
        if (!turningOn) ShellState.btConnected = false

        btToggleProc.command = ["bash", "-c",
            "bluetoothctl power " + (turningOn ? "on" : "off")]
        btToggleProc.running = false
        btToggleProc.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Night Light  (hyprsunset)
    // ─────────────────────────────────────────────────────────────────────────
    property bool nightLightOn: false

    Process { id: nlCheck; command: ["bash", "-c", "pgrep -x hyprsunset"]; running: false
        stdout: SplitParser { onRead: function(l) { if (l.trim() !== "") root.nightLightOn = true } } }
    Process { id: nlProc; command: ["hyprsunset", "-t", "5600"]; running: false }
    Process { id: nlKill; command: ["bash", "-c", "pkill hyprsunset"]; running: false }
    function _nightLightToggle() {
        if (root.nightLightOn) {
            nlProc.running = false; nlKill.running = false; nlKill.running = true
            root.nightLightOn = false
        } else { nlProc.running = true; root.nightLightOn = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Caffeine  (systemd-inhibit)
    // ─────────────────────────────────────────────────────────────────────────
    property bool caffeineOn: false

    Process { id: caffeineCheck
        command: ["bash", "-c", "pgrep -f 'systemd-inhibit.*Caffeine'"]; running: false
        stdout: SplitParser { onRead: function(l) { if (l.trim() !== "") root.caffeineOn = true } } }
    Process { id: caffeineProc
        command: ["systemd-inhibit","--what=idle:sleep",
                  "--who=Brain Shell","--why=Caffeine mode","sleep","infinity"]
        running: false }
    Process { id: caffeineKill
        command: ["bash", "-c", "pkill -f 'systemd-inhibit.*Caffeine'"]; running: false
        onRunningChanged: if (!running) root.caffeineOn = false }
    function _caffeineToggle() {
        if (root.caffeineOn) {
            caffeineProc.running = false
            caffeineKill.running = false; caffeineKill.running = true
        } else { caffeineProc.running = true; root.caffeineOn = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Do Not Disturb
    // ─────────────────────────────────────────────────────────────────────────
    function _dndToggle() {
        ShellState.dnd = !ShellState.dnd
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Hotspot Manager Component
    // ─────────────────────────────────────────────────────────────────────────
    QuickHotspotManager {
        id: hotspotManager
        wifiOn: root.wifiOn
        onWifiStateChanged: function(on) {
            root.wifiOn = on
            ShellState.wifiOn = on
        }
        onRequestWifiPoll: root._wifiPoll()
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Airplane Mode  (rfkill)
    // ─────────────────────────────────────────────────────────────────────────
    property bool airplaneOn: false

    Process { id: airplaneCheck
        command: ["bash", "-c",
            "notBlocked=$(rfkill list all 2>/dev/null | grep -c 'Soft blocked: no');" +
            " total=$(rfkill list all 2>/dev/null | grep -c 'Soft blocked:');" +
            " [ \"$total\" -gt 0 ] && [ \"$notBlocked\" -eq 0 ] && echo yes || echo no"]
        running: false
        stdout: SplitParser {
            onRead: function(l) { root.airplaneOn = l.trim() === "yes" }
        }
    }
    Process { id: airplaneOn_proc
        command: ["bash", "-c", "rfkill block all"]; running: false
        onRunningChanged: if (!running) root.airplaneOn = true }
    Process { id: airplaneOff_proc
        command: ["bash", "-c", "rfkill unblock all"]; running: false
        onRunningChanged: if (!running) root.airplaneOn = false }
    function _airplaneToggle() {
        if (root.airplaneOn) {
            airplaneOff_proc.running = false; airplaneOff_proc.running = true
        } else {
            airplaneOn_proc.running = false; airplaneOn_proc.running = true
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Focus Mode  (hyprctl gaps)
    // ─────────────────────────────────────────────────────────────────────────
    property int _savedGapsIn: 5; property int _savedGapsOut: 10

    Process { id: readGapsIn
        command: ["bash", "-c",
            "hyprctl getoption general:gaps_in -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',5))\""]
        running: false
        stdout: SplitParser { onRead: function(l) { var v=parseInt(l.trim()); if(!isNaN(v)) root._savedGapsIn=v } }
        onRunningChanged: if (!running) readGapsOut.running = true }
    Process { id: readGapsOut
        command: ["bash", "-c",
            "hyprctl getoption general:gaps_out -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',10))\""]
        running: false
        stdout: SplitParser { onRead: function(l) { var v=parseInt(l.trim()); if(!isNaN(v)) root._savedGapsOut=v } }
        onRunningChanged: if (!running) applyFocusGaps.running = true }
    Process { id: applyFocusGaps
        command: ["bash", "-c",
            "hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 10"]
        running: false; onRunningChanged: if (!running) ShellState.focusMode = true }
    Process { id: restoreGaps; command: []; running: false
        onRunningChanged: if (!running) ShellState.focusMode = false }
    function _focusToggle() {
        if (ShellState.focusMode) {
            restoreGaps.command = ["bash", "-c",
                "hyprctl keyword general:gaps_in "  + root._savedGapsIn  +
                " && hyprctl keyword general:gaps_out " + root._savedGapsOut]
            restoreGaps.running = false; restoreGaps.running = true
        } else { readGapsIn.running = false; readGapsIn.running = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Color Picker
    // ─────────────────────────────────────────────────────────────────────────
    property string pickerFormat: "HEX"
    property var sysThemeProc: Process {}

    function _pickerLaunch() {
        Popups.colorPickerActive = true;
        var fmt = root.pickerFormat;
        
        pickerProc.command = ["bash", "-c",
            "geom=$(slurp -p -b 00000000 -c 00000000 2>/dev/null) || exit 0; " +
            "rgb=$(grim -g \"$geom\" -t ppm - 2>/dev/null | tail -c 3 | od -An -t u1) || exit 0; " +
            "res=$(echo \"$rgb\" | awk -v fmt=\"" + fmt + "\" '{" +
            "  r=$1+0; g=$2+0; b=$3+0; " +
            "  if(fmt==\"RGB\") printf \"rgb(%d, %d, %d)\",r,g,b; " +
            "  else if(fmt==\"HSL\"){ " +
            "    rf=r/255;gf=g/255;bf=b/255; mx=rf;mn=rf; " +
            "    if(gf>mx)mx=gf; if(bf>mx)mx=bf; if(gf<mn)mn=gf; if(bf<mn)mn=bf; " +
            "    l=(mx+mn)/2; if(mx==mn){h=0;sv=0} else { d=mx-mn; " +
            "    sv=(l>0.5)?d/(2-mx-mn):d/(mx+mn); " +
            "    if(mx==rf)h=(gf-bf)/d+(gf<bf?6:0); else if(mx==gf)h=(bf-rf)/d+2; else h=(rf-gf)/d+4; h=h/6; } " +
            "    printf \"hsl(%d, %d%%, %d%%)\",int(h*360+0.5),int(sv*100+0.5),int(l*100+0.5); " +
            "  } else { " +
            "    printf \"#%02x%02x%02x\",r,g,b; " +
            "  } " +
            "}'); " +
            "if [ -n \"$res\" ]; then " +
            "  printf '%s' \"$res\" | { if command -v wl-copy >/dev/null 2>&1; then setsid -f wl-copy; else wl-copy; fi; }; " +
            "  echo \"$res\"; " +
            "fi"
        ];
        
        pickerProc.running = false;
        pickerProc.running = true;
    }
    property var pickerProc: Process {
        onExited: Popups.colorPickerActive = false
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Polling timer
    // ─────────────────────────────────────────────────────────────────────────
    Timer {
        interval: 5000; running: Popups.dashboardOpen; repeat: true
        onTriggered: {
            _wifiPoll(); _btPoll()
            hotspotManager.poll()
            airplaneCheck.running = false; airplaneCheck.running = true
            if (hotspotManager.hotspotOn && !hotspotManager.hotspotBusy) {
                hotspotManager.checkEthernetLive()
            }
        }
    }

    Component.onCompleted: {
        _wifiPoll(); _btPoll()
        nlCheck.running         = true
        caffeineCheck.running   = true
        airplaneCheck.running   = true
        hotspotManager.init()
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
                        on: root.wifiOn && !hotspotManager.hotspotOn
                        icon: (root.wifiOn && !hotspotManager.hotspotOn) ? "󰤨" : "󰤭"; label: "Wi-Fi"
                        sublabel: (root.wifiOn && !hotspotManager.hotspotOn) && root.wifiSSID !== "" ? root.wifiSSID : (hotspotManager.hotspotOn ? "Used by Hotspot" : "")
                        onToggled: root._wifiToggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: root.btOn; icon: root.btOn ? "󰂱" : "󰂲"; label: "Bluetooth"
                        sublabel: root.btOn && root.btDevice !== "" ? root.btDevice : ""
                        onToggled: root._btToggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: root.airplaneOn; icon: "󰀝"; label: "Airplane Mode"
                        onToggled: root._airplaneToggle()
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
                        on: root.nightLightOn; icon: "󰖐"; label: "Night Light"
                        onToggled: root._nightLightToggle()
                    }
                    QuickToggleTile {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        localScale: root.localScale
                        on: root.caffeineOn; icon: "󰅶"; label: "Caffeine"
                        onToggled: root._caffeineToggle()
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
                        onToggled: root._dndToggle()
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
                        on: false
                        icon: "󰈊"
                        label: "Picker"
                        sublabel: root.pickerFormat
                        onToggled: root._pickerLaunch()
                        onRightToggled: {
                            if (root.pickerFormat === "HEX") root.pickerFormat = "RGB";
                            else if (root.pickerFormat === "RGB") root.pickerFormat = "HSL";
                            else root.pickerFormat = "HEX";
                        }
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

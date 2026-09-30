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
import Quickshell
import Quickshell.Wayland
import "../services"
import "../state"
import "../"

PanelWindow {
    id: root
    
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    visible: MigrationService.isMigrating

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive // Block all keyboard interaction
    
    // Dim background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        
        // Consume all clicks
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
            onWheel: (wheel) => {}
        }
        
        Column {
            anchors.centerIn: parent
            spacing: Math.round(24 * root.localScale)
            
            Text {
                text: "Updating Architecture..."
                font.pixelSize: Math.round(24 * root.localScale)
                font.weight: Font.Bold
                color: Theme.text
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Backing up and migrating your configuration to v0.2.0.\nPlease wait, this will only take a moment."
                font.pixelSize: Math.round(14 * root.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}

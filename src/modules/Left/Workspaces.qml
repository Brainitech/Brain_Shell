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
import "../../"

Rectangle {
    id: root
    
    property real localScale: 1.0

    // --- 1. Capsule Container ---
    color: Theme.wsBackground
    radius: Math.round(Theme.wsRadius * localScale)

    // Auto-size
    width: workspaceRow.width + Math.round(Theme.wsPadding * 2 * localScale)
    height: Math.round(Theme.wsDotSize * localScale) + Math.round(Theme.wsPadding * 2 * localScale)

    // --- 2. State & Scroll Cooldown ---
    readonly property bool isScratchpad: WM.isScratchpad
    property bool scrollBusy: false

    Timer {
        id: scrollCooldown
        interval: 300
        repeat: false
        onTriggered: root.scrollBusy = false
    }
    
    // --- Wheel: cycle through occupied workspaces ---
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (root.scrollBusy) return;
            root.scrollBusy = true;
            scrollCooldown.restart();
            // Inverted scroll logic: Up (>0) goes to Next (+1), Down (<0) goes to Prev (-1)
            WM.cycleWorkspace(event.angleDelta.y < 0 ? 1 : -1);
        }
    }
    
    
    // --- 3. Workspace Dots ---
    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Math.round(Theme.wsSpacing * localScale)

        // Logic: Fade out dots when Scratchpad is active
        opacity: root.isScratchpad ? 0 : 1
        scale:   root.isScratchpad ? 0.8 : 1
        visible: opacity > 0 

        Behavior on opacity { NumberAnimation { duration: Anim.normal} }
        Behavior on scale   { NumberAnimation { duration: Anim.normal} }

        Repeater {
            model: 10 
            delegate: Rectangle {
                id: dot
                
                property var ws: WM.workspaces.find(w => w.id === index + 1)
                property bool isActive: WM.focusedWorkspaceId === (index + 1)
                property bool isOccupied: ws !== undefined
                property bool isUrgent:   ws !== undefined && ws.urgent


                height: Math.round(Theme.wsDotSize * localScale)
                radius: height / 2
                width: isActive ? Math.round(Theme.wsActiveWidth * localScale) : Math.round(Theme.wsDotSize * localScale)
                
                color: {
                    if (isActive)   return Theme.wsActive
                    if (isUrgent)   return Theme.wsUrgent
                    if (isOccupied) return Theme.wsOccupied
                    return Theme.wsEmpty
                }

                Behavior on width { NumberAnimation { duration: Anim.normal; easing.type: Anim.outBack; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }
                Behavior on color { ColorAnimation { duration: Anim.normal} }

                // --- Urgent pulse ---
                SequentialAnimation {
                    running: dot.isUrgent && !dot.isActive
                    loops:   Animation.Infinite

                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.35
                        duration: Anim.slower
                        easing.type: Anim.inOutSine
                    }
                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.0
                        duration: Anim.slower
                        easing.type: Anim.inOutSine
                    }
                }

                // Reset scale when no longer urgent
                onIsUrgentChanged: {
                    if (!isUrgent) scale = 1.0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WM.switchWorkspace(index + 1)
                }
            }
        }
    }

    // --- 4. Scratchpad Overlay ---
    Rectangle {
        id: overlay
        anchors.fill: parent
        radius: root.radius
        color: Theme.wsOverlay
        z: 99
        
        // Logic: Fade in overlay when Scratchpad is active
        visible: opacity > 0
        opacity: root.isScratchpad ? 1 : 0
        
        Behavior on opacity { NumberAnimation { duration: Anim.normal} }
        
        Text {
            anchors.centerIn: parent
            text: "" 
            color: Theme.text
            font.pixelSize: Math.round(14 * localScale)
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: WM.toggleScratchpad("magic")
        }
    }
}

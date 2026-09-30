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
import "../components"
import "../"

Item {
    id: root
    Keys.onEscapePressed: SurfaceState.close()
    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    
    // Physical state properties injected by DynamicSurface
    property var screen
    property real localScale: 1.0

    readonly property int popupWidth:  Math.round(Theme.networkPopupWidth * root.localScale)
    readonly property int popupHeight: Math.round(648 * root.localScale)
        
    property string page: Popups.networkPage

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: Popups.networkPinned = true
    }

    Item {
        id: hoverContainer
        anchors.fill: parent

        Item {
            id: sizer
            anchors.fill: parent
            clip: true
    
            
    
            Item {
                id: contentArea
                anchors {
                    fill:         parent
                    topMargin:    Math.round(8 * root.localScale)
                    leftMargin:   Math.round(8 * root.localScale)
                    rightMargin:  Math.round(8 * root.localScale)
                    bottomMargin: Math.round(8 * root.localScale)
                }
    
                opacity: (SurfaceState.activeContent === "network") ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: (SurfaceState.activeContent === "network")
                            ? Anim.transition * 0.5
                            : Anim.transition * 0.15
                    }
                }
    
                Column {
                    anchors.fill: parent
                    spacing: 0

                    // ── Tab bar ───────────────────────────────────────────────────────
                    TabSwitcher {
                        id: tabBar
                        localScale: root.localScale || 1.0
                        width: parent.width
                        orientation: "horizontal"
                        currentPage: root.page
                        model: [
                            { key: "wifi",      icon: "󰤨", label: "Wi-Fi"     },
                            { key: "bluetooth", icon: "󰂯", label: "Bluetooth" },
                            { key: "vpn",       icon: "󰦝", label: "VPN"       },
                            { key: "hotspot",   icon: "󰀃", label: "Hotspot"   },
                        ]
                        onPageChanged: function(key) { Popups.networkPage = key }
                    }

                    // ── Tab page area ─────────────────────────────────────────────────
                    Item {
                        id: tabContent
                        clip: true
                        width: parent.width
                        height: parent.height - tabBar.height
                        
                        property int pageIdx: Math.max(0, ["wifi", "bluetooth", "vpn", "hotspot"].indexOf(root.page))
                        property int oldIdx: pageIdx
                        property int newIdx: pageIdx
                        property real progress: 1.0
                        
                        NumberAnimation {
                            id: progressAnim
                            target: tabContent
                            property: "progress"
                            from: 0.0
                            to: 1.0
                            duration: Anim.style === "none" ? 0 : Anim.slow
                            easing.type: Anim.outExpo; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                        }
                        
                        onPageIdxChanged: {
                            oldIdx = newIdx;
                            newIdx = pageIdx;
                            progress = 0.0;
                            if (Anim.style !== "none") progressAnim.restart();
                            else progress = 1.0;
                        }

                        component NetworkTab: Loader {
                            property int myIdx
                            property string sourceFile
                            
                            property bool isIncoming: myIdx === tabContent.newIdx
                            property bool isOutgoing: myIdx === tabContent.oldIdx
                            property int slideDir: tabContent.newIdx > tabContent.oldIdx ? 1 : -1
                            property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                            
                            width: parent.width; height: parent.height
                            
                            x: {
                                if (Anim.style === "none" || Anim.style === "fade" || Anim.style === "scale" || Anim.style === "rise") return 0;
                                if (isIncoming) {
                                    return slideDir * width * (1.0 - tabContent.progress);
                                } else if (isOutgoing) {
                                    return -slideDir * width * parallaxFactor * tabContent.progress;
                                } else {
                                    return myIdx < tabContent.newIdx ? -width : width;
                                }
                            }
                            
                            opacity: {
                                if (Anim.style === "none" || Anim.style === "slide") return 1.0;
                            if (Anim.style === "scale" || Anim.style === "rise") { if (isIncoming) return tabContent.progress; if (isOutgoing) return 1.0 - tabContent.progress; return 0.0; }
                                if (isIncoming) return tabContent.progress;
                                if (isOutgoing) return 1.0 - tabContent.progress;
                                return 0.0;
                            }
                            
                            active: isIncoming || (isOutgoing && tabContent.progress < 1.0)
                            
                            y: {
                                if (Anim.style === "rise") {
                                    if (isIncoming) return 30 * (1.0 - tabContent.progress);
                                    if (isOutgoing) return -30 * tabContent.progress;
                                }
                                return 0;
                            }
                            
                            scale: {
                                if (Anim.style === "scale" || Anim.style === "rise") {
                                    if (isIncoming) return 0.95 + 0.05 * tabContent.progress;
                                    if (isOutgoing) return 1.0 + 0.05 * tabContent.progress;
                                }
                                return 1.0;
                            }
                            
                            visible: active
                            
                            source: sourceFile
                            onLoaded: item.localScale = root.localScale
                        }
                        
                        NetworkTab { myIdx: 0; sourceFile: "WifiTab.qml" }
                        NetworkTab { myIdx: 1; sourceFile: "BluetoothTab.qml" }
                        NetworkTab { myIdx: 2; sourceFile: "VPNTab.qml" }
                        NetworkTab { myIdx: 3; sourceFile: "HotspotTab.qml" }
                    }
            }
        }
    }
}
}
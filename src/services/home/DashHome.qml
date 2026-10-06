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
import Quickshell.Io
import "../"
import "../../components"
import "../../popups/dashboard_tabs"
import "../../"

// Dashboard Home tab — layout only.
//
//  ┌──────────────┬───────────────────────────┬──────────────┐
//  │ ProfileCard  │  ClockCard                │              │
//  ├──────────────┤                           │ QuickSettings│
//  │ CalendarCard │  PlayerCard               │ (brightness  │
//  │              │                           │  + toggles)  │
//  └──────────────┴───────────────────────────┴──────────────┘

Item {
    id: root

    property real localScale: 1.0

    readonly property int colW:     Math.round(210 * localScale)
    readonly property int gap:      Math.round(8 * localScale)
    readonly property int profileH: Math.round(160 * localScale)
    readonly property int clockH:   Math.round(220 * localScale)

    property string _avatarPath: ""
    property string _staticJpg:  ""   // resolved once: $HOME/.curr_wall_static.jpg

    function _updateAvatar() {
        if (PrefsService.customAvatarPath !== "") {
            var p = PrefsService.customAvatarPath
            if (p.startsWith("~")) p = p.replace(/^~/, Quickshell.env("HOME"))
            root._avatarPath = p
        } else if (root._staticJpg !== "") {
            root._avatarPath = root._staticJpg
        } else {
            root._avatarPath = ""
        }
    }
    
    Connections {
        target: PrefsService
        function onCustomAvatarPathChanged() {
            root._updateAvatar()
        }
    }

    // Resolve $HOME once, then set the fixed path.
    // Both gif (magick frame) and non-gif (symlink) cases now land at the
    // same ~/.curr_wall_static.jpg so no readlink resolution is needed.
    Process {
        command: ["bash", "-c", "echo $HOME"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var h = line.trim()
                if (h === "") return
                root._staticJpg  = h + "/.curr_wall_static.jpg"
                root._updateAvatar()
            }
        }
    }

    // Re-arm the image on every successful apply.
    Connections {
        target: WallpaperService
        function onWallpaperApplied(path) {
            root._avatarPath = ""
            reloadTimer.restart()
        }
    }

    Timer {
        id: reloadTimer
        interval: 0
        repeat:   false
        onTriggered: root._updateAvatar()
    }

    Component.onCompleted: {
        root._updateAvatar()
    }

    // ── Left column ───────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW

        ProfileCard {
            id: profileCard
            localScale: root.localScale
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH
            avatarPath: root._avatarPath
        }

        CalendarCard {
            localScale: root.localScale
            anchors {
                left: parent.left; right: parent.right
                top: profileCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }

    // ── Right column — QuickSettings fills full height ────────────────────────
    QuickSettings {
        id: rightCard
        localScale: root.localScale
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW
    }

    // ── Center column ─────────────────────────────────────────────────────────
    Item {
        id: centerCol
        anchors {
            left:  leftCol.right;  leftMargin:  root.gap
            right: rightCard.left; rightMargin: root.gap
            top:   parent.top;     bottom:      parent.bottom
            topMargin: root.gap
        }

        ClockCard {
            id: clockCard
            localScale: root.localScale
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.clockH
        }

        PlayerCard {
            localScale: root.localScale
            anchors {
                left:   parent.left;  right:  parent.right
                top:    clockCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }
}

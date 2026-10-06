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
import "../services/"
import "../"

Item {
    id: root
    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    property real localScale: 1.0

    readonly property int popupWidth:   Math.round(Theme.notificationsWidth * root.localScale)
    readonly property int maxHeight:    Math.round(700 * root.localScale)
            readonly property int animDuration: Anim.transition

    implicitWidth:  popupWidth
    implicitHeight: maxHeight



    // ── Content ─────────────────────────────────────────
    property int targetHeight: Math.min(
        Math.round(700 * root.localScale),
        notifList.height + Math.round(Theme.popupPadding * 2 * root.localScale) + Math.round(8 * root.localScale)
    )

    Item {
        anchors.fill: parent
        anchors.topMargin: Math.round(8 * root.localScale)
        anchors.leftMargin: Math.round(8 * root.localScale)
        anchors.rightMargin: Math.round(8 * root.localScale)
        anchors.bottomMargin: Math.round(8 * root.localScale)

        MouseArea { 
            anchors.fill: parent
            onClicked: {
                SurfaceState.open("right", "notifications")
                Popups.notificationsPinned = true
            }
        }

        opacity: (SurfaceState.activeContent === "notifications") ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: (SurfaceState.activeContent === "notifications") ? root.animDuration * 0.5 : root.animDuration * 0.15
            }
        }

        NotificationList {
            id:    notifList
            localScale: root.localScale
            width: parent.width
        }
    }
}

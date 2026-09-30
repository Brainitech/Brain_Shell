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
import "../../components"
import "../../"

Item {
    id: root
    property real localScale: 1.0
    height: parent.height

    // The TopBar State handles expanding the notch for notifications/network/toasts
    implicitWidth: contentRow.implicitWidth

    implicitHeight: parent.height

    // ── Normal content — fades out when any right popup opens ─────────────────
    Row {
        id: contentRow
        anchors.right: parent.right
        anchors.rightMargin: SurfaceState.isRightExpanded ? Math.round(-20 * localScale) : 0
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: Math.round(6 * localScale)

        opacity: SurfaceState.isRightExpanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }
        Behavior on anchors.rightMargin { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }

        Network{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Audio{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Battery{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Clock{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        SysTray{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Notifications{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

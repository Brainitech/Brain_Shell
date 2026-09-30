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
import "../../services"
import "../../"

Item {
    property real localScale: 1.0
    // Set to true to always show percentage beside the icon.
    // When false (default), percentage only shows on hover.
    property bool showPercentage: PrefsService.alwaysShowBatteryPercentage

    implicitWidth:  status.implicitWidth
    implicitHeight: status.implicitHeight
    
    visible: ShellState.hasBattery

    BatteryStatus {
        id:               status
        localScale:       parent.localScale
        anchors.centerIn: parent
        showPercentage:   parent.showPercentage
    }

    // MouseArea {
    //     anchors.fill: parent
    //     onClicked: {
    //         Popups.closeAll()
    //         SurfaceState.toggle("right", "battery")
    //     }
    // }
}

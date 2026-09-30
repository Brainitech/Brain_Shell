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

pragma Singleton
import QtQuick
import "."

QtObject {
    // ── Bindings to Modular Singletons ────────────────────────────────────────
    // Note: property alias cannot point to other singletons, so we use direct bindings.
    
    // Colors
    property color background: Colors.background
    property color active:     Colors.active
    property color text:       Colors.text
    property color subtext:    Colors.subtext
    property color icon:       Colors.icon
    property color border:     Colors.border
    property color iconFont:   Colors.iconFont
    property color error:      Colors.error
    property color errorSolid: Colors.errorSolid

    property color wsBackground: Colors.wsBackground
    property color wsActive:     Colors.wsActive
    property color wsOccupied:   Colors.wsOccupied
    property color wsEmpty:      Colors.wsEmpty
    property color wsOverlay:    Colors.wsOverlay
    property color wsUrgent:     Colors.wsUrgent

    // Metrics
    property bool barEnabled: Metrics.barEnabled
    
    property int borderWidth:   Metrics.borderWidth
    property int cornerRadius:  Metrics.cornerRadius
    property int notchHeight:   Metrics.notchHeight
        
    property int notchPadding:           Metrics.notchPadding
            
    property int lNotchMinWidth: Metrics.lNotchMinWidth
    property int lNotchMaxWidth: Metrics.lNotchMaxWidth
    property int cNotchMinWidth: Metrics.cNotchMinWidth
    property int cNotchMaxWidth: Metrics.cNotchMaxWidth
    property int rNotchMinWidth: Metrics.rNotchMinWidth
    property int rNotchMaxWidth: Metrics.rNotchMaxWidth

    property int dashboardWidth:  Metrics.dashboardWidth
    property int dashboardHeight: Metrics.dashboardHeight

    property int notificationsWidth: Metrics.notificationsWidth
    property int notificationToastWidth: Metrics.notificationToastWidth
    property int networkPopupWidth:  Metrics.networkPopupWidth

    property int popupMaxWidth:   Metrics.popupMaxWidth
    property int popupMaxHeight:  Metrics.popupMaxHeight
    property int popupPadding:     Metrics.popupPadding

    property int wsDotSize:     Metrics.wsDotSize
    property int wsActiveWidth: Metrics.wsActiveWidth
    property int wsSpacing:     Metrics.wsSpacing
    property int wsPadding:     Metrics.wsPadding
    property int wsRadius:      Metrics.wsRadius

}

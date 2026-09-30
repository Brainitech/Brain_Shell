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

Row {
	property real localScale: 1.0
	height:  parent.height
	spacing: Math.round(5 * localScale)
	// Note: Do NOT add anchors.centerIn: parent here. TopBar handles that.

	// 1. Arch Icon (Power Menu Trigger)
	ControlPanel{ 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	}

	// 2. Workspaces
	Workspaces { 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	} 
	
	//3. LayoutDisplay
	LayoutDisplayer { 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	}

}

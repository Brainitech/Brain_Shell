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
import "../../../components"
import "../../../"

Item {
    id: root
    property real localScale: 1.0

    width: parent ? parent.width : 400
    height: sizingGroup.height

    SettingsGroup {
        id: sizingGroup
        width: parent.width
        localScale: root.localScale
        title: "Surface & Window Styling"
        description: "Panel border thickness, corner roundness, and geometry."

        SettingsSlider {
            localScale: root.localScale
            text: "Border Width"
            description: "Thickness of panel borders."
            from: 0; to: 10; stepSize: 1; value: PrefsService.borderWidth
            defaultValue: 6
            onValueChanged: { if (value !== PrefsService.borderWidth) { PrefsService.borderWidth = value; PrefsService.saveConfig() } }
            valueSuffix: "px"
        }

        SettingsDivider { localScale: root.localScale }

        SettingsSlider {
            localScale: root.localScale
            text: "Global Roundness"
            description: "Global corner radius for popups, notches, and borders."
            from: 0; to: 20; stepSize: 2; value: PrefsService.cornerRadius
            defaultValue: 17
            onValueChanged: { if (value !== PrefsService.cornerRadius) { PrefsService.cornerRadius = value; PrefsService.saveConfig() } }
            valueSuffix: "px"
        }
    }
}

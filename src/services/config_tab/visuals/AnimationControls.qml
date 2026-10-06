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
    height: animGroup.height

    SettingsGroup {
        id: animGroup
        width: parent.width
        localScale: root.localScale
        title: "Motion & Animation"
        description: "Global transition styles, easing curves, and animation speed."

        SettingsButton {
            localScale: root.localScale
            text: "Animation Style"
            description: "Global transition style."
            inputType: "options"
            options: ["rise", "slide", "parallax", "fade", "scale", "none"]
            selectedOption: Anim.style
            buttonText: selectedOption
            defaultValue: "slide"
            onOptionSelected: function(opt) { if (opt !== Anim.style) Anim.setStyle(opt) }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsButton {
            localScale: root.localScale
            text: "Easing Curve"
            description: (Anim.curveStyle === "jello" && Anim.speedMultiplier > 0.5)
                         ? "The mathematical curve for animations. <font color='#FF5555'>(A lower animation speed is preferred)</font>"
                         : "The mathematical curve for animations."
            inputType: "options"
            options: ["smooth", "spring", "jello", "linear", "sharp", "cinematic"]
            selectedOption: Anim.curveStyle
            buttonText: selectedOption
            defaultValue: "smooth"
            onOptionSelected: function(opt) { if (opt !== Anim.curveStyle) Anim.setCurve(opt) }
        }

        SettingsDivider { localScale: root.localScale }

        SettingsSlider {
            localScale: root.localScale
            text: "Animation Speed"
            description: "Speed multiplier. Higher is faster."
            from: 0.1; to: 2.0; stepSize: 0.1; value: Anim.speedMultiplier
            defaultValue: 1.0
            onValueChanged: { if (value !== Anim.speedMultiplier) Anim.setSpeedMultiplier(value) }
            valueSuffix: "x"
        }
    }
}

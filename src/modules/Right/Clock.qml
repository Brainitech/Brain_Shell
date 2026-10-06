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
import "../../"

Text {
    id: clock
    property real localScale: 1.0

    text: Qt.formatDateTime(new Date(), "hh:mm")
    color: clockHov.hovered ? Theme.active : Theme.text
    Behavior on color { ColorAnimation { duration: Anim.color} }
    font.bold: true
    anchors.verticalCenter: parent.verticalCenter
    font.pixelSize: Math.round(16 * localScale)

    property int formatMode: 0

    state: "time"
    states: [
        State {
            name: "time"
            PropertyChanges { target: clock; formatMode: 0 }
        },
        State {
            name: "timeSeconds"
            PropertyChanges { target: clock; formatMode: 1 }
        },
        State {
            name: "date"
            PropertyChanges { target: clock; formatMode: 2 }
        }
    ]

    HoverHandler { id: clockHov }
    MouseArea {
        anchors.fill: parent
        acceptedButtons:     Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (clock.state === "time" || clock.state === "timeSeconds") {
                    clock.state = "date"
                } else if (clock.state === "date" || clock.state === "timeSeconds") {
                    clock.state = "time"
                }
            } else {
                if (clock.state === "time"|| clock.state === "date") {
                    clock.state = "timeSeconds"
                } else if (clock.state === "timeSeconds" || clock.state === "date") {
                    clock.state = "time"
                }
            }
            updateText()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateText()
    }

    function updateText() {
        let now = new Date()
        let tf = PrefsService.use24HourTime ? "hh:mm" : "h:mm ap"
        let tfs = PrefsService.use24HourTime ? "hh:mm:ss" : "h:mm:ss ap"
        switch(formatMode) {
            case 0:
                text = Qt.formatDateTime(now, tf)
                break
            case 1:
                text = Qt.formatDateTime(now, tfs)
                break
            case 2:
                text = Qt.formatDateTime(now, "dd-MM-yyyy")
                break
        }
    }
    
    Connections {
        target: PrefsService
        function onUse24HourTimeChanged() { updateText() }
    }

    Component.onCompleted: updateText()
}

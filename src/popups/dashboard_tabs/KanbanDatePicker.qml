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

Item {
    id: root

    property int  taskId: -1
    property real localScale: 1.0

    signal closed()

    property int  pickerYear:    0
    property int  pickerMonth:   0
    property int  pickerDay:     0     // 0 = date not selected
    property bool pickerHasTime: false
    property int  pickerTimeH:   12
    property int  pickerTimeM:   0
    property var  pickerDays:    []

    readonly property var _monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var _dowNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    onTaskIdChanged: {
        if (taskId >= 0) openPicker(taskId)
    }

    function openPicker(tId) {
        var now = new Date()
        root.pickerYear    = now.getFullYear()
        root.pickerMonth   = now.getMonth()
        root.pickerDay     = 0
        root.pickerHasTime = false
        root.pickerTimeH   = 12
        root.pickerTimeM   = 0

        var list = KanbanService.tasks
        for (var i = 0; i < list.length; i++) {
            if (list[i].id !== tId) continue
            var s = list[i].dueDate || ""
            if (s === "") break
            var dp2 = s.length >= 10 ? s.substring(0, 10) : ""
            var tp  = s.length >= 16 ? s.substring(11, 16) : ""
            if (dp2 !== "") {
                var p = dp2.split("-")
                root.pickerYear  = parseInt(p[0])
                root.pickerMonth = parseInt(p[1]) - 1
                root.pickerDay   = parseInt(p[2])
            }
            if (tp !== "") {
                var tParts = tp.split(":")
                root.pickerTimeH   = parseInt(tParts[0]) || 0
                root.pickerTimeM   = parseInt(tParts[1]) || 0
                root.pickerHasTime = true
            }
            break
        }
        rebuildPickerDays()
    }

    function rebuildPickerDays() {
        var firstDow   = new Date(root.pickerYear, root.pickerMonth, 1).getDay()
        var daysInMon  = new Date(root.pickerYear, root.pickerMonth + 1, 0).getDate()
        var daysInPrev = new Date(root.pickerYear, root.pickerMonth, 0).getDate()
        var days = []
        for (var p = firstDow - 1; p >= 0; p--)
            days.push({ n: daysInPrev - p, cur: false })
        for (var d = 1; d <= daysInMon; d++)
            days.push({ n: d, cur: true })
        var tail = 42 - days.length
        for (var t = 1; t <= tail; t++)
            days.push({ n: t, cur: false })
        root.pickerDays = days
    }

    onPickerYearChanged:  rebuildPickerDays()
    onPickerMonthChanged: rebuildPickerDays()

    function commitPicker() {
        if (root.taskId < 0) return
        var datePart = "", timePart = ""
        if (root.pickerDay > 0) {
            var m = root.pickerMonth + 1
            datePart = root.pickerYear + "-" + KanbanService.zp2(m) + "-" + KanbanService.zp2(root.pickerDay)
        }
        if (root.pickerHasTime)
            timePart = KanbanService.zp2(root.pickerTimeH) + ":" + KanbanService.zp2(root.pickerTimeM)

        var result = ""
        if (datePart !== "" && timePart !== "") result = datePart + " " + timePart
        else if (datePart !== "") result = datePart
        else if (timePart !== "") {
            var now = new Date()
            result = now.getFullYear() + "-" + KanbanService.zp2(now.getMonth()+1) + "-" + KanbanService.zp2(now.getDate())
                     + " " + timePart
        }
        KanbanService.patchTask(root.taskId, "dueDate", result)
        root.closed()
    }

    // ── Picker dim overlay ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent; z: 29
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent; onClicked: root.closed() }
    }

    // ── Date / time picker popup ──────────────────────────────────────────────
    Rectangle {
        id: datePicker
        z: 30
        anchors.centerIn: parent

        width: Math.round(230 * localScale)
        height: pickerCol.implicitHeight + Math.round(24 * localScale)
        radius: Math.round(Theme.cornerRadius * localScale)
        color: Qt.rgba(
            Math.min(1, Theme.background.r + 0.06),
            Math.min(1, Theme.background.g + 0.06),
            Math.min(1, Theme.background.b + 0.06), 0.98)
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
        border.width: 1

        // Swallow clicks so they don't reach the dim overlay below
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: pickerCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(12 * localScale) }
            spacing: Math.round(8 * localScale)

            // ── Month nav ──────────────────────────────────────────────────────
            Item {
                width: parent.width; height: Math.round(22 * localScale)
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "‹"; font.pixelSize: Math.round(17 * localScale)
                    color: pmH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.85) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    HoverHandler { id: pmH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.pickerMonth === 0) { root.pickerMonth = 11; root.pickerYear-- }
                            else root.pickerMonth--
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: root._monthNames[root.pickerMonth].substring(0, 3) + "  " + root.pickerYear
                    color: Theme.text; font.pixelSize: Math.round(11 * localScale); font.weight: Font.DemiBold
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "›"; font.pixelSize: Math.round(17 * localScale)
                    color: nmH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.85) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    HoverHandler { id: nmH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.pickerMonth === 11) { root.pickerMonth = 0; root.pickerYear++ }
                            else root.pickerMonth++
                        }
                    }
                }
            }

            // ── Day-of-week headers ────────────────────────────────────
            Item {
                width: parent.width; height: Math.round(14 * localScale)
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: root._dowNames
                        delegate: Text {
                            width: Math.floor(parent.parent.width / 7)
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData; font.pixelSize: Math.round(8 * localScale); font.weight: Font.Bold
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
                        }
                    }
                }
            }

            // ── Day grid ──────────────────────────────────────────────
            Grid {
                id: dayGrid
                width: parent.width; columns: 7; rows: 6
                readonly property real cW: width / 7
                readonly property real cH: Math.round(24 * localScale)

                Repeater {
                    model: root.pickerDays
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: dayGrid.cW; height: dayGrid.cH

                        readonly property bool isSel: modelData.cur && modelData.n === root.pickerDay
                        readonly property bool isNow: {
                            var n = new Date()
                            return modelData.cur &&
                                   modelData.n === n.getDate() &&
                                   root.pickerMonth === n.getMonth() &&
                                   root.pickerYear === n.getFullYear()
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(dayGrid.cW, dayGrid.cH) - 2; height: width; radius: width / 2
                            color: isSel
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.82)
                                : isNow ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                                        : dayH.hovered && modelData.cur ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                            border.color: isNow && !isSel ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Anim.superFast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.n
                                font.pixelSize: Math.round(9 * localScale); font.weight: isSel ? Font.Bold : Font.Normal
                                color: isSel ? Theme.background
                                    : modelData.cur ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.78) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14)
                            }
                        }
                        HoverHandler { id: dayH; enabled: modelData.cur; cursorShape: Qt.PointingHandCursor }
                        TapHandler  { enabled: modelData.cur; onTapped: root.pickerDay = modelData.n }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) }

            // ── Time row ──────────────────────────────────────────────
            Item {
                width: parent.width; height: timeInner.implicitHeight

                Row {
                    id: timeInner
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(10 * localScale)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⏰"; font.pixelSize: Math.round(13 * localScale)
                    }

                    // Controls when time is set
                    Row {
                        spacing: Math.round(4 * localScale); visible: root.pickerHasTime
                        anchors.verticalCenter: parent.verticalCenter

                        // ── Hour col ──────────────────────────────────
                        Column {
                            spacing: Math.round(2 * localScale); anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(18 * localScale); radius: Math.round(4 * localScale)
                                color: hUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Behavior on color { ColorAnimation { duration: Anim.superFast } }
                                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(7 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                                HoverHandler { id: hUpH; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: root.pickerTimeH = (root.pickerTimeH + 1) % 24 }
                            }
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(24 * localScale); radius: Math.round(4 * localScale)
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07); border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: KanbanService.zp2(root.pickerTimeH)
                                    font.pixelSize: Math.round(13 * localScale); font.family: "JetBrains Mono"; font.weight: Font.Bold
                                    color: Theme.active
                                }
                            }
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(18 * localScale); radius: Math.round(4 * localScale)
                                color: hDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Behavior on color { ColorAnimation { duration: Anim.superFast } }
                                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(7 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                                HoverHandler { id: hDnH; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: root.pickerTimeH = (root.pickerTimeH + 23) % 24 }
                            }
                        }

                        Text { anchors.verticalCenter: parent.verticalCenter; text: ":"; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text }

                        // ── Minute col ────────────────────────────────
                        Column {
                            spacing: Math.round(2 * localScale); anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(18 * localScale); radius: Math.round(4 * localScale)
                                color: mUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Behavior on color { ColorAnimation { duration: Anim.superFast } }
                                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(7 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                                HoverHandler { id: mUpH; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: root.pickerTimeM = (root.pickerTimeM + 5) % 60 }
                            }
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(24 * localScale); radius: Math.round(4 * localScale)
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07); border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: KanbanService.zp2(root.pickerTimeM)
                                    font.pixelSize: Math.round(13 * localScale); font.family: "JetBrains Mono"; font.weight: Font.Bold
                                    color: Theme.active
                                }
                            }
                            Rectangle {
                                width: Math.round(26 * localScale); height: Math.round(18 * localScale); radius: Math.round(4 * localScale)
                                color: mDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                                Behavior on color { ColorAnimation { duration: Anim.superFast } }
                                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(7 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                                HoverHandler { id: mDnH; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: root.pickerTimeM = (root.pickerTimeM + 55) % 60 }
                            }
                        }

                        // Clear time ✕
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(18 * localScale); height: Math.round(18 * localScale); radius: width / 2
                            color: clrTH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                            Behavior on color { ColorAnimation { duration: Anim.superFast } }
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: Math.round(8 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.40) }
                            HoverHandler { id: clrTH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root.pickerHasTime = false }
                        }
                    }

                    // "Add time" pill (shown when no time set)
                    Rectangle {
                        visible: !root.pickerHasTime
                        anchors.verticalCenter: parent.verticalCenter
                        width: addTL.implicitWidth + Math.round(18 * localScale); height: Math.round(24 * localScale); radius: height / 2
                        color: addTH.hovered
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            id: addTL; anchors.centerIn: parent
                            text: "Add time"; font.pixelSize: Math.round(10 * localScale)
                            color: addTH.hovered ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                            Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        }
                        HoverHandler { id: addTH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.pickerHasTime = true; root.pickerTimeH = 12; root.pickerTimeM = 0 }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) }

            // ── Clear / Done ──────────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(10 * localScale)

                Rectangle {
                    width: Math.round(86 * localScale); height: Math.round(28 * localScale); radius: Math.round(8 * localScale)
                    color: clrH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    Text { anchors.centerIn: parent; text: "Clear"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                    HoverHandler { id: clrH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            KanbanService.patchTask(root.taskId, "dueDate", "")
                            root.closed()
                        }
                    }
                }

                Rectangle {
                    width: Math.round(86 * localScale); height: Math.round(28 * localScale); radius: Math.round(8 * localScale)
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, doneH.hovered ? 0.28 : 0.16)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.38); border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    Text {
                        anchors.centerIn: parent; text: "Done"
                        font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Theme.active
                    }
                    HoverHandler { id: doneH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.commitPicker() }
                }
            }
        }
    }
}

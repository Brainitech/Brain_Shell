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
    id: card

    property var  taskData
    property int  colIdx: 0
    property real localScale: 1.0
    property int  delConfirmId: -1

    property bool showExtra: false
    property real xEntry:    0
    property real dragX:     0

    signal requestOpenPicker(int taskId)
    signal requestDeleteConfirm(int taskId)
    signal cancelDeleteConfirm()
    signal titleFocusChanged(bool focused)
    signal requestBoardFocus()

    readonly property bool isDelConfirm: delConfirmId === (taskData ? taskData.id : -1)

    height: cardBg.implicitHeight + Math.round(2 * localScale)

    transform: [
        Translate { x: card.dragX + card.xEntry },
        // 3D Tilt: card physically tilts in the direction you drag it
        Rotation {
            origin.x: card.width / 2; origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: (card.dragX / (65.0 * localScale)) * -12
            Behavior on angle { SpringAnimation { spring: 2.5; damping: 0.3 } }
        }
    ]

    // Lift Effect: card scales down slightly when grabbed
    scale: dragHandler.active ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: Anim.mediumSlow; easing.type: Anim.outBack; easing.overshoot: 1.5 } }

    // Fluid Column Jumps: smooth gliding instead of teleporting
    Behavior on x { SpringAnimation { spring: 2.0; damping: 0.25 } }
    Behavior on y { SpringAnimation { spring: 2.0; damping: 0.25 } }

    // ── Entry animation ────────────────────────────────────────────────────
    Component.onCompleted: {
        var id = card.taskData ? card.taskData.id : -1
        if (id < 0) return
        if (KanbanService.takeNewCard(id)) {
            // No extra animation — draft open/close is the creation affordance
        } else {
            var dir = KanbanService.takeEntryDirection(id)
            if (dir !== 0) {
                card.xEntry = dir * Math.round(36 * localScale)
                xSpringAnim.restart()
            }
        }
    }

    // Spring to 0 with OutBack rubber-band feel
    NumberAnimation {
        id: xSpringAnim
        target: card; property: "xEntry"; to: 0
        duration: Anim.slower; easing.type: Anim.outBack; easing.overshoot: 1.6
    }

    // ── Swipe to move ─────────────────────────────────────────────────────
    DragHandler {
        id: dragHandler
        target: null; xAxis.enabled: true; yAxis.enabled: false
        dragThreshold: Math.round(12 * localScale)

        onActiveChanged: {
            if (!active) {
                var d = card.dragX; snapAnim.start()
                var dir = d > 0 ? 1 : -1
                if (Math.abs(d) > Math.round(50 * localScale) && card.colIdx + dir >= 0 && card.colIdx + dir <= 2)
                    KanbanService.moveTask(card.taskData.id, dir)
            }
        }
        onTranslationChanged: {
            if (active) card.dragX = Math.max(Math.round(-65 * localScale), Math.min(Math.round(65 * localScale), translation.x))
        }
    }

    // Elastic Snap: wobbles slightly when snapping back to place
    NumberAnimation {
        id: snapAnim; target: card; property: "dragX"; to: 0
        duration: Anim.extraSlow; easing.type: Anim.outElastic; easing.amplitude: 1.2; easing.period: 0.6
    }

    // Dynamic Glow: stronger, smoother color tinting
    readonly property real dragAmt: Math.abs(dragX) / (65.0 * localScale)
    readonly property color dragTint: {
        if (dragX >  Math.round(2 * localScale)) return Qt.rgba(166/255, 227/255, 161/255, dragAmt * 0.35)
        if (dragX < Math.round(-2 * localScale)) return Qt.rgba(243/255, 139/255, 168/255, dragAmt * 0.35)
        return "transparent"
    }

    // ── Card body ─────────────────────────────────────────────────────────
    Rectangle {
        id: cardBg
        width: parent.width; radius: Math.round(8 * localScale)
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
        border.color: {
            var u = card.taskData ? card.taskData.urgency : ""
            if (u === "high")   return Qt.rgba(243/255, 139/255, 168/255, 0.45)
            if (u === "medium") return Qt.rgba(249/255, 226/255, 175/255, 0.35)
            if (u === "low")    return Qt.rgba(166/255, 227/255, 161/255, 0.35)
            return Theme.border
        }
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }
        implicitHeight: Math.max(body.implicitHeight + Math.round(18 * localScale), card.isDelConfirm ? Math.round(86 * localScale) : 0)

        // Drag direction tint
        Rectangle {
            anchors.fill: parent; radius: parent.radius; color: card.dragTint
            Behavior on color { ColorAnimation { duration: Anim.superFast } }
        }

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale); top: parent.top; topMargin: Math.round(9 * localScale) }
            spacing: Math.round(6 * localScale)

            // Title (inline edit)
            TextInput {
                id: titleEditInput
                width: parent.width
                text: card.taskData ? card.taskData.title : ""
                color: Theme.text; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium
                wrapMode: TextInput.WordWrap
                selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                onEditingFinished: {
                    var t = text.trim()
                    if (t !== "" && card.taskData) KanbanService.patchTask(card.taskData.id, "title", t)
                }
                onActiveFocusChanged: {
                    card.titleFocusChanged(activeFocus)
                    Popups.isInputFocused = activeFocus
                }
                Keys.onEscapePressed: function(event) {
                    event.accepted = true
                    if (card.taskData) text = card.taskData.title
                    card.requestBoardFocus()
                }
            }

            // Badges row
            Row {
                visible: card.taskData && (card.taskData.urgency !== "" || (card.taskData.dueDate || "") !== "")
                spacing: Math.round(6 * localScale)
                Rectangle {
                    visible: card.taskData && card.taskData.urgency !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    width: urgL.implicitWidth + Math.round(12 * localScale); height: Math.round(16 * localScale); radius: Math.round(8 * localScale)
                    color: card.taskData ? KanbanService.urgColor(card.taskData.urgency) : "transparent"; opacity: 0.85
                    Text { id: urgL; anchors.centerIn: parent; text: card.taskData ? KanbanService.urgLabel(card.taskData.urgency) : ""; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; color: Theme.background }
                }
                Row {
                    visible: card.taskData && (card.taskData.dueDate || "") !== ""
                    anchors.verticalCenter: parent.verticalCenter; spacing: Math.round(3 * localScale)
                    Text { text: "📅"; font.pixelSize: Math.round(9 * localScale) }
                    Text { text: card.taskData ? KanbanService.formatDue(card.taskData.dueDate || "") : ""; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50) }
                }
            }

            // Expandable extra fields
            Column {
                visible: card.showExtra; width: parent.width; spacing: Math.round(6 * localScale)

                // Urgency picker
                Row {
                    spacing: Math.round(5 * localScale)
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Urgency"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) }
                    Repeater {
                        model: ["", "low", "medium", "high"]
                        delegate: Rectangle {
                            required property string modelData
                            property bool sel: card.taskData && card.taskData.urgency === modelData
                            width: uT.implicitWidth + Math.round(12 * localScale); height: Math.round(17 * localScale); radius: Math.round(9 * localScale)
                            color: sel ? (modelData === "" ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15) : KanbanService.urgColor(modelData))
                                       : (uH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05))
                            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, sel ? 0.20 : 0.08); border.width: 1
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                            Text {
                                id: uT; anchors.centerIn: parent; font.pixelSize: Math.round(9 * localScale)
                                text: modelData === "" ? "None" : modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                color: (sel && modelData !== "") ? Theme.background : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                            }
                            HoverHandler { id: uH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: if (card.taskData) KanbanService.patchTask(card.taskData.id, "urgency", modelData) }
                        }
                    }
                }

                // Due date button row
                Row {
                    spacing: Math.round(6 * localScale)
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Due"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: dueLbl.implicitWidth + Math.round(20 * localScale); height: Math.round(20 * localScale); radius: Math.round(10 * localScale)
                        color: dueBH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            id: dueLbl; anchors.centerIn: parent; font.pixelSize: Math.round(9 * localScale)
                            text: (card.taskData && (card.taskData.dueDate || "") !== "") ? KanbanService.formatDue(card.taskData.dueDate) : "Set due date"
                            color: (card.taskData && (card.taskData.dueDate || "") !== "") ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.40)
                            Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        }
                        HoverHandler { id: dueBH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (card.taskData) card.requestOpenPicker(card.taskData.id) }
                    }

                    // Clear ✕
                    Rectangle {
                        visible: card.taskData && (card.taskData.dueDate || "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(16 * localScale); height: Math.round(16 * localScale); radius: width / 2
                        color: clrDH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: Math.round(8 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) }
                        HoverHandler { id: clrDH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (card.taskData) KanbanService.patchTask(card.taskData.id, "dueDate", "") }
                    }
                }
            }

            // Action bar
            Item {
                width: parent.width; height: Math.round(22 * localScale)

                // ▾/▴ extra fields
                Rectangle {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: Math.round(20 * localScale); height: Math.round(20 * localScale); radius: Math.round(5 * localScale)
                    color: optH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    Text { anchors.centerIn: parent; text: card.showExtra ? "▴" : "▾"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, optH.hovered ? 0.70 : 0.30) }
                    HoverHandler { id: optH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: card.showExtra = !card.showExtra }
                }

                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Math.round(4 * localScale)

                    // ← left
                    Rectangle {
                        visible: card.colIdx > 0
                        width: Math.round(20 * localScale); height: Math.round(20 * localScale); radius: Math.round(5 * localScale)
                        color: lH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text { anchors.centerIn: parent; text: "←"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, lH.hovered ? 0.80 : 0.40) }
                        HoverHandler { id: lH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (card.taskData) KanbanService.moveTask(card.taskData.id, -1) }
                    }

                    // → right
                    Rectangle {
                        visible: card.colIdx < 2
                        width: Math.round(20 * localScale); height: Math.round(20 * localScale); radius: Math.round(5 * localScale)
                        color: rH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text { anchors.centerIn: parent; text: "→"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, rH.hovered ? 0.80 : 0.40) }
                        HoverHandler { id: rH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (card.taskData) KanbanService.moveTask(card.taskData.id, 1) }
                    }

                    // ✕ delete
                    Rectangle {
                        width: Math.round(20 * localScale); height: Math.round(20 * localScale); radius: Math.round(5 * localScale)
                        color: dH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            anchors.centerIn: parent; text: "✕"; font.pixelSize: Math.round(10 * localScale)
                            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, dH.hovered ? 1.0 : 0.60)
                            Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        }
                        HoverHandler { id: dH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: if (card.taskData) card.requestDeleteConfirm(card.taskData.id) }
                    }
                }
            }
        }

        // ── Delete confirmation overlay ────────────────────────────────────
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            visible: card.isDelConfirm
            color: Qt.rgba(
                Math.min(1, Theme.background.r + 0.05),
                Math.min(1, Theme.background.g + 0.05),
                Math.min(1, Theme.background.b + 0.05), 0.96)

            Column {
                anchors.centerIn: parent; spacing: Math.round(10 * localScale)
                scale: Math.min(1.0, (parent.width - Math.round(12 * localScale)) / Math.round(136 * localScale))

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Delete task?"; color: Theme.text; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: Math.round(8 * localScale)
                    Rectangle {
                        width: Math.round(64 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                        color: cnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.60) }
                        HoverHandler { id: cnH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: card.cancelDeleteConfirm() }
                    }
                    Rectangle {
                        width: Math.round(64 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                        color: cfH.hovered ? Qt.lighter(Theme.errorSolid, 1.2) : Theme.errorSolid
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text { anchors.centerIn: parent; text: "Delete"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Bold; color: "white" }
                        HoverHandler { id: cfH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (card.taskData) {
                                    KanbanService.removeTask(card.taskData.id)
                                    card.cancelDeleteConfirm()
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↵ confirm · ⎋ cancel"; font.pixelSize: Math.round(9 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.20)
                }
            }
        }
    }
}

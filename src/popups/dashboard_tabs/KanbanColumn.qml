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
    id: colItem

    property int    colIdx: 0
    property string colLabel: ""
    property real   localScale: 1.0
    property int    delConfirmId: -1
    property int    clearConfirmColIdx: -1

    readonly property bool isClearConfirm: clearConfirmColIdx === colIdx
    onIsClearConfirmChanged: colItem.interactionChanged(isClearConfirm)

    property bool draftOpen: false
    onDraftOpenChanged: colItem.interactionChanged(draftOpen)

    signal requestOpenPicker(int taskId)
    signal requestDeleteConfirm(int taskId)
    signal cancelDeleteConfirm()
    signal requestClearConfirm(int colIdx)
    signal cancelClearConfirm()
    signal interactionChanged(bool active)
    signal requestBoardFocus()

    readonly property var cTasks: {
        var ci = colItem.colIdx
        return KanbanService.tasks.filter(function(t) { return t.column === ci })
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(Theme.cornerRadius * localScale)
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03)
        border.color: Theme.border
        border.width: 1
    }

    Column {
        anchors { fill: parent; margins: Math.round(10 * localScale) }
        spacing: Math.round(8 * localScale)

        // Header
        Item {
            width: parent.width
            height: Math.round(26 * localScale)

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: Math.round(7 * localScale)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: colItem.colLabel
                    color: Theme.active
                    font.pixelSize: Math.round(12 * localScale)
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: cntT.implicitWidth + Math.round(10 * localScale)
                    height: Math.round(16 * localScale)
                    radius: Math.round(8 * localScale)
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                    Text {
                        id: cntT
                        anchors.centerIn: parent
                        text: colItem.cTasks.length
                        color: Theme.active
                        font.pixelSize: Math.round(9 * localScale)
                        font.weight: Font.Bold
                    }
                }
            }

            // Actions row
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Math.round(6 * localScale)

                // Clear column button
                Rectangle {
                    width: Math.round(22 * localScale)
                    height: Math.round(22 * localScale)
                    radius: Math.round(6 * localScale)
                    color: clrColH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: clrColH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    border.width: 1
                    visible: colItem.cTasks.length > 0
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "🗑"
                        color: clrColH.hovered ? Theme.error : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                        font.pixelSize: Math.round(11 * localScale)
                    }
                    HoverHandler { id: clrColH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            colItem.draftOpen = false
                            colItem.requestClearConfirm(colItem.colIdx)
                        }
                    }
                }

                // Add (+) button
                Rectangle {
                    width: Math.round(22 * localScale)
                    height: Math.round(22 * localScale)
                    radius: Math.round(6 * localScale)
                    color: addH.hovered
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.active
                        font.pixelSize: Math.round(15 * localScale)
                    }
                    HoverHandler { id: addH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { colItem.draftOpen = true; draftTimer.restart() }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.45)
        }

        Timer {
            id: draftTimer
            interval: 50
            onTriggered: if (colItem.draftOpen) draftInput.forceActiveFocus()
        }

        // Content area
        Item {
            width: parent.width
            height: parent.height - Math.round(26 * localScale) - 1 - parent.spacing * 2

            // Draft card — slides in from top
            Item {
                id: draftWrap
                z: 2
                width: parent.width
                height: colItem.draftOpen ? draftRect.implicitHeight + Math.round(6 * localScale) : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: Anim.mediumFast
                        easing.type: Anim.outCubic
                        easing.overshoot: Anim.globalOvershoot
                        easing.amplitude: Anim.globalAmplitude
                        easing.period: Anim.globalPeriod
                    }
                }

                Rectangle {
                    id: draftRect
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: Math.round(3 * localScale)
                    }
                    radius: Math.round(8 * localScale)
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.06)
                    border.color: draftInput.activeFocus
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.50)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                    border.width: 1
                    implicitHeight: draftInput.contentHeight + Math.round(24 * localScale)
                    Behavior on border.color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: Math.round(10 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        visible: draftInput.text === ""
                        text: "Task title…"
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                        font.pixelSize: Math.round(12 * localScale)
                    }

                    TextInput {
                        id: draftInput
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Math.round(10 * localScale)
                            rightMargin: Math.round(10 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        color: Theme.text
                        font.pixelSize: Math.round(12 * localScale)
                        wrapMode: TextInput.WordWrap
                        selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)

                        function commit() {
                            var t = text.trim()
                            if (t !== "") KanbanService.addTask(colItem.colIdx, t)
                            colItem.draftOpen = false
                            text = ""
                            colItem.requestBoardFocus()
                        }

                        Keys.onReturnPressed: function(ev) { commit(); ev.accepted = true }
                        Keys.onEscapePressed: function(ev) {
                            colItem.draftOpen = false
                            text = ""
                            ev.accepted = true
                            colItem.requestBoardFocus()
                        }
                        onActiveFocusChanged: {
                            Popups.isInputFocused = activeFocus
                            if (!activeFocus && colItem.draftOpen) commit()
                        }
                    }
                }
            }

            // Task list
            Flickable {
                anchors.top: draftWrap.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colItem.draftOpen ? Math.round(4 * localScale) : 0
                height: parent.height - draftWrap.height - (colItem.draftOpen ? Math.round(4 * localScale) : 0)
                contentWidth: width
                contentHeight: taskCol.implicitHeight + Math.round(4 * localScale)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: taskCol
                    width: parent.width
                    spacing: Math.round(6 * localScale)

                    Repeater {
                        model: colItem.cTasks
                        delegate: KanbanTaskCard {
                            required property var modelData
                            localScale: colItem.localScale
                            width: parent.width
                            taskData: modelData
                            colIdx: colItem.colIdx
                            delConfirmId: colItem.delConfirmId

                            onRequestOpenPicker: function(taskId) { colItem.requestOpenPicker(taskId) }
                            onRequestDeleteConfirm: function(taskId) { colItem.requestDeleteConfirm(taskId) }
                            onCancelDeleteConfirm: { colItem.cancelDeleteConfirm() }
                            onTitleFocusChanged: function(focused) { colItem.interactionChanged(focused) }
                            onRequestBoardFocus: { colItem.requestBoardFocus() }
                        }
                    }
                }
            }
        }
    }

    // ── Clear column confirmation overlay ──────────────────────────────────
    Rectangle {
        id: clearConfirmOverlay
        anchors.fill: parent
        radius: Math.round(Theme.cornerRadius * localScale)
        z: 10
        visible: opacity > 0.001
        opacity: colItem.isClearConfirm ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Anim.fast; easing.type: Anim.outCubic }
        }
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.88)
        border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.35)
        border.width: 1

        // Click blocker to absorb clicks outside buttons and dismiss on empty click
        MouseArea {
            anchors.fill: parent
            enabled: colItem.isClearConfirm
            onClicked: colItem.cancelClearConfirm()
        }

        Column {
            anchors.centerIn: parent
            spacing: Math.round(12 * localScale)
            width: Math.min(parent.width - Math.round(20 * localScale), Math.round(220 * localScale))

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clear " + colItem.colLabel + "?"
                color: Theme.text
                font.pixelSize: Math.round(14 * localScale)
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: colItem.cTasks.length + " task" + (colItem.cTasks.length === 1 ? "" : "s") + " will be deleted"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.50)
                font.pixelSize: Math.round(10 * localScale)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(10 * localScale)

                Rectangle {
                    width: Math.round(68 * localScale)
                    height: Math.round(26 * localScale)
                    radius: Math.round(6 * localScale)
                    color: clrCnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Math.round(11 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.70)
                    }
                    HoverHandler { id: clrCnH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: colItem.cancelClearConfirm()
                    }
                }

                Rectangle {
                    width: Math.round(68 * localScale)
                    height: Math.round(26 * localScale)
                    radius: Math.round(6 * localScale)
                    color: clrCfH.hovered ? Qt.lighter(Theme.errorSolid, 1.2) : Theme.errorSolid
                    Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "Delete"
                        font.pixelSize: Math.round(11 * localScale)
                        font.weight: Font.Bold
                        color: "white"
                    }
                    HoverHandler { id: clrCfH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            KanbanService.clearColumn(colItem.colIdx)
                            colItem.cancelClearConfirm()
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "↵ confirm · ⎋ cancel"
                font.pixelSize: Math.round(9 * localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
        }
    }
}

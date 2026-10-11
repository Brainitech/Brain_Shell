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
import "../"
import "../../components"

Item {
    id: root
    focus: true

    property real localScale: 1.0

    // ── Interaction and modal tracking ────────────────────────────────────────
    property int _interactionCount: 0
    property int delConfirmId: -1
    property int pickerTaskId: -1

    function _evalInteraction() {
        Popups.tasksInteractionActive = root._interactionCount > 0 || root.pickerTaskId >= 0 || root.delConfirmId >= 0
    }
    onPickerTaskIdChanged: root._evalInteraction()
    onDelConfirmIdChanged: {
        root._evalInteraction()
        if (root.delConfirmId >= 0) deleteKeyHandler.forceActiveFocus()
    }

    // ── Delete keyboard handler ───────────────────────────────────────────────
    // Grabs focus when delete confirm opens; Enter = delete, Esc = cancel.
    Item {
        id: deleteKeyHandler
        Keys.onReturnPressed: function(ev) {
            if (root.delConfirmId >= 0) {
                KanbanService.removeTask(root.delConfirmId)
                root.delConfirmId = -1
                ev.accepted = true
            }
        }
        Keys.onEscapePressed: function(ev) {
            if (root.delConfirmId >= 0) {
                root.delConfirmId = -1
                ev.accepted = true
            }
        }
    }

    // ── Column definitions ────────────────────────────────────────────────────
    readonly property var colDefs: [
        { idx: 0, label: "To Do"   },
        { idx: 1, label: "Ongoing" },
        { idx: 2, label: "Done"    }
    ]

    // ── Column layout ─────────────────────────────────────────────────────────
    Row {
        id: mainRow
        anchors.fill: parent
        anchors.topMargin: Math.round(8 * localScale)
        spacing: Math.round(8 * localScale)

        Repeater {
            model: root.colDefs

            delegate: KanbanColumn {
                required property var modelData

                width: (mainRow.width - mainRow.spacing * 2) / 3
                height: parent.height
                colIdx: modelData.idx
                colLabel: modelData.label
                localScale: root.localScale
                delConfirmId: root.delConfirmId

                onRequestOpenPicker: function(taskId) { root.pickerTaskId = taskId }
                onRequestDeleteConfirm: function(taskId) { root.delConfirmId = taskId }
                onCancelDeleteConfirm: { root.delConfirmId = -1 }
                onInteractionChanged: function(active) {
                    root._interactionCount = Math.max(0, root._interactionCount + (active ? 1 : -1))
                    root._evalInteraction()
                }
                onRequestBoardFocus: { root.forceActiveFocus() }
            }
        }
    }

    // ── Date / time picker modal overlay ──────────────────────────────────────
    KanbanDatePicker {
        id: datePicker
        anchors.fill: parent
        z: 30
        visible: root.pickerTaskId >= 0
        localScale: root.localScale
        taskId: root.pickerTaskId
        onClosed: { root.pickerTaskId = -1 }
    }
}

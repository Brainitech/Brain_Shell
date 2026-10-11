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
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    // ── Persistent state ──────────────────────────────────────────────────────
    property var    tasks:            []
    property int    nextId:           0
    readonly property string filePath: Paths.userDataDir + "/tasks.json"

    // Backwards-compatible aliases
    property alias  _tasks:           root.tasks
    property alias  _nextId:          root.nextId
    property alias  _filePath:        root.filePath
    property alias  _newCardIds:      root.newCardIds
    property alias  _entryDirections: root.entryDirections

    // ── Animation tracking ────────────────────────────────────────────────────
    property var newCardIds:          ({})   // id → true  (y slide-in on creation)
    property var entryDirections:     ({})   // id → dir   (x spring on column move)

    function takeNewCard(id) {
        if (root.newCardIds[id]) {
            delete root.newCardIds[id]
            return true
        }
        return false
    }

    function takeEntryDirection(id) {
        if (root.entryDirections[id] !== undefined) {
            var dir = root.entryDirections[id]
            delete root.entryDirections[id]
            return dir
        }
        return 0
    }

    // ── Boot: initialize file and load ────────────────────────────────────────
    Process {
        id: mkProc
        command: [
            "bash", "-c",
            "[ -f '" + root.filePath + "' ] || " +
            "(mkdir -p \"" + Paths.userDataDir + "\" && " +
            "printf '%s' '{\"tasks\":[],\"nextId\":0}' > '" + root.filePath + "')"
        ]
        running: true
        onRunningChanged: {
            if (!running && root.filePath !== "") {
                rdProc.command = ["cat", root.filePath]
                rdProc.running = false
                rdProc.running = true
            }
        }
    }

    Process {
        id: rdProc
        command: []
        running: false
        stdout: StdioCollector {
            id: rdBuf
            onStreamFinished: {
                try {
                    var o = JSON.parse(rdBuf.text)
                    root.tasks  = o.tasks  || []
                    root.nextId = o.nextId || 0
                } catch(e) {
                    root.tasks  = []
                    root.nextId = 0
                }
            }
        }
    }

    // ── Save ──────────────────────────────────────────────────────────────────
    Process {
        id: wrProc
        command: []
        running: false
    }

    function save() {
        if (root.filePath === "") return
        var s = JSON.stringify({ tasks: root.tasks, nextId: root.nextId })
        wrProc.command = [
            "bash", "-c",
            "printf '%s' '" + s.replace(/'/g, "'\\''") + "' > '" + root.filePath + "'"
        ]
        wrProc.running = false
        wrProc.running = true
    }
    function _save() { save() }

    // ── External Confirm Action Hook ──────────────────────────────────────────
    Connections {
        target: Popups
        function onActionConfirmed(action) {
            if (action.startsWith("clear_kanban_col_")) {
                var cId = parseInt(action.split("_").pop())
                root.clearColumn(cId)
                Popups.cancelConfirm()
            }
        }
    }

    // ── Mutations ─────────────────────────────────────────────────────────────
    function addTask(col, title) {
        var id   = root.nextId++
        var list = root.tasks.slice()
        list.unshift({ id: id, title: title, column: col, urgency: "", dueDate: "" })
        root.newCardIds = Object.assign({}, root.newCardIds, { [id]: true })
        root.tasks = list
        save()
        return id
    }
    function _addTask(col, title) { return addTask(col, title) }

    function moveTask(id, dir) {
        var list = root.tasks.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id !== id) continue
            var nc = list[i].column + dir
            if (nc < 0 || nc > 2) return
            root.entryDirections = Object.assign({}, root.entryDirections, { [id]: dir })
            list[i] = Object.assign({}, list[i], { column: nc })
            break
        }
        root.tasks = list
        save()
    }
    function _moveTask(id, dir) { moveTask(id, dir) }

    function removeTask(id) {
        root.tasks = root.tasks.filter(function(t) { return t.id !== id })
        save()
    }
    function _removeTask(id) { removeTask(id) }

    function patchTask(id, key, val) {
        var list = root.tasks.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id !== id) continue
            var t = Object.assign({}, list[i])
            t[key] = val
            list[i] = t
            break
        }
        root.tasks = list
        save()
    }
    function _patchTask(id, key, val) { patchTask(id, key, val) }

    function clearColumn(colIdx) {
        root.tasks = root.tasks.filter(function(t) { return t.column !== colIdx })
        save()
    }

    // ── Urgency helpers ───────────────────────────────────────────────────────
    function urgColor(u) {
        if (u === "high")   return "#f38ba8"
        if (u === "medium") return "#f9e2af"
        if (u === "low")    return "#a6e3a1"
        return "transparent"
    }
    function _urgColor(u) { return urgColor(u) }

    function urgLabel(u) {
        if (u === "high")   return "High"
        if (u === "medium") return "Med"
        if (u === "low")    return "Low"
        return ""
    }
    function _urgLabel(u) { return urgLabel(u) }

    // ── Due date helpers ──────────────────────────────────────────────────────
    function zp2(n) { return n < 10 ? "0" + n : "" + n }
    function _zp2(n) { return zp2(n) }

    function formatDue(s) {
        if (!s || s === "") return ""
        var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        var now = new Date()
        var todayStr = now.getFullYear() + "-" + zp2(now.getMonth()+1) + "-" + zp2(now.getDate())
        var datePart = s.length >= 10 ? s.substring(0, 10) : ""
        var timePart = s.length >= 16 ? s.substring(11, 16) : ""
        var dateLabel = ""
        if (datePart !== "") {
            if (datePart === todayStr) dateLabel = "Today"
            else {
                var dp = datePart.split("-")
                dateLabel = months[parseInt(dp[1]) - 1] + " " + parseInt(dp[2])
            }
        }
        if (dateLabel !== "" && timePart !== "") return dateLabel + "  " + timePart
        if (dateLabel !== "") return dateLabel
        if (timePart !== "") return "Today  " + timePart
        return ""
    }
    function _formatDue(s) { return formatDue(s) }
}

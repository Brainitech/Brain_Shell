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
import Quickshell.Services.Notifications
import "../../"

// ─────────────────────────────────────────────────────────────
// NotificationService — global singleton
// ─────────────────────────────────────────────────────────────

NotificationServer {
    id: root

    bodyMarkupSupported:   true
    bodySupported:         true
    actionsSupported:      true
    keepOnReload:          true
    
    signal notificationAdded(var notification)
    
    property var list: []
    readonly property int count: list.length

    property bool _ready: false
    
    property Timer _startupTimer: Timer {
        interval: 500 
        running: true
        onTriggered: root._ready = true
    }
    
    onNotification: function(n) {
        n.tracked = true

        if (root.list.includes(n)) return 

        root.list = [n, ...root.list]
        
        if (ShellState.dnd) return
        
        if (root._ready) {
            root.notificationAdded(n)
        }

         n.onClosed.connect(function() {
            root.list = root.list.filter(function(x) { return x !== n })
        })
    }

    function dismissAll() {
        if (!root.list) return
        const list = [...root.list]
        for (const n of list) n.dismiss()
    }
}

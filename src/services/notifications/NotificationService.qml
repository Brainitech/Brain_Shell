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
    
    // Assign the Timer to a named property to avoid the default property error
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

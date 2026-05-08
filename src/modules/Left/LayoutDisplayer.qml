import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// ─── LayoutDisplayer ────────────────────────────────────────────────────────
// Small icon button beside the Workspaces module.
// Shows the active tiling layout for the focused workspace.
//
// Layout → symbol map:
//   dwindle  →       (nf-md-view_quilt)
//   master   →       (nf-md-view_split_vertical)
//   monocle  → 󰊓     (nf-md-fullscreen)
//   scroller → 󰔧     (nf-md-scroll_horizontal)
//
// Update triggers (event-driven, no forever-loop):
//   • Component.onCompleted     — initial read
//   • focusedWorkspaceChanged   — workspace switch
//   • focusedToplevelChanged    — window focus change (covers most layout shifts)
//   • 4 s safety timer          — catches layout change with no following event
// ────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    implicitWidth:  26
    implicitHeight: 26

    // ── State ────────────────────────────────────────────────────────────────

    property string currentLayout: ""
    property string numWindows: ""
    property var availableLayouts: ["dwindle", "master", "monocle", "scrolling"]

    // ── Symbol map ───────────────────────────────────────────────────────────

    function layoutSymbol(name) {
        switch (name.toLowerCase()) {
            case "dwindle":  return "><"   // nf-md-view_quilt
            case "master":   return "M"   // nf-md-view_split_vertical
            case "monocle":  return "|"+root.numWindows+"|"  // nf-md-fullscreen
            case "scrolling": return "<"+root.numWindows+">"  // nf-md-scroll_horizontal (hyprscroller)
            default:         return "Unknown"  // nf-md-view_dashboard (unknown fallback)
        }
    }

    // ── hyprctl query ────────────────────────────────────────────────────────
    // Runs `hyprctl -j activeworkspace` and parses `lastlayout` from the JSON.

    Process {
        id: queryProc

        command: ["hyprctl", "-j", "activeworkspace"]
        running: false

        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const obj = JSON.parse(collector.text)
                    if (obj && obj.tiledLayout) {
                        root.currentLayout = obj.tiledLayout.toLowerCase()
                        root.numWindows = obj.windows > 0 ? obj.windows.toString() : "  "
                    } 
                } catch (e) {
                    // malformed JSON — keep current value
                }
            }
        }
    }

    function refresh() {
        if (!queryProc.running) queryProc.running = true
    }

    // ── Triggers ─────────────────────────────────────────────────────────────

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        // Quickshell emits (name, data) for raw events
        function onRawEvent(event) {
			// console.log("RawEvent_name: "+ event.name)
			// console.log("RawEvent_data: "+ event.data)
            refresh()  // Refresh on every event; the proc will ignore if still running
        }
    }

    // Safety net: catches the case where the user changes layout
    // but no window event follows (e.g. switch layout on an empty workspace).
    Timer {
        interval: 4000
        running:  true
        repeat:   true
        onTriggered: root.refresh()
    }
    // ── Layout Changer ───────────────────────────────────────────────────────
    Process {
        id: setLayoutProc
        running: false
    }

    function cycleLayout(step) {
        let idx = availableLayouts.indexOf(root.currentLayout)
        if (idx === -1) idx = 0 // Fallback if unknown
        
        // Calculate next index (handles negative steps for right-click)
        idx = (idx + step + availableLayouts.length) % availableLayouts.length
        let newLayout = availableLayouts[idx]

        // 1. Run the hyprctl command silently
        setLayoutProc.command = ["hyprctl", "keyword", "general:layout", newLayout]
        setLayoutProc.running = true

        // 2. Optimistically update the UI instantly (no waiting for IPC/Timer)
        root.currentLayout = newLayout
    }

    // ── Visual ───────────────────────────────────────────────────────────────

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    cycleLayout(1)  // Forward
                } else if (mouse.button === Qt.RightButton) {
                    cycleLayout(-1) // Backward
                }
            }
        }

        Text {
            id: icon
            anchors.centerIn: parent
            text: root.currentLayout !== "" ? layoutSymbol(root.currentLayout) : "…"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#cdd6f4"

            // Brief scale-pop on symbol change
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: icon; property: "scale"
                        to: 0.6; duration: 80
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: icon; property: "scale"
                        to: 1.0; duration: 120
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell.Io
import "../."

// Performance mode selector using auto-cpufreq.
// Reads current governor from sysfs, sets mode via auto-cpufreq --force.
// Embed inside ArchMenu as a tab page.

Column {
    id: root
    spacing: 4
    width: parent.width

    // --- Current mode state ---
    // Maps scaling_governor → our three modes
    property string currentMode: "balanced"   // "powersave" | "balanced" | "performance"

    readonly property var modes: [
        { key: "powersave",    label: "Powersave",    icon: "🍃",
          cmd: ["pkexec", "auto-cpufreq", "--force=powersave"]    },
        { key: "performance",  label: "Performance",  icon: "⚡",
          cmd: ["pkexec", "auto-cpufreq", "--force=performance"]  },
    ]

    // --- Read current governor on load and when visible ---
    onVisibleChanged: if (visible) govReader.running = true
    Component.onCompleted: govReader.running = true

    Process {
        id: govReader
        // Read governor of cpu0 — representative of all cores
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"]
        stdout: StdioCollector { id: govOut }
        onRunningChanged: {
            if (!running) {
                var gov = govOut.text.trim()
                if      (gov === "powersave")   root.currentMode = "powersave"
                else if (gov === "performance") root.currentMode = "performance"
                else                            root.currentMode = "balanced"
            }
        }
    }

    // --- Set mode ---
    Process {
        id: setter
        property var pendingCmd: []
        command: pendingCmd
        onRunningChanged: {
            // Re-read governor after command finishes to confirm the change
            if (!running) govReader.running = true
        }
    }

    function setMode(cmd, key) {
        root.currentMode = key   // optimistic update for instant feedback
        setter.pendingCmd = cmd
        setter.running = true
    }

    // --- Buttons ---
    Repeater {
        model: root.modes

        delegate: Rectangle {
            width:  root.width
            height: 52
            radius: Theme.cornerRadius

            // Active: accent fill. Hover: subtle highlight. Inactive: transparent.
            readonly property bool isActive: root.currentMode === modelData.key
            color: isActive
                       ? Theme.active
                       : (hov.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

            Behavior on color { ColorAnimation { duration: 150 } }

            // Left accent bar when active
            Rectangle {
                visible: isActive
                width:   3
                height:  parent.height * 0.5
                radius:  2
                color:   Theme.background
                anchors {
                    left:           parent.left
                    leftMargin:     6
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text:           modelData.icon
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text:           modelData.label
                        font.pixelSize: 13
                        font.bold:      isActive
                        color:          isActive ? Theme.background : Theme.text
                    }
                }
            }

            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }

            MouseArea {
                anchors.fill: parent
                // Don't re-run if already active
                onClicked: if (!isActive) root.setMode(modelData.cmd, modelData.key)
            }
        }
    }
}

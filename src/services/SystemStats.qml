import QtQuick
import Quickshell.Io
import "../"

// System stats — runs fastfetch and displays output.
// Embed inside ArchMenu.qml.

Item {
    id: root

    // Re-run fastfetch each time this page becomes visible
    onVisibleChanged: if (visible) ff.running = true

    Process {
        id: ff
        command: ["fastfetch", "--logo", "none", "--color", "false"]
        running: true

        stdout: StdioCollector { id: ffOut }

        onRunningChanged: {
            if (!running) output.text = ffOut.text.trim()
        }
    }

    Flickable {
        anchors.fill:  parent
        contentHeight: output.implicitHeight
        clip:          true

        // ScrollBar.vertical: ScrollBar {}

        Text {
            id:           output
            width:        parent.width
            text:         "Loading..."
            color:        Theme.text
            font.family:  "monospace"
            font.pixelSize: 11
            lineHeight:   1.3
            wrapMode:     Text.WrapAnywhere
        }
    }
}

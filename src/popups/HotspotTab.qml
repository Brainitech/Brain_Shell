import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../components"

// HotspotTab — config editor for hotspot SSID/password.
// The actual start/stop toggle lives in QuickSettings tile.
// Config stored in src/user_data/hotspot.json.

Item {
    id: root

    property real localScale: 1.0
    property string _ssid:      "BrainShell"
    property string _password:  "changeme1"
    property bool   _showPass:  false
    property bool   _dirty:     false   // unsaved changes

    readonly property string _cfgPath:
        Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/hotspot.json"

    // ── Load ──────────────────────────────────────────────────────────────────
    Process {
        id: loadProc
        command: ["bash", "-c",
            "[ -f '" + root._cfgPath + "' ] || " +
            "(mkdir -p \"$(dirname '" + root._cfgPath + "')\" && " +
            "printf '%s' '{\"ssid\":\"BrainShell\",\"password\":\"changeme1\"}' " +
            "> '" + root._cfgPath + "'); " +
            "cat '" + root._cfgPath + "'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") return
                try {
                    var o = JSON.parse(text)
                    if (o.ssid)     root._ssid     = o.ssid
                    if (o.password) root._password = o.password
                } catch(e) {}
            }
        }
    }

    // ── Save ──────────────────────────────────────────────────────────────────
    Process {
        id: saveProc; command: []; running: false
        onRunningChanged: if (!running) root._dirty = false
    }

    function _save() {
        var j = JSON.stringify({ ssid: root._ssid, password: root._password })
        saveProc.command = ["bash", "-c",
            "printf '%s' '" + j.replace(/'/g, "'\\''") + "' > '" + root._cfgPath + "'"]
        saveProc.running = false; saveProc.running = true
    }

    // Also update QuickSettings in-memory values so the tile uses new creds immediately
    function _applyToQuickSettings() {
        // Walk to the parent DashHome → QuickSettings sibling is not accessible,
        // so we just save to disk; QS reads from disk on next hotspot start.
    }

    Connections {
        target: Popups
        function onNetworkOpenChanged() {
            if (Popups.networkOpen && root.visible)
                loadProc.running = true
        }
    }

    Component.onCompleted: loadProc.running = true

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent; spacing: 0

        // Header
        Item {
            width: parent.width; height: Math.round(40 * localScale)
            Text { anchors { left: parent.left; leftMargin: Math.round(2 * localScale)
            verticalCenter: parent.verticalCenter }
            text: "Hotspot"
            font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text }

            // Active indicator
            Row {
                anchors { left: parent.left; leftMargin: Math.round(76 * localScale);
                verticalCenter: parent.verticalCenter }
                spacing: Math.round(6 * localScale)
                Rectangle { width: Math.round(7 * localScale); height: Math.round(7 * localScale); radius: Math.round(4 * localScale); anchors.verticalCenter: parent.verticalCenter; color: ShellState.hotspot ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.22); Behavior on color { ColorAnimation { duration: Anim.normal} } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: ShellState.hotspot ? "Active" : "Inactive"; font.pixelSize: Math.round(11 * localScale); color: ShellState.hotspot ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.32) }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.07) }
        Item { width: parent.width; height: Math.round(8 * localScale) }

        Flickable {
            width: parent.width; height: parent.height - Math.round(49 * localScale)
            contentWidth: width; contentHeight: mainCol.implicitHeight + Math.round(8 * localScale)
            clip: true; boundsBehavior: Flickable.StopAtBounds

            Column {
                id: mainCol; width: parent.width; spacing: Math.round(14 * localScale)

                // Info banner
                Rectangle {
                    width: parent.width; height: infoCol.implicitHeight + Math.round(16 * localScale); radius: Math.round(Theme.cornerRadius * localScale)
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.06)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18); border.width: Math.max(1, Math.round(1 * localScale))

                    Column {
                        id: infoCol;
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(12 * localScale) }
                        spacing: Math.round(4 * localScale)
                        Text { width: parent.width; text: "󰀃  Toggle hotspot from the Quick Settings panel."; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7); wrapMode: Text.WordWrap }
                        Text { width: parent.width; text: "Requires an ethernet connection. Shares the same WiFi channel as your current connection."; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.30); wrapMode: Text.WordWrap; lineHeight: 1.4 }
                    }
                }

                // Config card
                Rectangle {
                    width: parent.width; height: cfgCol.implicitHeight + Math.round(20 * localScale); radius: Math.round(Theme.cornerRadius * localScale)
                    color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04); border.color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.07); border.width: Math.max(1, Math.round(1 * localScale))

                    Column {
                        id: cfgCol; anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(12 * localScale) }
                        spacing: Math.round(12 * localScale)

                        Text { text: "CREDENTIALS"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2; color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) }

                        // SSID
                        Item {
                            width: parent.width; height: Math.round(32 * localScale)
                            Text { anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "SSID"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.45); width: Math.round(72 * localScale) }
                            Rectangle {
                                anchors { left: parent.left; leftMargin: Math.round(76 * localScale); right: parent.right; verticalCenter: parent.verticalCenter }
                                height: Math.round(28 * localScale); radius: Math.round(7 * localScale)
                                color: ssidInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.05)
                                border.color: ssidInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.11); border.width: Math.max(1, Math.round(1 * localScale))
                                Behavior on border.color { ColorAnimation { duration: Anim.color} }
                                TextInput {
                                    id: ssidInput; anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                                    verticalAlignment: TextInput.AlignVCenter; color: Theme.text; font.pixelSize: Math.round(12 * localScale)
                                    selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                                    clip: true; maximumLength: 32
                                    text: root._ssid
                                    onTextChanged: { root._ssid = text; root._dirty = true }
                                }
                            }
                        }

                        // Password
                        Item {
                            width: parent.width; height: Math.round(32 * localScale)
                            Text { anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "Password"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.45); width: Math.round(72 * localScale) }
                            Rectangle {
                                anchors { left: parent.left; leftMargin: Math.round(76 * localScale); right: eyeBtn.left; rightMargin: Math.round(6 * localScale); verticalCenter: parent.verticalCenter }
                                height: Math.round(28 * localScale); radius: Math.round(7 * localScale)
                                color: passInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.05)
                                border.color: passInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.11); border.width: Math.max(1, Math.round(1 * localScale))
                                Behavior on border.color { ColorAnimation { duration: Anim.color} }
                                TextInput {
                                    id: passInput; anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                                    verticalAlignment: TextInput.AlignVCenter; color: Theme.text; font.pixelSize: Math.round(12 * localScale)
                                    selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                                    echoMode: root._showPass ? TextInput.Normal : TextInput.Password
                                    clip: true; maximumLength: 63
                                    text: root._password
                                    onTextChanged: { root._password = text; root._dirty = true }
                                }
                            }
                            Item {
                                id: eyeBtn; anchors { right: parent.right;
                                verticalCenter: parent.verticalCenter }
                                width: Math.round(28 * localScale); height: Math.round(28 * localScale)
                                Rectangle { anchors.fill: parent; radius: Math.round(6 * localScale); color: eyeH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08) : "transparent" }
                                Text { anchors.centerIn: parent; text: root._showPass ? "" : ""; font.pixelSize: Math.round(13 * localScale); color: root._showPass ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28) }
                                HoverHandler { id: eyeH; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: root._showPass = !root._showPass }
                            }
                        }

                        // Save button — only visible when dirty
                        Rectangle {
                            visible: root._dirty
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(90 * localScale); height: Math.round(28 * localScale); radius: Math.round(8 * localScale)
                            color: saveH.hovered
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                                : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40); border.width: Math.max(1, Math.round(1 * localScale))
                            Behavior on color { ColorAnimation { duration: Anim.fast} }
                            Text { anchors.centerIn: parent; text: "Save"; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium; color: Theme.active }
                            HoverHandler { id: saveH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._save() }
                        }
                    }
                }

                Item { width: parent.width; height: Math.round(4 * localScale) }
            }
        }
    }
}

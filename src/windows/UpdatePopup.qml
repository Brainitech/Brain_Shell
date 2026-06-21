import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// UpdatePopup — centered overlay popup for shell update notifications.
// Same structural pattern as ConfirmDialog: PanelWindow Overlay, dim background,
// centered fixed-size card. Instantiated per-screen in shell.qml.
//
// States:
//   checking      — spinner in header, no body (checking is brief, usually invisible)
//   available     — commit list + Update / Skip / Disable buttons
//   updating      — spinner, please wait text
//   conflict      — pull failed due to local changes: Stash & Update / Cancel
//   success       — Reload Shell / Dismiss, auto-dismiss after 10s
//   error         — generic error text + Retry / Close

PanelWindow {
    id: root
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool windowVisible: false
    visible: windowVisible
    
    Connections {
        target: UpdateService
        function onShowPopupChanged() {
            if (UpdateService.showPopup) {
                root.windowVisible = true
            } else {
                closeTimer.restart()
            }
        }
    }
    
    Timer {
        id: closeTimer
        interval: 20
        onTriggered: if (!UpdateService.showPopup) root.windowVisible = false
    }

    // Auto-dismiss success state after 10s
    Timer {
        interval: 3000
        running:  UpdateService.updateSuccess && root.windowVisible
        onTriggered: UpdateService.dismiss()
    }

    // ── Dim overlay ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
        // Pass through clicks in the dim area — update is non-blocking
        MouseArea {
            anchors.fill: parent
            // Intentionally no action — user must use the card buttons
        }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  Math.round(380 * localScale)
        radius: Math.round(Theme.notchRadius * localScale)
        color:  Theme.background
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        // Size to content
        height: cardCol.implicitHeight + Math.round(48 * localScale)

        // Prevent clicks from hitting the dim MouseArea
        MouseArea { anchors.fill: parent }

        // Left accent bar — color reflects state
        Rectangle {
            anchors {
                left:        parent.left
                top:         parent.top;    topMargin:    Math.round(10 * localScale)
                bottom:      parent.bottom; bottomMargin: Math.round(10 * localScale)
            }
            width:  Math.round(3 * localScale)
            radius: Math.round(2 * localScale)
            color: UpdateService.updateSuccess      ? "#a6e3a1"
                 : UpdateService.hasConflict        ? "#f5c47a"
                 : (UpdateService.lastError !== "" &&
                    !UpdateService.updating)        ? "#f38ba8"
                 : Theme.active
            Behavior on color { ColorAnimation { duration: Anim.normal} }
        }
        Item {
            visible: !UpdateService.updating
            anchors { top: parent.top; right: parent.right; topMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
            width: Math.round(24 * localScale); height: Math.round(24 * localScale)
        
            Rectangle {
                anchors.fill: parent; radius: Math.round(6 * localScale)
                color: xHov.hovered ? Qt.rgba(1,1,1,0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast} }
            }
            Text {
                anchors.centerIn: parent
                text: "✕"; font.pixelSize: Math.round(11 * localScale)
                color: Qt.rgba(1,1,1,0.35)
            }
            HoverHandler { id: xHov; cursorShape: Qt.PointingHandCursor }
            MouseArea { anchors.fill: parent; onClicked: UpdateService.dismiss() }
        }

        Column {
            id: cardCol
            anchors {
                top:         parent.top;   topMargin:   Math.round(24 * localScale)
                left:        parent.left;  leftMargin:  Math.round(22 * localScale)
                right:       parent.right; rightMargin: Math.round(18 * localScale)
            }
            spacing: Math.round(12 * localScale)

            // ── Header row ────────────────────────────────────────────────────
            Row {
                width:   parent.width
                spacing: Math.round(10 * localScale)

                Text {
                    id: headerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Math.round(18 * localScale)
                    text: UpdateService.updating || UpdateService.checking ? "󰑐"
                        : UpdateService.updateSuccess                      ? "󰄬"
                        : UpdateService.hasConflict                        ? "󰙨"
                        : UpdateService.lastError !== ""                   ? "󰅙"
                        : "󰑓"
                    color: UpdateService.updateSuccess      ? "#a6e3a1"
                         : UpdateService.hasConflict        ? "#f5c47a"
                         : (UpdateService.lastError !== "" &&
                            !UpdateService.updating)        ? "#f38ba8"
                         : Theme.active
                    Behavior on color { ColorAnimation { duration: Anim.normal} }

                    RotationAnimator {
                        target:      headerIcon
                        from:        0; to: 360
                        duration: Anim.megaSlow
                        loops:       Animation.Infinite
                        running:     UpdateService.updating || UpdateService.checking
                        easing.type: Anim.linear
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Math.round(13 * localScale)
                    font.weight:    Font.DemiBold
                    color:          Theme.text
                    text: UpdateService.updating      ? "Updating…"
                        : UpdateService.updateSuccess ? "Update Complete"
                        : UpdateService.hasConflict   ? "Conflict Detected"
                        : UpdateService.lastError !== "" && !UpdateService.updating
                                                      ? "Update Failed"
                        : "Brain Shell Update Available"
                }
            }

            Rectangle {
                width: parent.width; height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ── AVAILABLE ─────────────────────────────────────────────────────
            Column {
                visible: UpdateService.updateAvailable &&
                         !UpdateService.updating &&
                         !UpdateService.hasConflict &&
                         !UpdateService.updateSuccess &&
                         UpdateService.lastError === ""
                width:   parent.width
                spacing: Math.round(10 * localScale)

                Text {
                    text: UpdateService.commitsBehind + " new commit" +
                          (UpdateService.commitsBehind === 1 ? "" : "s") + " on main"
                    font.pixelSize: Math.round(12 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                }

                Column {
                    width:   parent.width
                    spacing: Math.round(4 * localScale)

                    Repeater {
                        model: Math.min(3, UpdateService.commitMessages.length)
                        delegate: Row {
                            spacing: Math.round(8 * localScale)
                            Text {
                                text:           "·"
                                font.pixelSize: Math.round(11 * localScale)
                                color:          Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.60)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                width:          parent.parent.width - Math.round(18 * localScale)
                                font.pixelSize: Math.round(11 * localScale)
                                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                                elide:          Text.ElideRight
                                // Strip the short hash prefix from the commit line
                                text: {
                                    var m = UpdateService.commitMessages[index] || ""
                                    var sp = m.indexOf(" ")
                                    return sp >= 0 ? m.substring(sp + 1) : m
                                }
                            }
                        }
                    }

                    Text {
                        visible:        UpdateService.commitMessages.length > 3
                        text:           "+ " + (UpdateService.commitMessages.length - 3) + " more"
                        font.pixelSize: Math.round(10 * localScale)
                        color:          Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40)
                        leftPadding:    Math.round(16 * localScale)
                    }
                }

                Row {
                    spacing: Math.round(8 * localScale)

                    // Update Now
                    Rectangle {
                        width: Math.round(108 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color: uH.hovered
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.26)
                            : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.13)
                        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text {
                            anchors.centerIn: parent
                            text:           "Update Now"
                            font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
                            color:          Theme.active
                        }
                        HoverHandler { id: uH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.applyUpdate() }
                    }

                    // Skip (dismiss this check)
                    Rectangle {
                        width: Math.round(58 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color:        skH.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                        border.color: Qt.rgba(1,1,1,0.09); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text { anchors.centerIn: parent; text: "Skip"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.52) }
                        HoverHandler { id: skH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.dismiss() }
                    }

                    // Disable auto-update
                    Rectangle {
                        width: Math.round(82 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color:        disH.hovered ? Qt.rgba(1,1,1,0.06) : "transparent"
                        border.color: Qt.rgba(1,1,1,0.07); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text { anchors.centerIn: parent; text: "Disable"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.28) }
                        HoverHandler { id: disH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.disableAutoUpdate() }
                    }
                }
            }

            // ── UPDATING ──────────────────────────────────────────────────────
            Column {
                visible: UpdateService.updating
                width:   parent.width
                spacing: Math.round(6 * localScale)

                Text {
                    text:           "Pulling latest changes from origin/main…"
                    font.pixelSize: Math.round(12 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    wrapMode:       Text.WordWrap
                    width:          parent.width
                }
                Text {
                    text:           "Do not close the shell."
                    font.pixelSize: Math.round(10 * localScale)
                    color:          Qt.rgba(1, 1, 1, 0.25)
                }
            }

            // ── CONFLICT ──────────────────────────────────────────────────────
            Column {
                visible: UpdateService.hasConflict && !UpdateService.updating
                width:   parent.width
                spacing: Math.round(12 * localScale)

                Text {
                    text: "Local uncommitted changes conflict with the update.\n" +
                          "Stash them aside to proceed, or cancel."
                    font.pixelSize: Math.round(12 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    wrapMode:       Text.WordWrap
                    width:          parent.width
                    lineHeight:     1.45
                }

                Row {
                    spacing: Math.round(8 * localScale)

                    // Stash & Update
                    Rectangle {
                        width: Math.round(128 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color: saH.hovered
                            ? Qt.rgba(245/255, 196/255, 122/255, 0.22)
                            : Qt.rgba(245/255, 196/255, 122/255, 0.10)
                        border.color: Qt.rgba(245/255, 196/255, 122/255, 0.38); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text {
                            anchors.centerIn: parent
                            text:           "Stash & Update"
                            font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
                            color:          "#f5c47a"
                        }
                        HoverHandler { id: saH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.stashAndUpdate() }
                    }

                    // Cancel
                    Rectangle {
                        width: Math.round(72 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color:        cxH.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                        border.color: Qt.rgba(1,1,1,0.09); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.52) }
                        HoverHandler { id: cxH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.dismiss() }
                    }
                }
            }

            // ── SUCCESS ───────────────────────────────────────────────────────
            Column {
                visible: UpdateService.updateSuccess
                width:   parent.width
                spacing: Math.round(12 * localScale)

                Text {
                    text: "Shell updated successfully.\nReload to apply the changes."
                    font.pixelSize: Math.round(12 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    wrapMode:       Text.WordWrap
                    width:          parent.width
                    lineHeight:     1.45
                }

                // Dismiss
                Rectangle {
                    width: Math.round(72 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                    color:        dmH.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                    border.color: Qt.rgba(1,1,1,0.09); border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                    Text { anchors.centerIn: parent; text: "Dismiss"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.52) }
                    HoverHandler { id: dmH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: UpdateService.dismiss() }
                }


                Text {
                    text:           "Auto-dismissing in a few seconds…"
                    font.pixelSize: Math.round(10 * localScale)
                    color:          Qt.rgba(1, 1, 1, 0.22)
                }
            }

            // ── ERROR ─────────────────────────────────────────────────────────
            Column {
                visible: UpdateService.lastError !== "" &&
                         !UpdateService.updating &&
                         !UpdateService.hasConflict
                width:   parent.width
                spacing: Math.round(12 * localScale)

                Text {
                    text:           UpdateService.lastError
                    font.pixelSize: Math.round(12 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    wrapMode:       Text.WordWrap
                    width:          parent.width
                }

                Row {
                    spacing: Math.round(8 * localScale)

                    // Retry
                    Rectangle {
                        width: Math.round(72 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color: rtH.hovered
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                            : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.09)
                        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text { anchors.centerIn: parent; text: "Retry"; font.pixelSize: Math.round(11 * localScale); color: Theme.active }
                        HoverHandler { id: rtH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.check() }
                    }

                    // Close
                    Rectangle {
                        width: Math.round(72 * localScale); height: Math.round(30 * localScale); radius: Math.round(8 * localScale)
                        color:        clH.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                        border.color: Qt.rgba(1,1,1,0.09); border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.color} }
                        Text { anchors.centerIn: parent; text: "Close"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.52) }
                        HoverHandler { id: clH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: UpdateService.dismiss() }
                    }
                }
            }
        }
    }

    // Escape to dismiss (same as ConfirmDialog)
    Item {
        anchors.fill: parent
        focus:        root.visible
        Keys.onEscapePressed: {
            if (!UpdateService.updating) UpdateService.dismiss()
        }
    }
}

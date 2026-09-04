import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"
import "../services/"

// Unified confirmation modal — replaces GfxWarning.qml.
// Driven entirely by Popups.confirm* props.
// Call Popups.showConfirm() to open, Popups.cancelConfirm() to close.
//
// Supported confirmAction values — all routed through scripts/PowerControl.sh:
//   "shutdown"        → hyprshutdown --post-cmd "systemctl poweroff"
//   "reboot"          → hyprshutdown --post-cmd "systemctl reboot"
//   "logout"          → hyprshutdown
//   "lock"            → loginctl lock-session
//   "suspend"         → systemctl suspend
//   "gpu-switch-envy" → pkexec scripts/GfxSwitch.sh <mode>, then systemctl reboot
//                       GfxSwitch.sh prints "authenticated" after pkexec auth succeeds,
//                       which triggers the processing card before envycontrol runs.

PanelWindow {
    id: root
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    color: "transparent"

    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    visible: Popups.confirmOpen || Popups.confirmRunning

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Region {
        id: confirmBlurReg
        item: confirmBox
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? confirmBlurReg : null

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: proc
        property var pendingCmd: []
        command: pendingCmd

        // Watch stdout for "authenticated" — printed by GfxSwitch.sh immediately
        // after pkexec grants root, before envycontrol starts doing its work.
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "authenticated") Popups.confirmRunning = true
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (reboot.command.length > 0) {
                if (exitCode === 0) {
                    reboot.running = true
                } else {
                    // Auth cancelled or envycontrol failed — hide card, abort.
                    Popups.confirmRunning = false
                    reboot.command = []
                }
            }
        }
    }

    Process {
        id: reboot
        command: []   // only populated for gpu-switch-envy
    }

    // ── Action dispatch ───────────────────────────────────────────────────────
    function confirm() {
        const powerScript = Quickshell.shellDir + "/src/scripts/PowerControl.sh"
        const gfxScript   = Quickshell.shellDir + "/src/scripts/GfxSwitch.sh"

        switch (Popups.confirmAction) {
            case "shutdown":
                Popups.cancelConfirm()
                proc.pendingCmd = ["bash", powerScript, "shutdown"]
                proc.running = true
                break
            case "reboot":
                Popups.cancelConfirm()
                proc.pendingCmd = ["bash", powerScript, "reboot"]
                proc.running = true
                break
            case "logout":
                Popups.cancelConfirm()
                proc.pendingCmd = ["bash", powerScript, "logout"]
                proc.running = true
                break
            case "lock":
                Popups.cancelConfirm()
                proc.pendingCmd = ["loginctl", "lock-session"]
                proc.running = true
                break
            case "suspend":
                Popups.cancelConfirm()
                proc.pendingCmd = ["systemctl", "suspend"]
                proc.running = true
                break
            case "gpu-switch-envy":
                // Capture mode BEFORE cancelConfirm() clears Popups state.
                const gfxMode   = Popups.confirmGfxMode
                reboot.command  = ["bash", powerScript, "reboot"]
                proc.pendingCmd = ["pkexec", "bash", gfxScript, gfxMode]
                Popups.cancelConfirm()
                proc.running    = true
                break
        }
    }

    function cancel() {
        if (!Popups.confirmRunning) Popups.cancelConfirm()
    }

    // ── Dim overlay ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: if (!Popups.confirmRunning) root.cancel()
        }
    }

    // ── Confirm dialog ────────────────────────────────────────────────────────
    Rectangle {
        id: confirmBox
        anchors.centerIn: parent
        width:  Math.round(360 * localScale)
        height: col.implicitHeight + Math.round(48 * localScale)
        radius: Math.round(Theme.cornerRadius * localScale)
        color:  Theme.background
        visible: Popups.confirmOpen && !Popups.confirmRunning

        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   Math.round(24 * localScale)
                leftMargin:  Math.round(24 * localScale)
                rightMargin: Math.round(24 * localScale)
            }
            spacing: Math.round(16 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    switch (Popups.confirmAction) {
                        case "shutdown":        return "⏻"
                        case "reboot":          return "↺"
                        case "logout":          return "⎋"
                        case "gpu-switch-envy": return "⚠️"
                        default:                return "⚠️"
                    }
                }
                font.pixelSize: Math.round(32 * localScale)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           Popups.confirmTitle
                color:          Theme.text
                font.pixelSize: Math.round(15 * localScale)
                font.bold:      true
            }

            Text {
                width:          parent.width
                text:           Popups.confirmMessage
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                font.pixelSize: Math.round(12 * localScale)
                wrapMode:       Text.WordWrap
                textFormat:     Text.RichText
                lineHeight:     1.4
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(10 * localScale)

                Rectangle {
                    width:  Math.round(130 * localScale)
                    height: Math.round(38 * localScale)
                    radius: Math.round(Theme.cornerRadius * localScale)
                    color:  cancelHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    Behavior on color { ColorAnimation { duration: Anim.color} }

                    Text {
                        anchors.centerIn: parent
                        text:           "Cancel"
                        color:          Theme.text
                        font.pixelSize: Math.round(13 * localScale)
                    }

                    HoverHandler { id: cancelHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.cancel() }
                }

                Rectangle {
                    width:  Math.round(130 * localScale)
                    height: Math.round(38 * localScale)
                    radius: Math.round(Theme.cornerRadius * localScale)
                    color:  confirmHov.hovered ? "#cc3a3a" : "#993030"
                    Behavior on color { ColorAnimation { duration: Anim.color} }

                    Text {
                        anchors.centerIn: parent
                        text:           Popups.confirmLabel
                        color:          "white"
                        font.pixelSize: Math.round(13 * localScale)
                        font.bold:      true
                    }

                    HoverHandler { id: confirmHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.confirm() }
                }
            }
        }
    }

    // ── Processing card ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  Math.round(300 * localScale)
        height: processingCol.implicitHeight + Math.round(56 * localScale)
        radius: Math.round(Theme.cornerRadius * localScale)
        color:  Theme.background
        visible: Popups.confirmRunning

        MouseArea { anchors.fill: parent }

        Column {
            id: processingCol
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   Math.round(28 * localScale)
                leftMargin:  Math.round(24 * localScale)
                rightMargin: Math.round(24 * localScale)
            }
            spacing: Math.round(18 * localScale)

            Canvas {
                id: spinnerCanvas
                anchors.horizontalCenter: parent.horizontalCenter
                width:  Math.round(40 * localScale)
                height: Math.round(40 * localScale)
                transformOrigin: Item.Center

                RotationAnimator {
                    target:      spinnerCanvas
                    from:        0
                    to:          360
                    duration: Anim.megaSlow
                    loops:       Animation.Infinite
                    running:     Popups.confirmRunning
                    easing.type: Anim.linear
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2, r = Math.round(16 * localScale)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.strokeStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    ctx.lineWidth   = Math.round(3 * localScale)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI)
                    ctx.strokeStyle = Theme.text
                    ctx.lineWidth   = Math.round(3 * localScale)
                    ctx.lineCap     = "round"
                    ctx.stroke()
                }

                Component.onCompleted: requestPaint()
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "Applying Changes"
                color:          Theme.text
                font.pixelSize: Math.round(15 * localScale)
                font.bold:      true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width:          parent.width
                text:           "Switching to <b>" + Popups.confirmGfxMode + "</b> graphics mode.<br>"
                                + "Your system will reboot when finished."
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                font.pixelSize: Math.round(12 * localScale)
                wrapMode:       Text.WordWrap
                textFormat:     Text.RichText
                lineHeight:     1.5
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  parent.width
                height: 1
                color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "Do not turn off your computer."
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                font.pixelSize: Math.round(11 * localScale)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Escape / Enter
    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onReturnPressed: root.confirm()
        Keys.onEscapePressed: root.cancel()
    }
}

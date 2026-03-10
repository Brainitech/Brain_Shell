import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../components"

// Dashboard Home tab
//
//  ┌──────────────┬───────────────────────────┬──────────────┐
//  │ Profile      │  Clock / Timer / Alarm    │ Brightness   │
//  │ (tall)       │  / Stopwatch              │ + 2×4 Tgls   │
//  ├──────────────┤───────────────────────────┤              │
//  │ Calendar     │  Player                   │              │
//  └──────────────┴───────────────────────────┴──────────────┘

Item {
    id: root

    // ── Layout ───────────────────────────────────────────────────────────────
    readonly property int colW:    210
    readonly property int gap:       8
    readonly property int cPad:     12
    readonly property int profileH: 160

    // ── Time ─────────────────────────────────────────────────────────────────
    property string timeHM:   "00:00"
    property string timeSec:  "00"
    property string timeAmPm: "AM"
    property string dateStr:  ""

    // ── Clock mode ───────────────────────────────────────────────────────────
    property string clockMode: "clock"

    // ── Stopwatch ────────────────────────────────────────────────────────────
    property int  swMs:      0
    property bool swRunning: false

    // ── Timer ────────────────────────────────────────────────────────────────
    property int  timerTotal:   25 * 60
    property int  timerLeft:    25 * 60
    property bool timerRunning: false

    // ── Brightness ───────────────────────────────────────────────────────────
    property real brightVal:  0.72   // 0.0 – 1.0, updated from brightnessctl
    property int  brightMax:  100
    property bool brightBusy: false  // debounce writes

    // ── Calendar ─────────────────────────────────────────────────────────────
    property int    calYear:       0
    property int    calMonth:      0
    property int    calToday:      0
    property var    calDays:       []
    property string calMonthLabel: ""

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dowNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    // ── Init ─────────────────────────────────────────────────────────────────
    Component.onCompleted: {
        updateTime()
        initCalendar()
        brightRead.running = true
    }

    // 1-second master tick
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            updateTime()
            if (root.swRunning) root.swMs += 1000
            if (root.timerRunning && root.timerLeft > 0) {
                root.timerLeft--
                if (root.timerLeft === 0) root.timerRunning = false
            }
        }
    }

    // ── Brightness processes ──────────────────────────────────────────────────

    // Read: brightnessctl -m  →  "device,name,X%,current,max"
    Process {
        id: brightRead
        command: ["bash", "-c", "brightnessctl -m"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(",")
                if (parts.length >= 5) {
                    var cur = parseInt(parts[3])
                    var max = parseInt(parts[4])
                    if (max > 0) {
                        root.brightMax = max
                        root.brightVal = cur / max
                    }
                }
            }
        }
    }

    // Write: brightnessctl set X (absolute value)
    Process {
        id: brightWrite
        command: ["bash", "-c", "brightnessctl set " + Math.round(root.brightVal * root.brightMax)]
        running: false
        onRunningChanged: {
            if (!running) root.brightBusy = false
        }
    }

    // Debounce timer — fires 120ms after last drag move
    Timer {
        id: brightDebounce
        interval: 120; repeat: false
        onTriggered: {
            root.brightBusy = true
            brightWrite.running = true
        }
    }

    function setBrightness(v) {
        root.brightVal = Math.max(0.0, Math.min(1.0, v))
        brightDebounce.restart()
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function zeroPad(n) { return n < 10 ? "0" + n : "" + n }

    function updateTime() {
        var d   = new Date()
        var h   = d.getHours()
        var m   = d.getMinutes()
        var s   = d.getSeconds()
        var pm  = h >= 12
        var h12 = h % 12; if (h12 === 0) h12 = 12
        timeHM   = zeroPad(h12) + ":" + zeroPad(m)
        timeSec  = zeroPad(s)
        timeAmPm = pm ? "PM" : "AM"
        var dows = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
        dateStr  = dows[d.getDay()] + "  " +
                   zeroPad(d.getDate()) + " " +
                   monthNames[d.getMonth()].substring(0,3).toUpperCase() + " " +
                   d.getFullYear()
    }

    function initCalendar() {
        var now  = new Date()
        calYear  = now.getFullYear()
        calMonth = now.getMonth()
        calToday = now.getDate()
        rebuildCal()
    }

    function rebuildCal() {
        calMonthLabel  = monthNames[calMonth].substring(0,3).toUpperCase() + "  " + calYear
        var firstDow   = new Date(calYear, calMonth, 1).getDay()
        var daysInMon  = new Date(calYear, calMonth + 1, 0).getDate()
        var daysInPrev = new Date(calYear, calMonth, 0).getDate()
        var days = []
        for (var p = firstDow - 1; p >= 0; p--)
            days.push({ n: daysInPrev - p, cur: false })
        for (var d = 1; d <= daysInMon; d++)
            days.push({ n: d, cur: true })
        var tail = 42 - days.length
        for (var t = 1; t <= tail; t++)
            days.push({ n: t, cur: false })
        calDays = days
    }

    function prevMonth() {
        if (calMonth === 0) { calMonth = 11; calYear-- } else calMonth--
        rebuildCal()
    }
    function nextMonth() {
        if (calMonth === 11) { calMonth = 0; calYear++ } else calMonth++
        rebuildCal()
    }

    function timerDisplay() {
        var m = Math.floor(timerLeft / 60); var s = timerLeft % 60
        return zeroPad(m) + ":" + zeroPad(s)
    }
    function timerProgress() {
        return timerTotal > 0 ? (timerTotal - timerLeft) / timerTotal : 0
    }
    function swDisplay() {
        var total = Math.floor(swMs / 1000)
        return zeroPad(Math.floor(total / 60)) + ":" + zeroPad(total % 60)
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  LEFT COLUMN — Profile + Calendar
    // ─────────────────────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: root.colW

        StatCard {
            id: profileCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH; padding: 0

            Item {
                anchors.fill: parent
                Column {
                    anchors.centerIn: parent; spacing: 10

                    Rectangle {
                        width: 64; height: 64; radius: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(166/255,208/255,247/255,0.22) }
                            GradientStop { position: 1.0; color: Qt.rgba(80/255,130/255,190/255,0.14) }
                        }
                        border.color: Qt.rgba(166/255,208/255,247/255,0.22); border.width: 1
                        Text { anchors.centerIn: parent; text: "󰀄"; font.pixelSize: 28; color: Theme.active }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Good day"; font.pixelSize: 14; font.weight: Font.DemiBold
                            color: Qt.rgba(235/255,240/255,255/255,0.9)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.dateStr; font.pixelSize: 9; font.family: "JetBrains Mono"
                            color: Qt.rgba(205/255,214/255,244/255,0.35)
                        }
                    }
                }
            }
        }

        StatCard {
            anchors {
                left: parent.left; right: parent.right
                top: profileCard.bottom; topMargin: root.gap; bottom: parent.bottom
            }
            padding: 0

            Item {
                anchors { fill: parent; margins: root.cPad }

                Item {
                    id: calHeader
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 22

                    Text {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "‹"; font.pixelSize: 15
                        color: calPH.hovered ? Qt.rgba(1,1,1,0.7) : Qt.rgba(1,1,1,0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        HoverHandler { id: calPH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: root.prevMonth() }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: root.calMonthLabel; font.pixelSize: 10; font.weight: Font.Bold
                        color: Theme.text
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "›"; font.pixelSize: 15
                        color: calNH.hovered ? Qt.rgba(1,1,1,0.7) : Qt.rgba(1,1,1,0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        HoverHandler { id: calNH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
                    }
                }

                Item {
                    id: dowRow
                    anchors { left: parent.left; right: parent.right; top: calHeader.bottom; topMargin: 3 }
                    height: 16
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: root.dowNames
                            delegate: Text {
                                width: Math.floor(dowRow.width / 7)
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData; font.pixelSize: 8; font.weight: Font.Bold
                                color: Qt.rgba(1,1,1,0.2)
                            }
                        }
                    }
                }

                Grid {
                    id: calGrid
                    anchors {
                        left: parent.left; right: parent.right
                        top: dowRow.bottom; topMargin: 2; bottom: parent.bottom
                    }
                    columns: 7; rows: 6
                    readonly property real cellW: width  / 7
                    readonly property real cellH: height / 6

                    Repeater {
                        model: root.calDays
                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: calGrid.cellW; height: calGrid.cellH

                            readonly property bool isToday:
                                modelData.cur && modelData.n === root.calToday &&
                                root.calMonth === new Date().getMonth() &&
                                root.calYear  === new Date().getFullYear()

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 4
                                height: width; radius: width / 2
                                color: isToday ? Qt.rgba(166/255,208/255,247/255,0.15)
                                       : cH.hovered && modelData.cur ? Qt.rgba(1,1,1,0.07) : "transparent"
                                border.color: isToday ? Qt.rgba(166/255,208/255,247/255,0.3) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    anchors.centerIn: parent; text: modelData.n
                                    font.pixelSize: 9; font.family: "JetBrains Mono"
                                    font.weight: isToday ? Font.Bold : Font.Normal
                                    color: isToday ? Theme.active
                                           : modelData.cur ? Qt.rgba(205/255,214/255,244/255,0.55)
                                                           : Qt.rgba(1,1,1,0.13)
                                }
                            }
                            HoverHandler { id: cH; enabled: modelData.cur; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  RIGHT COLUMN — Brightness + 2×4 Quick Settings
    // ─────────────────────────────────────────────────────────────────────────
    Item {
        id: rightCol
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.colW

        // ── Brightness card ───────────────────────────────────────────────────
        StatCard {
            id: brightCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 100; padding: 0

            Item {
                anchors { fill: parent; margins: root.cPad }

                Text {
                    id: brightLbl
                    anchors { left: parent.left; top: parent.top }
                    text: "BRIGHTNESS"; font.pixelSize: 9; font.weight: Font.Bold
                    color: Qt.rgba(166/255,208/255,247/255,0.35)
                }

                // Pct label top-right
                Text {
                    anchors { right: parent.right; top: parent.top }
                    text: Math.round(root.brightVal * 100) + "%"
                    font.pixelSize: 9; font.family: "JetBrains Mono"; font.weight: Font.Bold
                    color: Qt.rgba(166/255,208/255,247/255,0.6)
                }

                Row {
                    anchors {
                        left: parent.left; right: parent.right
                        top: brightLbl.bottom; topMargin: 10
                    }
                    spacing: 10

                    // Dim icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃞"; font.pixelSize: 14
                        color: Qt.rgba(1,1,1,0.3)
                    }

                    // ── Horizontal bar — same anatomy as AudioControl's ChannelColumn ──
                    Item {
                        id: brightTrackWrap
                        width: parent.width - 14 - 14 - parent.spacing * 2
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property int barH:    6
                        readonly property int thumbD:  16

                        // Track background
                        Rectangle {
                            id: brightTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: brightTrackWrap.barH
                            radius: height / 2
                            color: Qt.rgba(1,1,1,0.08)

                            // Fill — from left
                            Rectangle {
                                id: brightFill
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: Math.max(parent.radius * 2,
                                               parent.width * root.brightVal)
                                radius: parent.radius
                                color: Theme.active
                                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            }

                            // Drag + scroll
                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.SizeHorCursor
                                function calcVal(mx) {
                                    return Math.max(0.0, Math.min(1.0,
                                        (mx - brightTrackWrap.thumbD / 2) /
                                        (brightTrack.width - brightTrackWrap.thumbD)))
                                }
                                onPressed:         root.setBrightness(calcVal(mouseX))
                                onPositionChanged: if (pressed) root.setBrightness(calcVal(mouseX))
                            }
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: function(e) {
                                    root.setBrightness(root.brightVal + (e.angleDelta.y > 0 ? 0.05 : -0.05))
                                }
                            }
                        }

                        // Thumb — sits on top of track
                        Rectangle {
                            id: brightThumb
                            width:  brightTrackWrap.thumbD
                            height: brightTrackWrap.thumbD
                            radius: brightTrackWrap.thumbD / 2
                            color:  "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(
                                brightTrackWrap.width - width,
                                root.brightVal * (brightTrackWrap.width - width)
                            ))
                            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Bright icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃠"; font.pixelSize: 14
                        color: Qt.rgba(166/255,208/255,247/255,0.7)
                    }
                }
            }
        }

        // ── Quick Settings grid ───────────────────────────────────────────────
        StatCard {
            anchors {
                left: parent.left; right: parent.right
                top: brightCard.bottom; topMargin: root.gap; bottom: parent.bottom
            }
            padding: 0

            Item {
                anchors { fill: parent; margins: root.cPad }

                Text {
                    id: qsLbl
                    anchors { left: parent.left; top: parent.top }
                    text: "QUICK SETTINGS"; font.pixelSize: 9; font.weight: Font.Bold
                    color: Qt.rgba(166/255,208/255,247/255,0.35)
                }

                Grid {
                    id: tglGrid
                    anchors {
                        left: parent.left; right: parent.right
                        top: qsLbl.bottom; topMargin: 8; bottom: parent.bottom
                    }
                    columns: 2; rows: 4; spacing: 6
                    readonly property real btnW: (width  - spacing)     / 2
                    readonly property real btnH: (height - spacing * 3) / 4

                    component TglBtn: Rectangle {
                        id: tBtn
                        required property bool   on
                        required property string icon
                        required property string label
                        signal toggled()

                        width: tglGrid.btnW; height: tglGrid.btnH; radius: 10
                        color: on ? Qt.rgba(166/255,208/255,247/255,0.1)
                               : tH.hovered ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                        border.color: on ? Qt.rgba(166/255,208/255,247/255,0.2) : Qt.rgba(1,1,1,0.07)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }

                        Rectangle {
                            anchors { top: parent.top; right: parent.right; margins: 8 }
                            width: 6; height: 6; radius: 3
                            color: tBtn.on ? Theme.active : Qt.rgba(1,1,1,0.15)
                            Behavior on color { ColorAnimation { duration: 130 } }
                        }
                        Column {
                            anchors { left: parent.left; bottom: parent.bottom; margins: 9 }
                            spacing: 4
                            Text {
                                text: tBtn.icon; font.pixelSize: 17
                                color: tBtn.on ? Theme.active : Qt.rgba(1,1,1,0.28)
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                text: tBtn.label; font.pixelSize: 9; font.weight: Font.Medium
                                color: tBtn.on ? Qt.rgba(205/255,214/255,244/255,0.9)
                                               : Qt.rgba(205/255,214/255,244/255,0.35)
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        HoverHandler { id: tH; cursorShape: Qt.PointingHandCursor }
                        MouseArea    { anchors.fill: parent; onClicked: tBtn.toggled() }
                    }

                    TglBtn { on: ShellState.wifi;         icon: ShellState.wifi        ? "󰤨" : "󰤭"; label: "Wi-Fi";          onToggled: ShellState.wifi         = !ShellState.wifi         }
                    TglBtn { on: ShellState.bluetooth;    icon: ShellState.bluetooth   ? "󰂱" : "󰂲"; label: "Bluetooth";      onToggled: ShellState.bluetooth    = !ShellState.bluetooth    }
                    TglBtn { on: ShellState.nightLight;   icon: "󰖐";                               label: "Night Light";    onToggled: ShellState.nightLight   = !ShellState.nightLight   }
                    TglBtn { on: ShellState.caffeine;     icon: "󰅶";                               label: "Caffeine";       onToggled: ShellState.caffeine     = !ShellState.caffeine     }
                    TglBtn { on: ShellState.dnd;          icon: ShellState.dnd         ? "󰂛" : "󰂚"; label: "Do Not Disturb"; onToggled: ShellState.dnd          = !ShellState.dnd          }
                    TglBtn { on: ShellState.gameMode;     icon: "󰊚";                               label: "Game Mode";      onToggled: ShellState.gameMode     = !ShellState.gameMode     }
                    TglBtn { on: ShellState.screenRecord; icon: "󰻂";                               label: "Screen Rec";     onToggled: ShellState.screenRecord = !ShellState.screenRecord }
                    TglBtn { on: false;                   icon: "󰹑";                               label: "Screenshot";     onToggled: { /* TODO */ }           }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  CENTER COLUMN — Clock (top) + Player (bottom)
    // ─────────────────────────────────────────────────────────────────────────
    Item {
        id: centerCol
        anchors {
            left: leftCol.right;   leftMargin:  root.gap
            right: rightCol.left;  rightMargin: root.gap
            top: parent.top;       bottom: parent.bottom
        }

        // ── Clock card ────────────────────────────────────────────────────────
        StatCard {
            id: clockCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 220; padding: 0

            Item {
                anchors.fill: parent

                // ── CLOCK page ────────────────────────────────────────────────
                Item {
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: clockTabs.top }
                    visible: root.clockMode === "clock"
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.timeHM
                            font.pixelSize: 72; font.weight: Font.Bold
                            font.family: "JetBrains Mono"; font.letterSpacing: -3
                            color: Qt.rgba(235/255,240/255,255/255,1); lineHeight: 1
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ":" + root.timeSec; font.pixelSize: 20
                                font.family: "JetBrains Mono"
                                color: Qt.rgba(166/255,208/255,247/255,0.45)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.timeAmPm; font.pixelSize: 11; font.weight: Font.Bold
                                font.letterSpacing: 2; color: Qt.rgba(166/255,208/255,247/255,0.5)
                            }
                        }
                    }
                }

                // ── TIMER page ────────────────────────────────────────────────
                Item {
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: clockTabs.top }
                    visible: root.clockMode === "timer"
                    Column {
                        anchors.centerIn: parent; spacing: 10

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 100; height: 100
                            Canvas {
                                id: timerCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width/2, cy = height/2, r = 44
                                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2)
                                    ctx.strokeStyle = Qt.rgba(1,1,1,0.08)
                                    ctx.lineWidth = 5; ctx.stroke()
                                    var prog = root.timerProgress()
                                    if (prog > 0) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + Math.PI*2*prog)
                                        ctx.strokeStyle = Qt.rgba(166/255,208/255,247/255,0.85)
                                        ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.stroke()
                                    }
                                }
                                Connections {
                                    target: root
                                    function onTimerLeftChanged() { timerCanvas.requestPaint() }
                                }
                            }
                            Column {
                                anchors.centerIn: parent; spacing: 1
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.timerDisplay(); font.pixelSize: 22; font.weight: Font.Bold
                                    font.family: "JetBrains Mono"; color: Qt.rgba(235/255,240/255,255/255,0.9)
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "remaining"; font.pixelSize: 8; color: Qt.rgba(1,1,1,0.25)
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 5
                            Repeater {
                                model: [5, 15, 25, 60]
                                delegate: Rectangle {
                                    required property var modelData; required property int index
                                    width: 36; height: 22; radius: 6
                                    color: preH.hovered ? Qt.rgba(166/255,208/255,247/255,0.1) : Qt.rgba(1,1,1,0.05)
                                    border.color: Qt.rgba(1,1,1,0.1); border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData < 60 ? modelData + "m" : "1h"
                                        font.pixelSize: 9; font.family: "JetBrains Mono"; font.weight: Font.Bold
                                        color: Qt.rgba(1,1,1,0.45)
                                    }
                                    HoverHandler { id: preH; cursorShape: Qt.PointingHandCursor }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { root.timerTotal = modelData*60; root.timerLeft = modelData*60; root.timerRunning = false }
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                            Repeater {
                                model: [
                                    { label: root.timerRunning ? "Pause" : "Start", primary: true  },
                                    { label: "Reset",                               primary: false }
                                ]
                                delegate: Rectangle {
                                    required property var modelData; required property int index
                                    width: 58; height: 26; radius: 8
                                    color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.12) : Qt.rgba(1,1,1,0.05)
                                    border.color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.22) : Qt.rgba(1,1,1,0.1)
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 10; font.weight: Font.Medium; color: modelData.primary ? Theme.active : Qt.rgba(1,1,1,0.4) }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (modelData.primary) root.timerRunning = !root.timerRunning
                                            else { root.timerLeft = root.timerTotal; root.timerRunning = false }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── ALARM page ────────────────────────────────────────────────
                Item {
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: clockTabs.top }
                    visible: root.clockMode === "alarm"
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰀠"; font.pixelSize: 36; color: Qt.rgba(166/255,208/255,247/255,0.3) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No alarms set"; font.pixelSize: 13; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.3) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Coming soon"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.18) }
                    }
                }

                // ── STOPWATCH page ────────────────────────────────────────────
                Item {
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: clockTabs.top }
                    visible: root.clockMode === "stopwatch"
                    Column {
                        anchors.centerIn: parent; spacing: 12
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.swDisplay(); font.pixelSize: 52; font.weight: Font.Bold
                            font.family: "JetBrains Mono"; font.letterSpacing: -1
                            color: Qt.rgba(235/255,240/255,255/255,0.9)
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                            Repeater {
                                model: [
                                    { label: root.swRunning ? "Stop" : "Start", primary: true  },
                                    { label: "Reset",                           primary: false }
                                ]
                                delegate: Rectangle {
                                    required property var modelData; required property int index
                                    width: 58; height: 26; radius: 8
                                    color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.12) : Qt.rgba(1,1,1,0.05)
                                    border.color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.22) : Qt.rgba(1,1,1,0.1)
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 10; font.weight: Font.Medium; color: modelData.primary ? Theme.active : Qt.rgba(1,1,1,0.4) }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (modelData.primary) root.swRunning = !root.swRunning
                                            else { root.swMs = 0; root.swRunning = false }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // TabSwitcher — pinned to bottom
                TabSwitcher {
                    id: clockTabs
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    orientation: "horizontal"; width: parent.width
                    currentPage: root.clockMode
                    model: [
                        { key: "clock",     icon: "󰥔", label: "Clock"     },
                        { key: "timer",     icon: "󱎫", label: "Timer"     },
                        { key: "alarm",     icon: "󰀠", label: "Alarm"     },
                        { key: "stopwatch", icon: "󰔚", label: "Stopwatch" }
                    ]
                    onPageChanged: function(key) { root.clockMode = key }
                }
            }
        }

        // ── Player card ───────────────────────────────────────────────────────
        StatCard {
            anchors {
                left: parent.left; right: parent.right
                top: clockCard.bottom; topMargin: root.gap; bottom: parent.bottom
            }
            padding: 0

            Row {
                anchors.fill: parent; spacing: 0

                // ── Album art — square, static ────────────────────────────────
                Rectangle {
                    id: artSquare
                    width: parent.height; height: parent.height
                    radius: Theme.cornerRadius; clip: true
                    color: "#0d1e2b"

                    // Gradient wash
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(166/255,208/255,247/255,0.06) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Static disc rings — centered, no animation
                    Item {
                        anchors.centerIn: parent; width: 70; height: 70
                        Rectangle {
                            anchors.centerIn: parent; width: parent.width; height: parent.width; radius: parent.width/2
                            color: "transparent"
                            border.color: Qt.rgba(166/255,208/255,247/255,0.18); border.width: 1
                        }
                        Rectangle {
                            anchors.centerIn: parent; width: 50; height: 50; radius: 25
                            color: "transparent"
                            border.color: Qt.rgba(166/255,208/255,247/255,0.09); border.width: 1
                        }
                        Rectangle {
                            anchors.centerIn: parent; width: 16; height: 16; radius: 8
                            color: "#0a1420"
                            border.color: Qt.rgba(166/255,208/255,247/255,0.22); border.width: 1
                        }
                    }
                }

                // ── Track info + controls ─────────────────────────────────────
                Item {
                    width: parent.width - artSquare.width; height: parent.height

                    // Top section: badge → title → artist → progress + timestamps
                    Column {
                        anchors {
                            top: parent.top; topMargin: 14
                            left: parent.left; leftMargin: 14
                            right: parent.right; rightMargin: 14
                        }
                        spacing: 5

                        // Source badge
                        Rectangle {
                            height: 18; width: badgeRow.implicitWidth + 14; radius: 9
                            color: Qt.rgba(166/255,208/255,247/255,0.07)
                            border.color: Qt.rgba(166/255,208/255,247/255,0.14); border.width: 1
                            Row {
                                id: badgeRow; anchors.centerIn: parent; spacing: 5
                                Rectangle {
                                    width: 5; height: 5; radius: 2.5; color: Theme.active
                                    anchors.verticalCenter: parent.verticalCenter
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 700 }
                                        NumberAnimation { to: 1.0; duration: 700 }
                                    }
                                }
                                Text {
                                    text: "No media"; font.pixelSize: 9; font.weight: Font.Bold
                                    font.letterSpacing: 0.8; color: Theme.active
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Text {
                            width: parent.width; text: "Nothing Playing"
                            font.pixelSize: 15; font.weight: Font.Bold
                            color: Qt.rgba(235/255,240/255,255/255,0.9); elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width; text: "Open a media player"
                            font.pixelSize: 11; color: Qt.rgba(205/255,214/255,244/255,0.35)
                            elide: Text.ElideRight
                        }

                        // Progress track — same style as brightness bar
                        Item {
                            width: parent.width; height: 22

                            Rectangle {
                                id: progTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 4; radius: 2
                                color: Qt.rgba(1,1,1,0.08)

                                Rectangle {
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                    width: 0; radius: 2; color: Theme.active
                                }
                            }
                            // Timestamps sit at the vertical ends of this Item
                            Text {
                                anchors { left: parent.left; bottom: parent.bottom }
                                text: "0:00"; font.pixelSize: 9; font.family: "JetBrains Mono"
                                color: Qt.rgba(1,1,1,0.2)
                            }
                            Text {
                                anchors { right: parent.right; bottom: parent.bottom }
                                text: "0:00"; font.pixelSize: 9; font.family: "JetBrains Mono"
                                color: Qt.rgba(1,1,1,0.2)
                            }
                        }
                    }

                    // Bottom section: shuffle · prev · play · next · repeat
                    Row {
                        anchors {
                            bottom: parent.bottom; bottomMargin: 12
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 4

                        Repeater {
                            model: [
                                { icon: "⇄",  key: "shuffle", small: true  },
                                { icon: "⏮",  key: "prev",    small: true  },
                                { icon: "⏵",  key: "play",    small: false },
                                { icon: "⏭",  key: "next",    small: true  },
                                { icon: "↺",  key: "repeat",  small: true  }
                            ]
                            delegate: Rectangle {
                                required property var  modelData
                                required property int  index
                                readonly property bool isPlay: modelData.key === "play"

                                width:  isPlay ? 40 : 30; height: isPlay ? 40 : 30
                                radius: isPlay ? 10 : 8
                                color: isPlay ? Qt.rgba(166/255,208/255,247/255,0.12)
                                       : cH.hovered ? Qt.rgba(1,1,1,0.07) : "transparent"
                                border.color: isPlay ? Qt.rgba(166/255,208/255,247/255,0.22) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon; font.pixelSize: isPlay ? 16 : 12
                                    color: isPlay ? Theme.active : Qt.rgba(1,1,1,0.35)
                                }
                                HoverHandler { id: cH; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
        }
    }
}

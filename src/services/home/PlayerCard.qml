import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0

    // ── Source blocklist ──────────────────────────────────────────────────────
    readonly property var _blocked: [
        "kdeconnect", 
        "gsconnect", 
        "playerctld",
        "plasma-browser-integration"
    ]

    // Explicit count tracker — forces filteredPlayers to re-evaluate whenever
    // a player joins or leaves the MPRIS list.
    property int _mprisCount: Mpris.players.values.length

    readonly property var filteredPlayers: {
        var _dep = root._mprisCount  // explicit dependency on list size changes
        var result = []
        var vals = Mpris.players.values
        for (var i = 0; i < vals.length; i++) {
            var id = (vals[i].identity || "").toLowerCase()
            var isBlocked = false
            
            for (var j = 0; j < root._blocked.length; j++) {
                if (id.indexOf(root._blocked[j]) !== -1) {
                    isBlocked = true
                    break
                }
            }
            
            if (!isBlocked) {
                result.push(vals[i])
            }
        }
        return result
    }

    property int selectedPlayerIndex: 0
    property bool _dropdownOpen: false

    onVisibleChanged: if (!visible) root._dropdownOpen = false

    onFilteredPlayersChanged: {
        // Prefer keeping the same player object selected after list change.
        var oldPlayer = root.player
        if (oldPlayer) {
            for (var i = 0; i < root.filteredPlayers.length; i++) {
                if (root.filteredPlayers[i] === oldPlayer) {
                    root.selectedPlayerIndex = i
                    return
                }
            }
        }
        // Fallback: clamp to valid range
        if (root.selectedPlayerIndex >= root.filteredPlayers.length)
            root.selectedPlayerIndex = Math.max(0, root.filteredPlayers.length - 1)
    }

    // ── MPRIS ─────────────────────────────────────────────────────────────────
    readonly property var player: root.filteredPlayers.length > 0
                                  ? root.filteredPlayers[root.selectedPlayerIndex] : null

    readonly property bool   isPlaying: root.player?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string artUrl:    root.player?.trackArtUrl ?? ""

    readonly property string title: {
        var t = root.player?.trackTitle
        return (t && t !== "") ? t : "Nothing Playing"
    }
    readonly property string artist: {
        var a = root.player?.trackArtists
        if (!a) return ""
        if (typeof a === "string") return a
        if (typeof a.join === "function") return a.join(", ")
        return a.toString()
    }

    readonly property real length:   root.player?.length   ?? 0
    readonly property real position: root.player?.position ?? 0

    property real _pos: 0
    onPositionChanged: root._pos = position

    Timer {
        interval: 1000; running: root.isPlaying; repeat: true
        onTriggered: {
            if (root.length > 0)
                root._pos = Math.min(root._pos + 1, root.length)
        }
    }

    function _fmt(sec) {
        var s = Math.floor(sec)
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    readonly property real _progress: root.length > 0 ? root._pos / root.length : 0

    // ── Shared cava bars (32 bars from CavaService) ───────────────────────────
    readonly property int _cavaBars: 32
    readonly property var _bars: CavaService.bars

    // ── Player icon helper ────────────────────────────────────────────────────
    function _playerIcon(player) {
        if (!player) return "♪"
        var id = (player.identity || "").toLowerCase()
        if (id.indexOf("spotify")  !== -1) return ""
        if (id.indexOf("firefox")  !== -1) return ""
        if (id.indexOf("chromium") !== -1) return ""
        if (id.indexOf("chrome")   !== -1) return ""
        if (id.indexOf("brave")    !== -1) return ""
        if (id.indexOf("youtube")  !== -1) return ""
        return "♪"
    }

    // ── Player label helper ───────────────────────────────────────────────────
    function _playerLabel(player) {
        if (!player) return "—"
        var id = (player.identity || "").toLowerCase()
        if (id.indexOf("spotify")  !== -1) return "Spotify"
        if (id.indexOf("firefox")  !== -1) return "Firefox"
        if (id.indexOf("chromium") !== -1) return "Chromium"
        if (id.indexOf("chrome")   !== -1) return "Chrome"
        if (id.indexOf("brave")    !== -1) return "Brave"
        if (id.indexOf("youtube")  !== -1) return "YouTube"
        if (id.indexOf("edge")     !== -1) return "Edge"
        if (id.indexOf("opera")    !== -1) return "Opera"
        if (id.indexOf("vivaldi")  !== -1) return "Vivaldi"
        return player.identity || "Player"
    }

    // ── Background visuals ────────────────────────────────────────────────────
    Item {
        id: bgSource
        anchors.fill:  parent
        opacity:       0
        layer.enabled: true

        Item {
            id: artSource
            anchors.fill:  parent
            layer.enabled: true
            Image {
                anchors.fill: parent
                source:   root.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth:   true
            }
        }

        MultiEffect {
            source:       artSource
            anchors.fill: parent
            visible:      root.artUrl !== ""
            opacity:      root.artUrl !== "" ? 1 : 0
            blurEnabled:  true
            blur:         0.5
            blurMax:      32
            saturation:   0.2
            Behavior on opacity { NumberAnimation { duration: Anim.slower} }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.38) }
                GradientStop { position: 0.4; color: Qt.rgba(0,0,0,0.50) }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.88) }
            }
        }
    }

    Rectangle {
        id: bgMask
        anchors.fill:  parent
        radius:        Theme.cornerRadius
        visible:       false
        layer.enabled: true
    }

    MultiEffect {
        source:           bgSource
        anchors.fill:     parent
        maskEnabled:      true
        maskSource:       bgMask
        maskThresholdMin: 0.5
        maskSpreadAtMin:  1.0
    }

    // ── Track name + artist ───────────────────────────────────────────────────
    Column {
        anchors {
            left:  parent.left;  leftMargin:  Math.round(120 * localScale) 
            right: parent.right; rightMargin: Math.round(120 * localScale) 
            top:   parent.top;   topMargin:   Math.round(16 * localScale)
        }
        spacing: Math.round(4 * localScale)
        clip: true // Ensure nothing bleeds outside the column boundaries
        // ── Title with Marquee Scroll ──
        Item {
            width: parent.width
            height: Math.round(22 * localScale) 
            clip: true 
            TextMetrics {
                id: titleMetrics
                font: titleText.font
                text: root.title
            }
            Text {
                id: titleText
                text: root.title
                font.pixelSize: Math.round(18 * localScale); font.weight: Font.Bold
                color: "#ffffff"
                anchors.horizontalCenter: titleMetrics.width <= parent.width ? parent.horizontalCenter : undefined
                NumberAnimation on x {
                    id: marqueeAnim
                    running: titleMetrics.width > titleText.parent.width && root.isPlaying
                    from: titleText.parent.width
                    to: -titleMetrics.width
                    duration: Math.max(0, (titleMetrics.width + titleText.parent.width) * 20)
                    loops: Animation.Infinite
                }
                onTextChanged: marqueeAnim.restart()
            }
        }
        Text {
            width:   parent.width
            text:    root.artist
            visible: root.artist !== ""
            font.pixelSize: Math.round(13 * localScale)
            color: Qt.rgba(1,1,1,0.55) 
            
            maximumLineCount: 1
            elide: Text.ElideRight
            
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Bottom stack: controls + progress (raised to give room for picker) ──────
    Column {
        anchors {
            left:   parent.left;   leftMargin:   Math.round(14 * localScale)
            right:  parent.right;  rightMargin:  Math.round(14 * localScale)
            bottom: parent.bottom; bottomMargin: Math.round(54 * localScale)
        }
        spacing: Math.round(6 * localScale)

        // Controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(28 * localScale)
            Repeater {
                model: [ { key: "prev" }, { key: "play" }, { key: "next" } ]
                delegate: Rectangle {
                    required property var  modelData
                    required property int  index
                    readonly property bool isPlay: modelData.key === "play"
                    readonly property string dispIcon: {
                        if (modelData.key === "prev") return "󰒫"
                        if (modelData.key === "next") return "󰒬"
                        return !root.isPlaying ? "󰐊" : "󰏤"
                    }
                    width: Math.round(36 * localScale); height: Math.round(36 * localScale) 
                    radius: height / 2
                    color: isPlay
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                           : cH.hovered ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.06)
                    border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                    Text {
                        anchors.centerIn: parent
                        text: parent.dispIcon
                        font.pixelSize: isPlay ? Math.round(18 * localScale) : Math.round(14 * localScale)
                        color: isPlay ? Theme.active : Qt.rgba(1,1,1,0.7)
                    }
                    HoverHandler { id: cH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!root.player) return
                            switch (modelData.key) {
                                case "play":
                                    if (root.player.canTogglePlaying)
                                        root.player.isPlaying = !root.player.isPlaying
                                    break
                                case "prev":
                                    if (root.player.canGoPrevious) root.player.previous()
                                    break
                                case "next":
                                    if (root.player.canGoNext) root.player.next()
                                    break
                            }
                        }
                    }
                }
            }
        }

        // Progress bar + timestamps
        Column {
            width: parent.width; spacing: Math.round(3 * localScale)
            Item {
                width: parent.width; height: Math.round(6 * localScale)
                Rectangle {
                    anchors.fill: parent; radius: height / 2
                    color: Qt.rgba(1,1,1,0.2)
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (root.player && root.length > 0) {
                                var f = mouse.x / width
                                root.player.position = f * root.length
                                root._pos = f * root.length
                            }
                        }
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width:  Math.max(radius * 2, parent.width * root._progress)
                        radius: parent.radius; color: Theme.active
                        Behavior on width { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic} }
                    }
                }
            }
            Item {
                width: parent.width; height: Math.round(14 * localScale)

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root._pos)
                    font.pixelSize: Math.round(9 * localScale); font.family: "JetBrains Mono"
                    color: Qt.rgba(1,1,1,0.4)
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root.length)
                    font.pixelSize: Math.round(9 * localScale); font.family: "JetBrains Mono"
                    color: Qt.rgba(1,1,1,0.4)
                }
            }
        }
    }

    // ── Source picker — upward-expanding pill ─────────────────────────────────
    // Sits in the gap between the controls and the card bottom; expands upward.
    Item {
        id: sourcePicker
        anchors {
            top:          parent.top
            right:        parent.right
            topMargin:    Math.round(12 * localScale)
            rightMargin:  Math.round(12 * localScale)
        }
        visible: root.filteredPlayers.length > 1
        z:       30
        
        width:  pill.width
        height: pill.height

        Rectangle {
            id: pill
            anchors.top:   parent.top
            anchors.right: parent.right

            // Width tracks the active row + padding
            width: activeRow.implicitWidth + Math.round(24 * localScale)

            readonly property int _rowH: Math.round(26 * localScale)
            height: root._dropdownOpen 
                    ? (_rowH * root.filteredPlayers.length) 
                    : _rowH
            Behavior on height { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic} }

            radius:       _rowH / 2
            clip:         true
            color:        Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
            border.color: root._dropdownOpen
                          ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
                          : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Anim.mediumFast} }

            // Stacks downward from the top
            Column {
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                spacing: 0

                // ── Active player row (Always at the top) ─────────────
                Item {
                    height: pill._rowH
                    width:  parent.width

                    Row {
                        id: activeRow
                        anchors.centerIn: parent
                        spacing: Math.round(6 * localScale)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.player ? root._playerIcon(root.player) : "♪"
                            font.pixelSize: Math.round(11 * localScale)
                            color:          Theme.active
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.player ? root._playerLabel(root.player) : "Player"
                            font.pixelSize: Math.round(11 * localScale)
                            font.weight:    Font.Medium
                            color:          Qt.rgba(1,1,1,0.92)
                            // Cap width so crazy browser identities don't stretch the pill
                            width:          Math.min(implicitWidth, Math.round(120 * localScale)) 
                            elide:          Text.ElideRight
                        }
                    }

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked:    root._dropdownOpen = !root._dropdownOpen
                    }
                }

                // ── Other player rows (Drop down below active) ─────────
                Repeater {
                    model: root.filteredPlayers
                    delegate: Item {
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === root.selectedPlayerIndex

                        width:  parent.width
                        height: isCurrent ? 0 : (root._dropdownOpen ? pill._rowH : 0)
                        visible: !isCurrent
                        opacity: root._dropdownOpen ? 1 : 0
                        
                        Behavior on height  { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic} }
                        Behavior on opacity { NumberAnimation { duration: Anim.color} }

                        Row {
                            anchors.centerIn: parent
                            spacing: Math.round(6 * localScale)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           root._playerIcon(modelData)
                                font.pixelSize: Math.round(11 * localScale)
                                color:          rowH.hovered ? Qt.rgba(1,1,1,0.90) : Qt.rgba(1,1,1,0.55)
                                Behavior on color { ColorAnimation { duration: Anim.fast} }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           root._playerLabel(modelData)
                                font.pixelSize: Math.round(11 * localScale)
                                color:          rowH.hovered ? Qt.rgba(1,1,1,0.90) : Qt.rgba(1,1,1,0.55)
                                width:          Math.min(implicitWidth, Math.round(120 * localScale))
                                elide:          Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Anim.fast} }
                            }
                        }

                        HoverHandler { id: rowH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedPlayerIndex = index
                                root._dropdownOpen = false
                            }
                        }
                    }
                }
            }
        }
    } 

    // ── Cava bars — independent, always flush with the card bottom ────────────
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: Math.round(7 * localScale); rightMargin: Math.round(7 * localScale); bottomMargin: Math.round(4 * localScale) }
        height: Math.round(32 * localScale)
        Row {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: Math.round(2 * localScale)
            readonly property real barW: Math.max(1, (parent.width - spacing * (root._cavaBars - 1)) / root._cavaBars)
            Repeater {
                model: root._bars
                delegate: Item {
                    required property int modelData
                    required property int index
                    width: parent.barW; height: Math.round(32 * localScale)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:  parent.width
                        readonly property real _amp: root.isPlaying ? (modelData / 100) : 0
                        height: Math.max(2, _amp * Math.round(32 * localScale))
                        radius: width / 2
                        color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25 + _amp * 0.65)
                        Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic} }
                    }
                }
            }
        }
    }

    // Border
    Rectangle {
        anchors.fill: parent
        radius:       Theme.cornerRadius
        color:        "transparent"
        border.color: Qt.rgba(1,1,1,0.08)
        border.width: 1
    }

    // Close dropdown on click outside
    TapHandler {
        enabled: root._dropdownOpen
        onTapped: root._dropdownOpen = false
    }
}

import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0

    property bool _dropdownOpen: false

    onVisibleChanged: {
        if (!visible) root._dropdownOpen = false
    }

    Binding {
        target: CavaService
        property: "dashboardVisible"
        value: root.visible && Popups.dashboardOpen && Popups.dashboardPage === "home"
    }

    // ── MPRIS (via MediaService) ─────────────────────────────────────────────
    readonly property var    player:    MediaService.activePlayer
    readonly property bool   isPlaying: MediaService.isPlaying
    readonly property string artUrl:    MediaService.artUrl
    readonly property string title:     MediaService.title
    readonly property string artist:    MediaService.artist
    readonly property real   length:    MediaService.length
    readonly property real   _pos:      MediaService._pos
    readonly property real   _progress: MediaService.progress

    function _fmt(sec) { return MediaService._fmt(sec) }

    // ── Shared cava bars (32 bars from CavaService) ───────────────────────────
    readonly property int _cavaBars: 32
    readonly property var _bars: CavaService.bars

    // Signal CavaService consumer visibility
    Component.onDestruction: CavaService.dashboardVisible = false

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

    // Tap background to close dropdown or raise app (first child = bottom Z)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        Timer {
            id: raiseTimer
            interval: 150
            repeat: false
            onTriggered: MediaService.raisePlayer()
        }

        onClicked: {
            if (root._dropdownOpen) {
                root._dropdownOpen = false;
            } else {
                SurfaceState.close();
                raiseTimer.start();
            }
        }
    }

    // ── Track name + artist ───────────────────────────────────────────────────
    Column {
        anchors {
            left:  parent.left;  leftMargin:  Math.round(120 * localScale) 
            right: parent.right; rightMargin: Math.round(120 * localScale) 
            top:   parent.top;   topMargin:   Math.round(16 * localScale)
        }
        spacing: Math.round(4 * localScale)
        clip: true
        Item {
            width: parent.width
            height: Math.round(32 * localScale) 
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
                color: Theme.text
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
            color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.55) 
            
            maximumLineCount: 1
            elide: Text.ElideRight
            
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Bottom stack: controls + progress ──────────────────────────────────────
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
                           : cH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.14) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.06)
                    border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                    Text {
                        anchors.centerIn: parent
                        text: parent.dispIcon
                        font.pixelSize: isPlay ? Math.round(18 * localScale) : Math.round(14 * localScale)
                        color: isPlay ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.7)
                    }
                    HoverHandler { id: cH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData.key === "play") MediaService.toggle()
                            else if (modelData.key === "prev") MediaService.prev()
                            else if (modelData.key === "next") MediaService.next()
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
                    color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.2)
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (root.length > 0)
                                MediaService.seek(mouse.x / width)
                        }
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width:  Math.max(radius * 2, parent.width * root._progress)
                        radius: parent.radius; color: Theme.active
                        Behavior on width { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }
                    }
                }
            }
            Item {
                width: parent.width; height: Math.round(14 * localScale)

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root._pos)
                    font.pixelSize: Math.round(9 * localScale); font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.4)
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root._fmt(root.length)
                    font.pixelSize: Math.round(9 * localScale); font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.4)
                }
            }
        }
    }

    // ── Source picker — upward-expanding pill ─────────────────────────────────
    Item {
        id: sourcePicker
        anchors {
            top:          parent.top
            right:        parent.right
            topMargin:    Math.round(12 * localScale)
            rightMargin:  Math.round(12 * localScale)
        }
        visible: MediaService.filteredPlayers.length > 1
        z:       30
        
        width:  pill.width
        height: pill.height

        Rectangle {
            id: pill
            anchors.top:   parent.top
            anchors.right: parent.right

            width: activeRow.implicitWidth + Math.round(24 * localScale)

            readonly property int _rowH: Math.round(26 * localScale)
            height: root._dropdownOpen 
                    ? (_rowH * MediaService.filteredPlayers.length) 
                    : _rowH
            Behavior on height { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }

            radius:       _rowH / 2
            clip:         true
            color:        Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
            border.color: root._dropdownOpen
                          ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
                          : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Anim.mediumFast} }

            Column {
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                spacing: 0

                Item {
                    height: pill._rowH
                    width:  parent.width

                    Row {
                        id: activeRow
                        anchors.centerIn: parent
                        spacing: Math.round(6 * localScale)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.player ? MediaService.playerIcon(root.player) : "♪"
                            font.pixelSize: Math.round(11 * localScale)
                            color:          Theme.active
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.player ? MediaService.playerLabel(root.player) : "Player"
                            font.pixelSize: Math.round(11 * localScale)
                            font.weight:    Font.Medium
                            color:          Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.92)
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

                Repeater {
                    model: MediaService.filteredPlayers
                    delegate: Item {
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === MediaService.selectedIndex

                        width:  parent.width
                        height: isCurrent ? 0 : (root._dropdownOpen ? pill._rowH : 0)
                        visible: !isCurrent
                        opacity: root._dropdownOpen ? 1 : 0
                        
                        Behavior on height  { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }
                        Behavior on opacity { NumberAnimation { duration: Anim.color} }

                        Row {
                            anchors.centerIn: parent
                            spacing: Math.round(6 * localScale)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           MediaService.playerIcon(modelData)
                                font.pixelSize: Math.round(11 * localScale)
                                color:          rowH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.90) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.55)
                                Behavior on color { ColorAnimation { duration: Anim.fast} }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           MediaService.playerLabel(modelData)
                                font.pixelSize: Math.round(11 * localScale)
                                color:          rowH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.90) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.55)
                                width:          Math.min(implicitWidth, Math.round(120 * localScale))
                                elide:          Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Anim.fast} }
                            }
                        }

                        HoverHandler { id: rowH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                MediaService.selectPlayer(index)
                                root._dropdownOpen = false
                            }
                        }
                    }
                }
            }
        }
    } 

    // ── Cava bars — flush with the card bottom ────────────────────────────────
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
        border.color: Theme.border
        border.width: 1
    }
}

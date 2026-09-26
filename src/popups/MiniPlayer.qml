import QtQuick
import QtQuick.Effects
import "../theme"
import "../state"
import "../services"
import "../components"
import "../"

// MiniPlayer — compact music controls popup extruding from the center notch.
// Replicates the ScreenRecOptionsPopup pattern: clip-masked downward reveal.

Item {
    id: root
    property real localScale: 1.0

    width: parent.width
    height: contentCol.height + Math.round(24 * localScale)

    property bool isOpen: Popups.miniPlayerOpen && !ShellState.screenRecord
    opacity: isOpen ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }

    property real expandOffset: opacity === 1 ? 0 : -Math.round(20 * localScale)
    Behavior on expandOffset { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }

    onIsOpenChanged: {
        CavaService.miniPlayerVisible = isOpen
    }

    // Dismiss when dashboard opens
    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (Popups.dashboardOpen) Popups.miniPlayerOpen = false
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Math.round(8 * localScale)
        anchors.rightMargin: Math.round(8 * localScale)
        transform: Translate { y: root.expandOffset }

        // Swallow clicks so they don't bleed to notch toggle, and use them to raise the app
        MouseArea { 
            anchors.fill: parent 
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                MediaService.raisePlayer();
                Popups.miniPlayerOpen = false;
            }
        }
        HoverHandler {
            onHoveredChanged: {
                // Keep alive while hovered
            }
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
                    source:   MediaService.artUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth:   true
                }
            }

            MultiEffect {
                source:       artSource
                anchors.fill: parent
                visible:      MediaService.artUrl !== ""
                opacity:      MediaService.artUrl !== "" ? 1 : 0
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

        // Border for the card
        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: "transparent"
            border.color: Theme.border
            border.width: 1
        }

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Math.round(8 * localScale)
            spacing: Math.round(10 * localScale)

            // ── Title + Artist ──────────────────────────────────────────────
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Math.round(20 * localScale)
                spacing: Math.round(2 * localScale)

                Item {
                    width: parent.width
                    height: Math.round(20 * localScale)
                    clip: true

                    TextMetrics {
                        id: miniTitleMetrics
                        font: miniTitleText.font
                        text: MediaService.title
                    }

                    Text {
                        id: miniTitleText
                        text: MediaService.title
                        font.pixelSize: Math.round(14 * localScale)
                        font.weight: Font.Bold
                        color: Theme.text
                        anchors.horizontalCenter: miniTitleMetrics.width <= parent.width ? parent.horizontalCenter : undefined
                        NumberAnimation on x {
                            id: miniMarquee
                            running: miniTitleMetrics.width > miniTitleText.parent.width && MediaService.isPlaying
                            from: miniTitleText.parent.width
                            to: -miniTitleMetrics.width
                            duration: Math.max(0, (miniTitleMetrics.width + miniTitleText.parent.width) * 25)
                            loops: Animation.Infinite
                        }
                        onTextChanged: miniMarquee.restart()
                    }
                }

                Text {
                    width: parent.width
                    text: MediaService.artist
                    visible: MediaService.artist !== ""
                    font.pixelSize: Math.round(11 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.70)
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // ── Controls row ─────────────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(20 * localScale)

                Repeater {
                    model: [{ key: "prev" }, { key: "play" }, { key: "next" }]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isPlay: modelData.key === "play"
                        readonly property string icon: {
                            if (modelData.key === "prev") return "󰒫"
                            if (modelData.key === "next") return "󰒬"
                            return MediaService.isPlaying ? "󰏤" : "󰐊"
                        }
                        width: Math.round(36 * localScale)
                        height: Math.round(36 * localScale)
                        radius: height / 2
                        color: isPlay
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25)
                            : ctrlHov.hovered
                                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                                : "transparent"
                        border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.fast } }

                        Text {
                            anchors.centerIn: parent
                            text: parent.icon
                            font.pixelSize: isPlay ? Math.round(18 * localScale) : Math.round(14 * localScale)
                            color: isPlay ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.85)
                        }

                        HoverHandler { id: ctrlHov; cursorShape: Qt.PointingHandCursor }
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

            // ── Source picker pill ────────────────────────────────────────
            Item {
                width: parent.width
                height: srcRow.height
                visible: MediaService.filteredPlayers.length > 1

                Row {
                    id: srcRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(6 * localScale)
                    height: Math.round(22 * localScale)

                    Repeater {
                        model: MediaService.filteredPlayers
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isCurrent: index === MediaService.selectedIndex
                            width: srcLabel.implicitWidth + Math.round(16 * localScale)
                            height: Math.round(22 * localScale)
                            radius: height / 2
                            color: isCurrent
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25)
                                : srcPillHov.hovered
                                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                            border.color: isCurrent
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                                : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Anim.fast } }

                            Text {
                                id: srcLabel
                                anchors.centerIn: parent
                                text: MediaService.playerLabel(modelData)
                                font.pixelSize: Math.round(10 * localScale)
                                font.weight: Font.Medium
                                color: isCurrent ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.75)
                            }

                            HoverHandler { id: srcPillHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: MediaService.selectPlayer(index)
                            }
                        }
                    }
                }
            }

            // ── Progress bar ─────────────────────────────────────────────
            Item {
                width: parent.width - Math.round(24 * localScale)
                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.round(4 * localScale)
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            MediaService.seek(mouse.x / width)
                        }
                    }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: Math.max(parent.radius * 2, parent.width * MediaService.progress)
                        radius: parent.radius
                        color: Theme.active
                    }
                }
            }
        }
    }
}

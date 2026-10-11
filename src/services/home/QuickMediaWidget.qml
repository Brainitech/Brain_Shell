/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import Quickshell
import Quickshell.Io
import "../../"
import "../../components"
import "../"

Item {
    id: mediaWidgetRoot

    property real localScale: 1.0
    property bool compact: false
    property bool showArt: true

    implicitWidth: mediaWidgetRoot.compact ? Math.round(240 * mediaWidgetRoot.localScale) : Math.round(210 * mediaWidgetRoot.localScale)
    implicitHeight: mediaWidgetRoot.compact ? Math.round(56 * mediaWidgetRoot.localScale) : Math.round(144 * mediaWidgetRoot.localScale)

    // ── Compact Mode Layout ───────────────────────────────────────────────────
    Item {
        id: compactView
        anchors.fill: parent
        visible: mediaWidgetRoot.compact

        // Left album art thumbnail
        Rectangle {
            id: compactArtThumb
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: Math.round(40 * mediaWidgetRoot.localScale)
            height: width
            radius: Math.round(Theme.cornerRadius * 0.4 * mediaWidgetRoot.localScale)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
            clip: true
            visible: mediaWidgetRoot.showArt

            Image {
                anchors.fill: parent
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: MediaService.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: MediaService.artUrl === ""
                text: "♪"
                font.pixelSize: Math.round(16 * mediaWidgetRoot.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                onClicked: MediaService.raisePlayer()
            }
        }

        // Right controls
        Row {
            id: compactCtrlRow
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: Math.round(4 * mediaWidgetRoot.localScale)

            Repeater {
                model: [ { key: "prev" }, { key: "play" }, { key: "next" } ]
                delegate: Rectangle {
                    id: compactBtn
                    required property var modelData
                    required property int index
                    readonly property bool isPlay: modelData.key === "play"
                    readonly property string dispIcon: {
                        if (modelData.key === "prev") return "󰒫"
                        if (modelData.key === "next") return "󰒬"
                        return !MediaService.isPlaying ? "󰐊" : "󰏤"
                    }
                    width: isPlay ? Math.round(30 * mediaWidgetRoot.localScale) : Math.round(26 * mediaWidgetRoot.localScale)
                    height: width
                    radius: height / 2
                    color: isPlay
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
                           : cBtnHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: compactBtn.dispIcon
                        font.pixelSize: compactBtn.isPlay ? Math.round(14 * mediaWidgetRoot.localScale) : Math.round(12 * mediaWidgetRoot.localScale)
                        color: compactBtn.isPlay ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.75)
                    }

                    HoverHandler { id: cBtnHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (compactBtn.modelData.key === "play") MediaService.toggle()
                            else if (compactBtn.modelData.key === "prev") MediaService.prev()
                            else if (compactBtn.modelData.key === "next") MediaService.next()
                        }
                    }
                }
            }
        }

        // Center track details & progress bar
        Column {
            anchors {
                left: mediaWidgetRoot.showArt ? compactArtThumb.right : parent.left
                leftMargin: mediaWidgetRoot.showArt ? Math.round(8 * mediaWidgetRoot.localScale) : 0
                right: compactCtrlRow.left
                rightMargin: Math.round(8 * mediaWidgetRoot.localScale)
                verticalCenter: parent.verticalCenter
            }
            spacing: Math.round(3 * mediaWidgetRoot.localScale)

            Item {
                id: compactTitleBox
                width: parent.width
                height: Math.round(18 * mediaWidgetRoot.localScale)
                clip: true

                TextMetrics {
                    id: compactTitleMetrics
                    font: compactTitleText.font
                    text: MediaService.title
                }

                Text {
                    id: compactTitleText
                    text: MediaService.title
                    font.pixelSize: Math.round(12 * mediaWidgetRoot.localScale)
                    font.weight: Font.DemiBold
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    x: compactTitleMetrics.width <= compactTitleBox.width ? 0 : 0

                    NumberAnimation on x {
                        id: compactMarquee
                        running: compactTitleMetrics.width > compactTitleBox.width && MediaService.isPlaying
                        from: compactTitleBox.width
                        to: -compactTitleMetrics.width
                        duration: Math.max(1, (compactTitleMetrics.width + compactTitleBox.width) * 25)
                        loops: Animation.Infinite
                        onRunningChanged: {
                            if (!running) compactTitleText.x = 0
                        }
                    }
                    onTextChanged: compactMarquee.restart()
                }
            }

            Text {
                width: parent.width
                text: MediaService.artist
                visible: MediaService.artist !== ""
                font.pixelSize: Math.round(10 * mediaWidgetRoot.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            // Compact progress seek track
            Item {
                width: parent.width
                height: Math.round(4 * mediaWidgetRoot.localScale)

                Rectangle {
                    id: compactProgressTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(parent.radius * 2, parent.width * MediaService.progress)
                        radius: parent.radius
                        color: Theme.active
                        Behavior on width {
                            NumberAnimation {
                                duration: Anim.normal
                                easing.type: Anim.outCubic
                                easing.overshoot: Anim.globalOvershoot
                                easing.amplitude: Anim.globalAmplitude
                                easing.period: Anim.globalPeriod
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (MediaService.length > 0)
                                MediaService.seek(mouse.x / width)
                        }
                    }
                }
            }
        }
    }

    // ── Expanded Mode Layout ──────────────────────────────────────────────────
    Item {
        id: expandedView
        anchors.fill: parent
        visible: !mediaWidgetRoot.compact

        // Track title & artist header
        Column {
            id: expandedHeaderCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: Math.round(4 * mediaWidgetRoot.localScale)
            }
            spacing: Math.round(4 * mediaWidgetRoot.localScale)
            clip: true

            Item {
                id: expandedTitleBox
                width: parent.width
                height: Math.round(26 * mediaWidgetRoot.localScale)
                clip: true

                TextMetrics {
                    id: expandedTitleMetrics
                    font: expandedTitleText.font
                    text: MediaService.title
                }

                Text {
                    id: expandedTitleText
                    text: MediaService.title
                    font.pixelSize: Math.round(16 * mediaWidgetRoot.localScale)
                    font.weight: Font.Bold
                    color: Theme.text
                    anchors.horizontalCenter: expandedTitleMetrics.width <= expandedTitleBox.width ? parent.horizontalCenter : undefined

                    NumberAnimation on x {
                        id: expandedMarquee
                        running: expandedTitleMetrics.width > expandedTitleBox.width && MediaService.isPlaying
                        from: expandedTitleBox.width
                        to: -expandedTitleMetrics.width
                        duration: Math.max(1, (expandedTitleMetrics.width + expandedTitleBox.width) * 20)
                        loops: Animation.Infinite
                        onRunningChanged: {
                            if (!running && expandedTitleMetrics.width > expandedTitleBox.width) {
                                expandedTitleText.x = 0
                            }
                        }
                    }
                    onTextChanged: expandedMarquee.restart()
                }
            }

            Text {
                width: parent.width
                text: MediaService.artist
                visible: MediaService.artist !== ""
                font.pixelSize: Math.round(12 * mediaWidgetRoot.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                maximumLineCount: 1
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Controls row (prev, play/pause, next)
        Row {
            id: expandedCtrlRow
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: expandedProgressCol.top
                bottomMargin: Math.round(10 * mediaWidgetRoot.localScale)
            }
            spacing: Math.round(22 * mediaWidgetRoot.localScale)

            Repeater {
                model: [ { key: "prev" }, { key: "play" }, { key: "next" } ]
                delegate: Rectangle {
                    id: expandedBtn
                    required property var modelData
                    required property int index
                    readonly property bool isPlay: modelData.key === "play"
                    readonly property string dispIcon: {
                        if (modelData.key === "prev") return "󰒫"
                        if (modelData.key === "next") return "󰒬"
                        return !MediaService.isPlaying ? "󰐊" : "󰏤"
                    }
                    width: isPlay ? Math.round(38 * mediaWidgetRoot.localScale) : Math.round(34 * mediaWidgetRoot.localScale)
                    height: width
                    radius: height / 2
                    color: isPlay
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                           : eBtnHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                    border.color: isPlay ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.32) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: expandedBtn.dispIcon
                        font.pixelSize: expandedBtn.isPlay ? Math.round(18 * mediaWidgetRoot.localScale) : Math.round(14 * mediaWidgetRoot.localScale)
                        color: expandedBtn.isPlay ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.75)
                    }

                    HoverHandler { id: eBtnHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (expandedBtn.modelData.key === "play") MediaService.toggle()
                            else if (expandedBtn.modelData.key === "prev") MediaService.prev()
                            else if (expandedBtn.modelData.key === "next") MediaService.next()
                        }
                    }
                }
            }
        }

        // Progress bar + timestamps column
        Column {
            id: expandedProgressCol
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: Math.round(4 * mediaWidgetRoot.localScale)
            }
            spacing: Math.round(4 * mediaWidgetRoot.localScale)

            // Seek track
            Item {
                width: parent.width
                height: Math.round(6 * mediaWidgetRoot.localScale)

                Rectangle {
                    id: expandedProgressTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.20)

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(parent.radius * 2, parent.width * MediaService.progress)
                        radius: parent.radius
                        color: Theme.active
                        Behavior on width {
                            NumberAnimation {
                                duration: Anim.normal
                                easing.type: Anim.outCubic
                                easing.overshoot: Anim.globalOvershoot
                                easing.amplitude: Anim.globalAmplitude
                                easing.period: Anim.globalPeriod
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (MediaService.length > 0)
                                MediaService.seek(mouse.x / width)
                        }
                    }
                }
            }

            // Timestamps
            Item {
                width: parent.width
                height: Math.round(12 * mediaWidgetRoot.localScale)

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: MediaService._fmt(MediaService._pos)
                    font.pixelSize: Math.round(9 * mediaWidgetRoot.localScale)
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                }

                Text {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: MediaService._fmt(MediaService.length)
                    font.pixelSize: Math.round(9 * mediaWidgetRoot.localScale)
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                }
            }
        }
    }
}

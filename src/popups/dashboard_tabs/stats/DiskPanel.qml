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
import QtQuick.Controls.Basic
import "../../../"
import "../../"
import "../../../components"

Item {
    id: root

    property real localScale: 1.0
    required property var service

    readonly property bool _scrollable: Math.ceil(flickable.contentHeight) > Math.floor(flickable.height) + 1

    // ── Header ──────────────────────────────────────────────────────────────
    Item {
        id: headerRow
        anchors {
            top:   parent.top
            left:  parent.left
            right: parent.right
        }
        implicitHeight: headerLabel.implicitHeight
        height:         implicitHeight

        Text {
            id: headerLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Disks"
            font.pixelSize: Math.round(11 * localScale)
            font.weight:    Font.Medium
            color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
        }

        Text {
            visible:        root.service.disks.length > 0
            anchors {
                right:          parent.right
                rightMargin:    Math.round(8 * localScale)
                verticalCenter: parent.verticalCenter
            }
            text:           root.service.disks.length
            font.pixelSize: Math.round(9 * localScale)
            font.weight:    Font.Medium
            color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
        }
    }

    // ── Standalone scrollbar — lives outside the Flickable ──────────────────
    ScrollBar {
        id: vScroll
        visible:     root._scrollable
        orientation: Qt.Vertical
        anchors {
            top:         flickable.top
            bottom:      flickable.bottom
            right:       parent.right
            rightMargin: Math.round(3 * localScale)
        }
        // Manually bind to Flickable
        size:     flickable.visibleArea.heightRatio
        position: flickable.visibleArea.yPosition
        onPositionChanged: if (active) flickable.contentY = position * flickable.contentHeight

        contentItem: Rectangle {
            implicitWidth:  Math.round(2 * localScale)
            implicitHeight: Math.round(20 * localScale)
            radius:         width / 2
            color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
            opacity:        vScroll.active ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: Anim.slower; easing.type: Anim.inOutQuad}
            }
        }

        background: Rectangle {
            implicitWidth: Math.round(2 * localScale)
            radius:        width / 2
            color:         Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        }
    }

    // ── Flickable — stops before the scrollbar lane ──────────────────────────
    Flickable {
        id: flickable
        anchors {
            top:          headerRow.bottom
            topMargin:    Math.round(6 * localScale)
            left:         parent.left
            right:        parent.right
            rightMargin:  root._scrollable ? Math.round(12 * localScale) : Math.round(8 * localScale)
            bottom:       parent.bottom
            bottomMargin: Math.round(4 * localScale)
            leftMargin:   Math.round(8 * localScale)
        }
        clip:           true
        contentHeight:  diskColumn.implicitHeight
        contentWidth:   width
        boundsBehavior: Flickable.StopAtBounds

        flickDeceleration:    2500
        maximumFlickVelocity: 1200

        Column {
            id: diskColumn
            width:   flickable.width
            spacing: Math.round(10 * localScale)

            Repeater {
                model: root.service.disks

                delegate: DiskBar {
                    localScale: root.localScale
                    width:    parent.width
                    source:   modelData.source
                    mount:    modelData.mount
                    usedPct:  modelData.usedPct
                    usedStr:  modelData.usedStr
                    totalStr: modelData.totalStr
                }
            }
        }
    }
}

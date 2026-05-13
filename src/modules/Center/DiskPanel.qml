import QtQuick
import QtQuick.Controls.Basic
import "../../"
import "../../components"

Item {
    id: root

    required property var service

    readonly property bool _scrollable: flickable.contentHeight > flickable.height

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
            font.pixelSize: 11
            font.weight:    Font.Medium
            color:          Qt.rgba(1, 1, 1, 0.4)
        }

        Text {
            visible:        root.service.disks.length > 0
            anchors {
                right:          parent.right
                rightMargin:    8
                verticalCenter: parent.verticalCenter
            }
            text:           root.service.disks.length
            font.pixelSize: 9
            font.weight:    Font.Medium
            color:          Qt.rgba(1, 1, 1, 0.25)
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
            rightMargin: 3
        }
        // Manually bind to Flickable
        size:     flickable.visibleArea.heightRatio
        position: flickable.visibleArea.yPosition
        onPositionChanged: if (active) flickable.contentY = position * flickable.contentHeight

        contentItem: Rectangle {
            implicitWidth:  2
            implicitHeight: 20
            radius:         width / 2
            color:          Qt.rgba(1, 1, 1, 0.5)
            opacity:        vScroll.active ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }
        }

        background: Rectangle {
            implicitWidth: 2
            radius:        width / 2
            color:         Qt.rgba(1, 1, 1, 0.08)
        }
    }

    // ── Flickable — stops before the scrollbar lane ──────────────────────────
    Flickable {
        id: flickable
        anchors {
            top:          headerRow.bottom
            topMargin:    6
            left:         parent.left
            right:        parent.right
            rightMargin:  root._scrollable ? 12 : 8
            bottom:       parent.bottom
            bottomMargin: 4
            leftMargin:   8
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
            spacing: 10

            Repeater {
                model: root.service.disks

                delegate: DiskBar {
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

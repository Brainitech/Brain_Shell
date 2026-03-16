import QtQuick
import "../"
import "../components"

// Dashboard Home tab — layout only.
// All logic lives in the individual card files in this directory.
//
//  ┌──────────────┬───────────────────────────┬──────────────┐
//  │ ProfileCard  │  ClockCard                │ BrightCard   │
//  ├──────────────┤                           ├──────────────┤
//  │ CalendarCard │  PlayerCard               │ QuickSetting │
//  └──────────────┴───────────────────────────┴──────────────┘

Item {
    id: root

    readonly property int colW:    210
    readonly property int gap:       8
    readonly property int profileH: 160
    readonly property int clockH:   220
    readonly property int brightH:  100

    // ── Left column ───────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: root.colW

        ProfileCard {
            id: profileCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH
        }

        CalendarCard {
            anchors {
                left: parent.left; right: parent.right
                top: profileCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }

    // ── Right column ──────────────────────────────────────────────────────────
    Item {
        id: rightCol
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.colW

        BrightnessCard {
            id: brightCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.brightH
        }

        QuickSettings {
            anchors {
                left: parent.left; right: parent.right
                top: brightCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }

    // ── Center column ─────────────────────────────────────────────────────────
    Item {
        id: centerCol
        anchors {
            left: leftCol.right;   leftMargin:  root.gap
            right: rightCol.left;  rightMargin: root.gap
            top: parent.top;       bottom: parent.bottom
        }

        ClockCard {
            id: clockCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.clockH
        }

        PlayerCard {
            anchors {
                left:   parent.left
                right:  parent.right
                top:    clockCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }
}

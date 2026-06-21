import QtQuick
import QtQuick.Controls
import Quickshell
import "../"

Item {
    id: root

    property real localScale: 1.0

    // ── State ─────────────────────────────────────────────────────────────────
    property bool loading:  true
    property int  selIndex: -1
    property string query:  ""

    readonly property var apps: DesktopEntries.applications.values

    readonly property var filtered: {
        if (loading) return []

        var q = query.toLowerCase().trim()
        if (q === "") return apps
        return apps.filter(function(a) {
            return a.name.toLowerCase().indexOf(q) !== -1
        })
    }

    onVisibleChanged: {
        if (!visible) return
        root.loading   = true
        searchInput.text = ""
        root.query     = ""
        root.selIndex  = -1
        delayTimer.restart()
        focusTimer.restart()
    }

    Timer {
        id: delayTimer
        interval: 150
        onTriggered: {
            root.loading  = false
            root.selIndex = root.filtered.length > 0 ? 0 : -1
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: searchInput.forceActiveFocus()
    }

    // ── Launch ────────────────────────────────────────────────────────────────
    function launch(entry) {
        entry.execute()
        Popups.dashboardOpen = false
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: Math.round(8 * localScale)

        // App list container
        Item {
            width:  parent.width
            height: parent.height - searchBar.height - parent.spacing

            // Loading state
            Column {
                anchors.centerIn: parent
                spacing: Math.round(12 * localScale)
                visible: root.loading

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰣪"; font.pixelSize: Math.round(32 * localScale)
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3)

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: Anim.megaSlow
                        running: root.loading
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           "Initializing..."
                    color:          Qt.rgba(1,1,1,0.25)
                    font.pixelSize: Math.round(13 * localScale)
                }
            }

            // Empty / no results state
            Column {
                anchors.centerIn: parent
                spacing: Math.round(10 * localScale)
                visible: !root.loading && root.filtered.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           root.query !== "" ? "󰩄" : "󱗃"
                    font.pixelSize: Math.round(28 * localScale)
                    color:          Qt.rgba(1,1,1,0.18)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           root.query !== "" ? "No results" : "No apps found"
                    color:          Qt.rgba(1,1,1,0.25)
                    font.pixelSize: Math.round(13 * localScale)
                }
            }

            // App list
            ListView {
                id: appList
                anchors.fill: parent
                visible: !root.loading && root.filtered.length > 0

                // Reverted directly back to the pure array (instant updates, no glitching)
                model: root.filtered

                clip:    true
                spacing: Math.round(3 * localScale)
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth:  Math.round(3 * localScale)
                        implicitHeight: Math.round(40 * localScale)
                        radius:         width / 2
                        color:          Qt.rgba(1, 1, 1, 0.22)
                    }
                    background: Item {}
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width:  appList.width - Math.round(8 * localScale)
                    height: Math.round(46 * localScale)
                    radius: Math.round(9 * localScale)

                    readonly property bool isSel: root.selIndex === index

                    color: isSel
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                           : rowH.hovered ? Qt.rgba(1,1,1,0.06) : "transparent"
                    border.color: isSel
                                  ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                                  : rowH.hovered ? Qt.rgba(1,1,1,0.08) : "transparent"
                    border.width: 1

                    Behavior on color        { ColorAnimation { duration: Anim.fast} }
                    Behavior on border.color { ColorAnimation { duration: Anim.fast} }

                    Row {
                        anchors {
                            left:   parent.left;  leftMargin:  Math.round(12 * localScale)
                            right:  parent.right; rightMargin: Math.round(12 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Math.round(12 * localScale)

                        // App icon
                        Item {
                            width: Math.round(28 * localScale); height: Math.round(28 * localScale)
                            anchors.verticalCenter: parent.verticalCenter

                            Loader {
                                id: iconLoader
                                anchors.fill: parent
                                asynchronous: true
                                active: true

                                sourceComponent: Image {
                                    source: {
                                        var s = modelData.icon;
                                        // Tier 1 Fallback: Ask Quickshell for the generic Linux application icon
                                        if (!s || s.trim() === "") return "image://icon/application-x-executable";
                                        if (s.startsWith("/")) return "file://" + s;
                                        return "image://icon/" + s;
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: Math.round(28 * localScale)
                                    sourceSize.height: Math.round(28 * localScale)

                                    onStatusChanged: {
                                        if (status === Image.Error || status === Image.Null) {
                                            Qt.callLater(function() { iconLoader.active = false; });
                                        }
                                    }
                                }
                            }

                            // Tier 2 Fallback: Nerd Font Icon
                            Rectangle {
                                anchors.fill: parent
                                radius: Math.round(7 * localScale)
                                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                                visible: !iconLoader.active || (iconLoader.item && iconLoader.item.status !== Image.Ready)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀻" // Generic Nerd Font App Grid Icon
                                    font.pixelSize: Math.round(16 * localScale)
                                    color: Theme.active
                                }
                            }
                        }

                        // App name
                        Text {
                            width: parent.width - Math.round(28 * localScale) - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            text:           modelData.name
                            font.pixelSize: Math.round(13 * localScale)
                            color:          isSel ? Theme.active : Theme.text
                            elide:          Text.ElideRight
                            Behavior on color { ColorAnimation { duration: Anim.fast} }
                        }
                    }

                    HoverHandler { id: rowH; cursorShape: Qt.PointingHandCursor }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered:    root.selIndex = index
                        onClicked:    root.launch(modelData)
                    }
                }
            }
        }

        // Search bar
        Rectangle {
            id: searchBar
            width: parent.width; height: Math.round(44 * localScale); radius: Math.round(12 * localScale)
            color: Qt.rgba(1,1,1,0.06)
            border.color: searchInput.activeFocus
                          ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.50)
                          : Qt.rgba(1,1,1,0.12)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Anim.color} }

            Row {
                anchors { fill: parent; leftMargin: Math.round(14 * localScale); rightMargin: Math.round(14 * localScale) }
                spacing: Math.round(10 * localScale)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"; font.pixelSize: Math.round(16 * localScale)
                    color: searchInput.activeFocus
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
                           : Qt.rgba(1,1,1,0.35)
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                }

                Item {
                    width: parent.width - Math.round(26 * localScale) - parent.spacing
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:    "Search apps…"
                        color:   Qt.rgba(1,1,1,0.22)
                        font.pixelSize: Math.round(13 * localScale)
                        visible: searchInput.text === ""
                    }

                    TextInput {
                        id: searchInput
                        anchors { fill: parent; topMargin: Math.round(2 * localScale); bottomMargin: Math.round(2 * localScale) }
                        verticalAlignment: TextInput.AlignVCenter
                        color:          Theme.text
                        font.pixelSize: Math.round(13 * localScale)
                        selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                        clip: true

                        // Debouncer removed: Instant 1:1 keystroke filtering
                        onTextChanged: {
                            root.query = text
                            root.selIndex = root.filtered.length > 0 ? 0 : -1
                            if (root.filtered.length > 0)
                                appList.positionViewAtIndex(0, ListView.Beginning)
                        }

                        Keys.onUpPressed: {
                            if (root.selIndex > 0) {
                                root.selIndex--
                                appList.positionViewAtIndex(root.selIndex, ListView.Contain)
                            }
                        }

                        Keys.onDownPressed: {
                            if (root.selIndex < root.filtered.length - 1) {
                                root.selIndex++
                                appList.positionViewAtIndex(root.selIndex, ListView.Contain)
                            }
                        }

                        Keys.onReturnPressed: {
                            if (root.selIndex >= 0 && root.selIndex < root.filtered.length)
                                root.launch(root.filtered[root.selIndex])
                        }

                        Keys.onEscapePressed: {
                            if (text !== "") {
                                text = ""
                            } else {
                                Popups.dashboardOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}

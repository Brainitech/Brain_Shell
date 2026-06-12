import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"
import "../theme"
import "../components"
import "."

// AppLauncher — scrollable app list + bottom search bar.
// Lives inside Dashboard.qml on the "launcher" page.
// Uses native Quickshell DesktopEntries via AppSearch (no Python process).

Item {
    id: root

    // ── State ─────────────────────────────────────────────────────────────────
    property var  apps:     []
    property bool loading:  true
    property int  selIndex: -1
    property string query:  ""

    readonly property var filtered: {
        var q = query.toLowerCase().trim()
        if (q === "") return apps
        return AppSearch.fuzzyQuery(q)
    }

    // ── Preload apps at startup (not just when launcher becomes visible) ─────
    Component.onCompleted: _loadApps()

    // Track when DesktopEntries discovers new apps — refresh the list
    Connections {
        target: AppSearch
        function onListChanged() {
            if (root.visible) _loadApps()
        }
    }

    // ── Reload when becoming visible (catches any missed updates) ────────────
    onVisibleChanged: {
        if (!visible) return
        root.query     = ""
        root.selIndex  = -1
        searchInput.text = ""
        _loadApps()
        focusTimer.restart()
    }

    function _loadApps() {
        root.loading = (root.apps.length === 0)
        var list = []
        try {
            list = AppSearch.getAllApps()
            console.log("[AppLauncher] loaded", list.length, "apps")
        } catch(e) {
            console.warn("[AppLauncher] AppSearch failed:", e)
        }
        root.apps = list || []
        root.loading = false
        root.selIndex = root.apps.length > 0 ? 0 : -1
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: {
            searchInput.forceActiveFocus()
            FocusGrabManager.requestGrab(searchInput)
        }
    }

    // ── Launch ────────────────────────────────────────────────────────────────
    Process {
        id: _fallbackLaunchProc
        command: []
        running: false
    }

    function launch(app) {
        if (app && app.execute) {
            app.execute()
            UsageTracker.recordLaunch(app.id)
        } else if (app && app.execString) {
            // Fallback for compatibility — use declarative Process
            _fallbackLaunchProc.command = ["bash", "-c", "setsid " + app.execString + " &>/dev/null &"]
            _fallbackLaunchProc.running = false
            _fallbackLaunchProc.running = true
            UsageTracker.recordLaunch(app.id || app.name)
        }
        Popups.dashboardOpen = false
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 8

        // App list
        Item {
            width:  parent.width
            height: parent.height - searchBar.height - parent.spacing

            // Loading state
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: root.loading

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰣪"; font.pixelSize: 32
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           "Loading apps…"
                    color:          Qt.rgba(1,1,1,0.25)
                    font.pixelSize: 13
                }
            }

            // Empty / no results state
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: !root.loading && root.filtered.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           root.query !== "" ? "󰩄" : "󱗃"
                    font.pixelSize: 28
                    color:          Qt.rgba(1,1,1,0.18)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           root.query !== "" ? "No results" : "No apps found"
                    color:          Qt.rgba(1,1,1,0.25)
                    font.pixelSize: 13
                }
            }

            // App list
            ListView {
                id: appList
                anchors.fill: parent
                visible: !root.loading && root.filtered.length > 0
                model:   root.filtered
                clip:    true
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 2000

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth:  3
                        implicitHeight: 40
                        radius:         1.5
                        color:          Qt.rgba(1, 1, 1, 0.22)
                    }
                    background: Item {}
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width:  appList.width - 8
                    height: 46
                    radius: 9

                    readonly property bool isSel: root.selIndex === index

                    color: isSel
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                           : rowH.hovered ? Qt.rgba(1,1,1,0.06) : "transparent"
                    border.color: isSel
                                  ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                                  : rowH.hovered ? Qt.rgba(1,1,1,0.08) : "transparent"
                    border.width: 1

                    Behavior on color        { ColorAnimation { duration: Anim.standardSmall } }
                    Behavior on border.color { ColorAnimation { duration: Anim.standardSmall } }

                    Row {
                        anchors {
                            left:   parent.left;  leftMargin:  12
                            right:  parent.right; rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 12

                        // App icon
                        Item {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: ico
                                anchors.fill: parent
                                source: {
                                    var s = modelData.icon
                                    if (!s || s === "")    return ""
                                    if (s.startsWith("/")) return "file://" + s
                                    return "image://icon/" + s
                                }
                                fillMode:          Image.PreserveAspectFit
                                smooth:            true
                                sourceSize.width:  28
                                sourceSize.height: 28
                            }

                            // Letter fallback
                            Rectangle {
                                anchors.fill: parent
                                radius:       7
                                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                                visible: ico.status !== Image.Ready || modelData.icon === ""
                                Text {
                                    anchors.centerIn: parent
                                    text:           modelData.name.charAt(0).toUpperCase()
                                    font.pixelSize: 13; font.bold: true
                                    color:          Theme.active
                                }
                            }
                        }

                        // App name
                        Text {
                            width: parent.width - 28 - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            text:           modelData.name
                            font.pixelSize: 13
                            color:          isSel ? Theme.active : Theme.text
                            elide:          Text.ElideRight
                            Behavior on color { ColorAnimation { duration: Anim.standardSmall } }
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
        StyledRect {
            id: searchBar
            width: parent.width; height: 44
            variant: "surface"
            border.color: searchInput.activeFocus
                          ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.50)
                          : Qt.rgba(1,1,1,0.12)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Anim.standardSmall } }

            Row {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"; font.pixelSize: 16
                    color: searchInput.activeFocus
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
                           : Qt.rgba(1,1,1,0.35)
                    Behavior on color { ColorAnimation { duration: Anim.standardSmall } }
                }

                Item {
                    width: parent.width - 26 - parent.spacing
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:    "Search apps…"
                        color:   Qt.rgba(1,1,1,0.22)
                        font.pixelSize: 13
                        visible: searchInput.text === ""
                    }

                    TextInput {
                        id: searchInput
                        anchors { fill: parent; topMargin: 2; bottomMargin: 2 }
                        verticalAlignment: TextInput.AlignVCenter
                        color:          Theme.text
                        font.pixelSize: 13
                        selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                        clip: true

                        onTextChanged: {
                            root.query    = text
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

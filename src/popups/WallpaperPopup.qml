import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Layouts
import "../shapes"
import "../components"
import "../services"
import "../"

PanelWindow {
    id: root

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay

    property bool wantsFocus: false
    WlrLayershell.keyboardFocus: wantsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: focusGrabTimer
        interval: 15
        onTriggered: {
            if (windowVisible && Popups.wallpaperOpen) root.wantsFocus = true
        }
    }
    
    readonly property int panelWidth:  Math.round(980 * root.localScale)
    readonly property int panelHeight: Math.round(420 * root.localScale)
    readonly property int fw:          Math.round(Theme.notchRadius * root.localScale)
    readonly property int fh:          Math.round(Theme.notchRadius * root.localScale)

    property bool windowVisible: false
    visible: windowVisible

    // ── Self-hover tracking ───────────────────────────────────────────────────
    property bool selfHovered: true
    
    property bool allowHover: false

    // ── Hover close timer ─────────────────────────────────────────────────────
    // Fires when both the trigger region and the popup itself are no longer hovered.
    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (root.allowHover && !Popups.wallpaperTriggerHovered && !root.selfHovered)
                Popups.wallpaperOpen = false
        }
    }

    onSelfHoveredChanged: {
        if (root.allowHover) {
            if (!selfHovered && !Popups.wallpaperTriggerHovered) hoverCloseTimer.restart()
            else                                                  hoverCloseTimer.stop()
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        onTriggered: searchInput.forceActiveFocus()
    }

    Connections {
        target: Popups
        function onWallpaperTriggerHoveredChanged() {
            if (Popups.wallpaperTriggerHovered) {
                if (root.allowHover) {
                    hoverCloseTimer.stop()
                    if (!Popups.wallpaperOpen) {
                        closeTimer.stop()
                        root.windowVisible           = true
                        Popups.wallpaperOpen         = true
                        WallpaperService.refresh()
                        WallpaperService.previewWall = ""
                        content.schemePopupOpen      = false
                        content.folderMode           = false
                        content.appliedScheme        = WallpaperService.scheme
                        searchInput.text             = ""
                        focusGrabTimer.restart()
                        searchInput.forceActiveFocus()
                        focusTimer.restart()
                    }
                }
            } else {
                if (root.allowHover && !root.selfHovered) hoverCloseTimer.restart()
            }
        }

        function onWallpaperOpenChanged() {
            if (Popups.wallpaperOpen) {
                closeTimer.stop()
                hoverCloseTimer.stop()
                root.windowVisible           = true
                WallpaperService.refresh()
                WallpaperService.previewWall = ""
                content.schemePopupOpen      = false
                content.folderMode           = false
                content.appliedScheme        = WallpaperService.scheme
                searchInput.text             = ""
                focusGrabTimer.restart()
                searchInput.forceActiveFocus()
                focusTimer.restart()
            } else {
                root.wantsFocus = false
                focusGrabTimer.stop()
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Anim.transition + 20
        onTriggered: { if (!Popups.wallpaperOpen) root.windowVisible = false }
    }

    Connections {
        target: WallpaperService
        function onWallpapersChanged() {
            if (!Popups.wallpaperOpen) return
            var walls = WallpaperService.wallpapers
            if (!walls || walls.length === 0) return
            var target = WallpaperService.currentWall
            for (var i = 0; i < walls.length; i++) {
                if (walls[i] === target) {
                    WallpaperService.previewWall = target
                    wallGrid.targetCenterIndex   = i
                    centerLockTimer.restart()
                    wallGrid.forceLayout()
                    wallGrid.positionViewAtIndex(i, ListView.Center)
                    return
                }
            }
        }
    }

    Timer {
        id: centerLockTimer
        interval: Anim.transition
        onTriggered: wallGrid.targetCenterIndex = -1
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    Popups.wallpaperOpen = false
    }

    Item {
        id: sizer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     Math.round(Theme.borderWidth * root.localScale)
        clip: true

        width:  Popups.wallpaperOpen ? root.panelWidth + 2 * root.fw : Math.round(Theme.cNotchMinWidth * root.localScale) + 2 * root.fw
        height: Popups.wallpaperOpen ? root.panelHeight : 0

        Behavior on width  { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
        Behavior on height { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        MouseArea {
            anchors.fill: parent
            onClicked:    {}
        }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "bottom"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * root.localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            id: content
            focus: true
            anchors {
                fill:         parent
                topMargin:    Math.round(16 * root.localScale)
                bottomMargin: root.fh + Math.round(8 * root.localScale)
                leftMargin:   root.fw + Math.round(16 * root.localScale)
                rightMargin:  root.fw + Math.round(16 * root.localScale)
            }

            property string searchQuery:     ""
            property bool   schemePopupOpen: false
            property bool   folderMode:      false
            property string appliedScheme:   WallpaperService.scheme

            readonly property var filteredWallpapers: {
                var q = searchQuery.toLowerCase()
                if (q === "") return WallpaperService.wallpapers
                return WallpaperService.wallpapers.filter(function(p) {
                    return p.split("/").pop().toLowerCase().indexOf(q) !== -1
                })
            }

            readonly property bool applyActive:
                WallpaperService.previewWall !== "" ||
                (WallpaperService.currentWall !== "" &&
                 WallpaperService.scheme !== content.appliedScheme)

            opacity: Popups.wallpaperOpen ? 1 : 0
            transform: Translate {
                y: Popups.wallpaperOpen ? 0 : Math.round(40 * root.localScale)
                Behavior on y { NumberAnimation { duration: Anim.transition; easing.type: Anim.outExpo} }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.wallpaperOpen ? Anim.transition * 0.5 : Anim.transition * 0.15
                }
            }

            ListView {
                id: wallGrid
                property int targetCenterIndex: -1
                onWidthChanged: {
                    if (Popups.wallpaperOpen && targetCenterIndex !== -1 && count > targetCenterIndex)
                        positionViewAtIndex(targetCenterIndex, ListView.Center)
                }

                anchors.top:          parent.top
                anchors.left:         parent.left
                anchors.right:        parent.right
                anchors.bottom:       divider.top
                anchors.bottomMargin: Math.round(8 * localScale)

                orientation:    ListView.Horizontal
                spacing:        Math.round(14 * localScale)
                clip:           true
                boundsBehavior: Flickable.StopAtBounds
                interactive:    false
                ScrollBar.horizontal: ScrollBar { 
                    policy: ScrollBar.AsNeeded
                    height: Math.round(6 * localScale) 
                }
                model: content.filteredWallpapers

                Text {
                    anchors.centerIn: parent
                    visible:          wallGrid.count === 0
                    text:             "No wallpapers found in " + WallpaperService.wallpaperDir
                    color:            Qt.rgba(1,1,1,0.25)
                    font.pixelSize:   Math.round(13 * localScale)
                }

                delegate: Item {
                    id:                      cardDelegate
                    required property string modelData
                    required property int    index
                    property bool isPreview: WallpaperService.previewWall === modelData
                    property bool isCurrent: WallpaperService.currentWall === modelData
                    readonly property int labelH: Math.round(30 * localScale)

                    width:  isPreview ? Math.round(130 * 1.2 * localScale) : Math.round(130 * localScale)
                    height: isPreview ? wallGrid.height : wallGrid.height - Math.round(14 * localScale)
                    Behavior on width { NumberAnimation { duration: Anim.color; easing.type: Anim.inOutCubic} }

                    Item {
                        id:           cardContent
                        anchors.fill: parent
                        visible:      false

                        Image {
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            anchors.top:   parent.top
                            height:        parent.height - cardDelegate.labelH
                            source:        modelData.indexOf("://") !== -1 ? modelData : "file://" + modelData
                            fillMode:      Image.PreserveAspectCrop
                            asynchronous:  true
                            cache:         true
                        }

                        Rectangle {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            anchors.bottom: parent.bottom
                            height: cardDelegate.labelH
                            color: isPreview
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                                : Qt.rgba(1,1,1,0.09)

                            Text {
                                anchors.centerIn: parent
                                width:               parent.width - Math.round(10 * localScale)
                                text:                modelData.split("/").pop().replace(/\.[^/.]+$/, "")
                                color:               isPreview ? Theme.active : Qt.rgba(1,1,1,0.65)
                                font.pixelSize:      Math.round(10 * localScale)
                                font.weight:         isPreview ? Font.Medium : Font.Normal
                                elide:               Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        id: cardMask
                        anchors.fill: parent
                        radius: Math.round(10 * localScale)
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        source: cardContent
                        anchors.fill: parent
                        maskEnabled: true
                        maskSource: cardMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(10 * localScale)
                        color: "transparent"
                        border.width: isPreview ? Math.round(2 * localScale) : Math.round(1 * localScale)
                        border.color: isPreview ? Theme.active
                            : isCurrent ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                            : Qt.rgba(1,1,1,0.15)
                        Behavior on border.color { ColorAnimation { duration: Anim.color} }
                        Behavior on border.width { NumberAnimation  { duration: Anim.color} }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            content.schemePopupOpen = false
                            if (cardDelegate.isPreview) {
                                content.appliedScheme = WallpaperService.scheme
                                WallpaperService.apply(cardDelegate.modelData)
                                Popups.wallpaperOpen = false
                            } else {
                                WallpaperService.previewWall = cardDelegate.modelData
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.top:          parent.top
                anchors.left:         parent.left
                anchors.right:        parent.right
                anchors.bottom:       divider.top
                anchors.bottomMargin: Math.round(8 * root.localScale)
                z:                    wallGrid.z + 1
                acceptedButtons:      Qt.NoButton
                onWheel: function(wheel) {
                    wallGrid.contentX = Math.max(0,
                        Math.min(wallGrid.contentWidth - wallGrid.width,
                            wallGrid.contentX - wheel.angleDelta.y))
                }
            }

            Rectangle {
                id: divider
                anchors.bottom:       utilBar.top
                anchors.bottomMargin: Math.round(8 * root.localScale)
                anchors.left:         parent.left
                anchors.right:        parent.right
                height: 1
                color: Qt.rgba(1,1,1,0.07)
            }

            Item {
                id: utilBar
                anchors.bottom:       parent.bottom
                anchors.bottomMargin: Math.round((Theme.notchRadius - 12) * root.localScale)
                anchors.left:         parent.left
                anchors.right:        parent.right
                height: Math.round(32 * localScale)

                Row {
                    anchors.verticalCenter:   parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(8 * localScale)

                    Rectangle {
                        id:                 folderBtn
                        width:              Math.round(32 * root.localScale)
                        height:             Math.round(32 * root.localScale)
                        radius:             Math.round(8 * root.localScale)
                        color: folderBtnMA.containsMouse 
                               ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                               : (content.folderMode ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : Qt.rgba(1,1,1,0.04))
                        border.color: (content.folderMode || folderBtnMA.containsMouse)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                            : Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: Anim.fast} }
                        Behavior on border.color { ColorAnimation { duration: Anim.fast} }
                        Text {
                            anchors.centerIn: parent; text: "󰉋"; font.pixelSize: Math.round(15 * root.localScale)
                            color: (content.folderMode || folderBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.5)
                            Behavior on color { ColorAnimation { duration: Anim.fast} }
                        }
                        MouseArea {
                            id:                 folderBtnMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                content.schemePopupOpen = false
                                content.folderMode = !content.folderMode
                                if (content.folderMode) {
                                    dirInput.text = WallpaperService.wallpaperDir
                                    dirInput.forceActiveFocus()
                                    dirInput.selectAll()
                                } else {
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id:                 filterBox
                        width:              Math.round(300 * root.localScale)
                        height:             Math.round(32 * root.localScale)
                        radius:             Math.round(8 * root.localScale)
                        color: filterBoxMA.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.06)
                        border.color: (searchInput.activeFocus || dirInput.activeFocus)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                            : (filterBoxMA.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.fast} }
                        Behavior on border.color { ColorAnimation { duration: Anim.fast} }
                        
                        MouseArea {
                            id:                 filterBoxMA
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        Item {
                            anchors.fill:        parent
                            anchors.leftMargin:  Math.round(10 * root.localScale)
                            anchors.rightMargin: Math.round(10 * root.localScale)
                            visible: !content.folderMode

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search wallpapers…"
                                color: (searchInput.activeFocus || filterBoxMA.containsMouse) ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7) : Qt.rgba(1,1,1,0.28)
                                font.pixelSize: Math.round(12 * root.localScale); visible: searchInput.text === ""
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill:      parent
                                verticalAlignment: TextInput.AlignVCenter
                                color:             Theme.text
                                font.pixelSize:    Math.round(12 * root.localScale)
                                selectionColor:    Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                                clip:              true
                                onTextChanged:     content.searchQuery = text

                                Keys.onReturnPressed: {
                                    var walls = content.filteredWallpapers
                                    if (!walls || walls.length === 0) return
                                    var previewInSearch = false
                                    for (var i = 0; i < walls.length; i++) {
                                        if (walls[i] === WallpaperService.previewWall) { previewInSearch = true; break }
                                    }
                                    var target = previewInSearch ? WallpaperService.previewWall : walls[0]
                                    content.appliedScheme = WallpaperService.scheme
                                    WallpaperService.apply(target)
                                    Popups.wallpaperOpen = false
                                }
                                Keys.onLeftPressed: {
                                    var walls = content.filteredWallpapers
                                    if (!walls || walls.length === 0) return
                                    var cur = WallpaperService.previewWall; var idx = -1
                                    for (var i = 0; i < walls.length; i++) { if (walls[i] === cur) { idx = i; break } }
                                    idx = (idx <= 0) ? walls.length - 1 : idx - 1
                                    WallpaperService.previewWall = walls[idx]
                                    wallGrid.positionViewAtIndex(idx, ListView.Center)
                                }
                                Keys.onRightPressed: {
                                    var walls = content.filteredWallpapers
                                    if (!walls || walls.length === 0) return
                                    var cur = WallpaperService.previewWall; var idx = -1
                                    for (var i = 0; i < walls.length; i++) { if (walls[i] === cur) { idx = i; break } }
                                    idx = (idx < 0 || idx >= walls.length - 1) ? 0 : idx + 1
                                    WallpaperService.previewWall = walls[idx]
                                    wallGrid.positionViewAtIndex(idx, ListView.Center)
                                }
                                Keys.onEscapePressed: {
                                    if (searchInput.text !== "") {
                                        var target = WallpaperService.previewWall !== ""
                                            ? WallpaperService.previewWall : WallpaperService.currentWall
                                        var walls = WallpaperService.wallpapers; var idx = 0
                                        for (var i = 0; i < walls.length; i++) { if (walls[i] === target) { idx = i; break } }
                                        searchInput.text = ""
                                        wallGrid.forceLayout()
                                        wallGrid.positionViewAtIndex(idx, ListView.Center)
                                    } else { Popups.closeAll() }
                                }
                            }
                        }

                        Item {
                            anchors.fill:        parent
                            anchors.leftMargin:  Math.round(10 * root.localScale)
                            anchors.rightMargin: Math.round(10 * root.localScale)
                            visible:             content.folderMode

                            Text {
                                id: pathLbl
                                anchors.left:           parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text:                   "Path: "
                                color:                  (dirInput.activeFocus || filterBoxMA.containsMouse) ? Theme.active : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
                                font.pixelSize:         Math.round(11 * root.localScale)
                            }

                            TextInput {
                                id:                dirInput
                                anchors.left:      pathLbl.right
                                anchors.right:     parent.right
                                anchors.top:       parent.top
                                anchors.bottom:    parent.bottom
                                verticalAlignment: TextInput.AlignVCenter
                                color:             Theme.text
                                font.pixelSize:    Math.round(12 * root.localScale)
                                font.family:       "JetBrains Mono"
                                selectionColor:    Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                                clip:              true
                                Keys.onReturnPressed: {
                                    WallpaperService.wallpaperDir = dirInput.text
                                    WallpaperService.refresh()
                                    content.folderMode = false
                                    searchInput.forceActiveFocus()
                                }
                                Keys.onEscapePressed: {
                                    content.folderMode = false
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id:                 schemeBtn
                        width:              schemeBtnRow.implicitWidth + 20
                        height:             Math.round(32 * root.localScale)
                        radius:             Math.round(8 * root.localScale)
                        color: schemeBtnMA.containsMouse 
                               ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                               : (content.schemePopupOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : Qt.rgba(1,1,1,0.04))
                        border.color: (content.schemePopupOpen || schemeBtnMA.containsMouse)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                            : Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: Anim.fast} }
                        Behavior on border.color { ColorAnimation { duration: Anim.fast} }

                        Row {
                            id:                 schemeBtnRow; anchors.centerIn: parent; spacing: Math.round(7 * localScale)
                            Text {
                                text:                   "󰏘"
                                font.pixelSize:         Math.round(14 * localScale)
                                color:                  (content.schemePopupOpen || schemeBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.55)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color       { ColorAnimation { duration: Anim.fast} }
                            }
                            Text {
                                text:                   WallpaperService.scheme
                                font.pixelSize:         Math.round(12 * localScale)
                                color:                  (content.schemePopupOpen || schemeBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.7)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color       { ColorAnimation { duration: Anim.fast} }
                            }
                            Text {
                                text:                   content.schemePopupOpen ? "▴" : "▾"
                                font.pixelSize:         Math.round(8 * localScale)
                                color:                  (content.schemePopupOpen || schemeBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.35)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id:           schemeBtnMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    content.schemePopupOpen = !content.schemePopupOpen
                        }
                    }
                }

                Rectangle {
                    id: applyBtn
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    property bool active:   content.applyActive
                    width:                  active ? Math.round(90 * localScale) : 0
                    height:                 Math.round(32 * localScale)
                    radius:                 Math.round(8 * localScale)
                    opacity:                active ? 1 : 0
                    clip:                   true
                    color: applyBtnMA.containsMouse
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                    border.color: applyBtnMA.containsMouse
                        ? Theme.active
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                    border.width: 1
                    Behavior on width        { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic} }
                    Behavior on opacity      { NumberAnimation { duration: Anim.mediumFast} }
                    Behavior on color        { ColorAnimation { duration: Anim.fast} }
                    Behavior on border.color { ColorAnimation { duration: Anim.fast} }
                    Text {
                        anchors.centerIn: parent
                        text:             WallpaperService.applying ? "…" : "Apply"
                        font.pixelSize:   Math.round(12 * localScale)
                        font.weight:      Font.Medium 
                        color:            Theme.active
                        opacity:          applyBtn.active ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Anim.fast} }
                    }
                    MouseArea {
                        id:           applyBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        enabled:      applyBtn.active && !WallpaperService.applying
                        onClicked: {
                            var target = WallpaperService.previewWall !== ""
                                ? WallpaperService.previewWall : WallpaperService.currentWall
                            content.appliedScheme = WallpaperService.scheme
                            WallpaperService.apply(target)
                            Popups.wallpaperOpen = false
                        }
                    }
                }
            }

            TapHandler {
                enabled:  content.schemePopupOpen
                onTapped: content.schemePopupOpen = false
            }
        }

        Rectangle {
            id: schemeDropdown
            z:       100
            visible: content.schemePopupOpen
            clip:    false

            width:  schemeDropdownCol.implicitWidth + Math.round(32 * root.localScale)
            height: schemeDropdownCol.implicitHeight + Math.round(16 * root.localScale)
            radius: Math.round(Theme.cornerRadius * root.localScale)

            color:        Theme.background
            border.color: Theme.active
            border.width: 1

            opacity:            content.schemePopupOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Anim.color} }

            onVisibleChanged: {
                if (visible) {
                    var pos = schemeBtn.mapToItem(sizer, 0, 0)
                    x = Math.min(pos.x, sizer.width - width - Math.round(4 * root.localScale))
                    y = pos.y - height - Math.round(6 * root.localScale)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked:    {}
            }

            ColumnLayout {
                id:               schemeDropdownCol
                anchors.centerIn: parent
                spacing:          Math.round(4 * root.localScale)

                Repeater {
                    model: WallpaperService.schemes
                    delegate: Rectangle {
                        id: schemeItem
                        required property string modelData
                        property bool sel: WallpaperService.scheme === modelData

                        Layout.fillWidth: true
                        // Pad minimumWidth to ensure space between text and rectangle edges
                        Layout.minimumWidth: schemeItemText.implicitWidth + Math.round(40 * root.localScale) 
                        Layout.preferredHeight: Math.round(32 * root.localScale)
                        
                        radius: Math.round(8 * root.localScale)
                        color: schemeItemMA.containsMouse 
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                            : (sel ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : "transparent")
                        
                        border.color: (sel || schemeItemMA.containsMouse) 
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                            : "transparent"
                        border.width: 1

                        Behavior on color        { ColorAnimation { duration: Anim.fast} }
                        Behavior on border.color { ColorAnimation { duration: Anim.fast} }

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Math.round(12 * root.localScale)
                            spacing: Math.round(10 * root.localScale)
                            
                            Text {
                                text:                   sel ? "●" : "○"
                                font.pixelSize:         Math.round(10 * root.localScale)
                                color:                  (sel || schemeItemMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.3)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id:                     schemeItemText
                                text:                   modelData
                                font.pixelSize:         Math.round(13 * root.localScale)
                                color:                  (sel || schemeItemMA.containsMouse) ? Theme.text : Qt.rgba(1,1,1,0.65)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id:           schemeItemMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                WallpaperService.scheme = modelData
                                content.schemePopupOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}

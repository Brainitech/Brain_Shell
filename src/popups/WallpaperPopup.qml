import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Layouts
import "../shapes"
import "../components"
import "../services"
import "../theme"
import "../"

PanelWindow {
    id: root

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (windowVisible && Popups.wallpaperOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int panelWidth:  980
    readonly property int panelHeight: 420
    readonly property int fw:          Theme.notchRadius
    readonly property int fh:          Theme.notchRadius

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
        interval: 150
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
                searchInput.forceActiveFocus()
                focusTimer.restart()
            } else {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Anim.standardNormal + 20
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
        // Force grid refresh when thumbnails finish generating
        function onThumbnailsReady() {
            if (!Popups.wallpaperOpen) return
            wallGrid.forceLayout()
        }
    }

    Timer {
        id: centerLockTimer
        interval: Anim.standardNormal
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
        anchors.bottomMargin:     Theme.borderWidth
        clip: true

        width:  Popups.wallpaperOpen ? root.panelWidth + 2 * root.fw : Theme.cNotchMinWidth + 2 * root.fw
        height: Popups.wallpaperOpen ? root.panelHeight : 0

        Behavior on width  { NumberAnimation { duration: Anim.standardNormal; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }
        Behavior on height { NumberAnimation { duration: Anim.standardNormal; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }

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
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            id: content
            focus: true
            anchors {
                fill:         parent
                topMargin:    16
                bottomMargin: root.fh + 8
                leftMargin:   root.fw + 16
                rightMargin:  root.fw + 16
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
                y: Popups.wallpaperOpen ? 0 : 40
                Behavior on y { NumberAnimation { duration: Anim.standardLarge; easing.type: Anim.easing("decelerate").type; easing.bezierCurve: Anim.easing("decelerate").bezierCurve } }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.wallpaperOpen ? Math.round(Anim.standardNormal * 0.5) : Math.round(Anim.standardNormal * 0.15)
                    easing.type: Anim.easing("standard").type
                    easing.bezierCurve: Anim.easing("standard").bezierCurve
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
                anchors.bottomMargin: 8

                orientation:    ListView.Horizontal
                spacing:        14
                clip:           true
                boundsBehavior: Flickable.StopAtBounds
                interactive:    false
                ScrollBar.horizontal: ScrollBar { 
                    policy: ScrollBar.AsNeeded
                    height: 6 
                }
                model: content.filteredWallpapers

                Text {
                    anchors.centerIn: parent
                    visible:          wallGrid.count === 0
                    text:             "No wallpapers found in " + WallpaperService.wallpaperDir
                    color:            Qt.rgba(1,1,1,0.25)
                    font.pixelSize:   13
                }

                delegate: Item {
                    id:                      cardDelegate
                    required property string modelData
                    required property int    index
                    property bool isPreview: WallpaperService.previewWall === modelData
                    property bool isCurrent: WallpaperService.currentWall === modelData
                    readonly property int labelH: 30

                    width:  isPreview ? (130 * 1.2) : 130
                    height: isPreview ? wallGrid.height : wallGrid.height - 14
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.InOutCubic } }

                    // ── Viewport-aware lazy loading (ported from NothingLess) ──
                    // Only decode images when the card is visible or near-visible.
                    // Cards outside the viewport show a placeholder, saving RAM/CPU.
                    readonly property bool isInViewport: {
                        var vpLeft = wallGrid.contentX
                        var vpRight = vpLeft + wallGrid.width
                        var cardLeft = x
                        var cardRight = x + width
                        var buffer = width * 2  // preload 2 cards ahead/behind
                        return cardRight + buffer >= vpLeft && cardLeft - buffer <= vpRight
                    }

                    Item {
                        id:           cardContent
                        anchors.fill: parent
                        visible:      false

                        // ── Thumbnail image (static, always a thumbnail) ──────
                        Image {
                            id: thumbImg
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            anchors.top:   parent.top
                            height:        parent.height - cardDelegate.labelH
                            // Only load when in/near viewport — saves decode cost
                            source: {
                                if (!cardDelegate.isInViewport) return ""
                                var thumb = WallpaperService.thumbnailFor(modelData)
                                if (thumb && thumb !== "") return "file://" + thumb
                                // No fallback to original — thumbnails only
                                return ""
                            }
                            sourceSize.width: 200
                            sourceSize.height: 200
                            fillMode:      Image.PreserveAspectCrop
                            asynchronous:  true
                            cache:         false  // don't waste Qt image cache on thumbnails

                            // Placeholder while loading / out of viewport
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(1,1,1,0.03)
                                visible: thumbImg.source == "" || thumbImg.status !== Image.Ready
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!cardDelegate.isInViewport) return ""
                                        var ext = modelData.toLowerCase().split('.').pop()
                                        if (['mp4','webm','mkv','mov','avi','gif'].includes(ext)) return "🎬"
                                        return "🖼"
                                    }
                                    font.pixelSize: 22
                                }
                            }
                        }

                        // ── Live preview for video / animated GIF ───────────
                        // Only instantiate when card is selected AND in viewport.
                        // Saves GPU memory by not creating 50+ video decoders.
                        Loader {
                            id: livePreviewLoader
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            anchors.top:   parent.top
                            height:        parent.height - cardDelegate.labelH
                            clip: true

                            readonly property string ext: cardDelegate.modelData.toLowerCase().split('.').pop()
                            readonly property bool isGif: ext === 'gif'
                            readonly property bool isVid: ['mp4','webm','mkv','mov','avi'].includes(ext)

                            // Only instantiate when selected AND in viewport
                            active: cardDelegate.isPreview && cardDelegate.isInViewport && (isGif || isVid)
                            sourceComponent: isGif ? gifPreviewComp
                                            : (isVid ? videoPreviewComp : null)
                        }

                        // GIFs → AnimatedImage (QtMultimedia Video does not render gifs)
                        Component {
                            id: gifPreviewComp
                            AnimatedImage {
                                source:   "file://" + cardDelegate.modelData
                                fillMode: Image.PreserveAspectCrop
                                cache:    false
                                playing:  true
                                speed:    1.0
                                asynchronous: true
                            }
                        }

                        // Real videos → lightweight preview
                        Component {
                            id: videoPreviewComp
                            Video {
                                id: previewVideo
                                anchors.fill: parent
                                source:   "file://" + cardDelegate.modelData
                                loops:    MediaPlayer.Infinite
                                autoPlay: true
                                muted:    true
                                fillMode: VideoOutput.PreserveAspectCrop
                            }
                        }

                        // Video/GIF indicator badge
                        Rectangle {
                            anchors.right:  parent.right
                            anchors.top:    parent.top
                            anchors.margins: 4
                            width:  20; height: 14; radius: 3
                            color:  "#cc000000"
                            visible: {
                                var ext = modelData.toLowerCase().split('.').pop()
                                return ['mp4','webm','mkv','mov','avi','gif'].includes(ext)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                color: "white"
                                font.pixelSize: 7
                            }
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
                                width:               parent.width - 10
                                text:                modelData.split("/").pop().replace(/\.[^/.]+$/, "")
                                color:               isPreview ? Theme.active : Qt.rgba(1,1,1,0.65)
                                font.pixelSize:      10
                                font.weight:         isPreview ? Font.Medium : Font.Normal
                                elide:               Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        id: cardMask
                        anchors.fill: parent
                        radius: 10
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
                        radius: 10
                        color: "transparent"
                        border.width: isPreview ? 2 : 1
                        border.color: isPreview ? Theme.active
                            : isCurrent ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                            : Qt.rgba(1,1,1,0.15)
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on border.width { NumberAnimation  { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            content.schemePopupOpen = false
                            // Preview highlight
                            WallpaperService.previewWall = cardDelegate.modelData
                            // Apply immediately with smooth transition
                            content.appliedScheme = WallpaperService.scheme
                            WallpaperService.apply(cardDelegate.modelData)
                            Popups.wallpaperOpen = false
                        }
                    }
                }
            }

            MouseArea {
                anchors.top:          parent.top
                anchors.left:         parent.left
                anchors.right:        parent.right
                anchors.bottom:       divider.top
                anchors.bottomMargin: 8
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
                anchors.bottomMargin: 8
                anchors.left:         parent.left
                anchors.right:        parent.right
                height: 1
                color: Qt.rgba(1,1,1,0.07)
            }

            Item {
                id: utilBar
                anchors.bottom:       parent.bottom
                anchors.bottomMargin: -20
                anchors.left:         parent.left
                anchors.right:        parent.right
                height: 32

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        id:                 folderBtn
                        width:              32
                        height:             32
                        radius:             8
                        color: folderBtnMA.containsMouse 
                               ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                               : (content.folderMode ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : Qt.rgba(1,1,1,0.04))
                        border.color: (content.folderMode || folderBtnMA.containsMouse)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                            : Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent; text: "󰉋"; font.pixelSize: 15
                            color: (content.folderMode || folderBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.5)
                            Behavior on color { ColorAnimation { duration: 100 } }
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
                        width:              300
                        height:             32
                        radius:             8
                        color: filterBoxMA.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.06)
                        border.color: (searchInput.activeFocus || dirInput.activeFocus)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                            : (filterBoxMA.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                        
                        MouseArea {
                            id:                 filterBoxMA
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        Item {
                            anchors.fill:        parent
                            anchors.leftMargin:  10
                            anchors.rightMargin: 10
                            visible: !content.folderMode

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search wallpapers…"
                                color: (searchInput.activeFocus || filterBoxMA.containsMouse) ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7) : Qt.rgba(1,1,1,0.28)
                                font.pixelSize: 12; visible: searchInput.text === ""
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill:      parent
                                verticalAlignment: TextInput.AlignVCenter
                                color:             Theme.text
                                font.pixelSize:    12
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
                            anchors.leftMargin:  10
                            anchors.rightMargin: 10
                            visible:             content.folderMode

                            Text {
                                id: pathLbl
                                anchors.left:           parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text:                   "Path: "
                                color:                  (dirInput.activeFocus || filterBoxMA.containsMouse) ? Theme.active : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
                                font.pixelSize:         11
                            }

                            TextInput {
                                id:                dirInput
                                anchors.left:      pathLbl.right
                                anchors.right:     parent.right
                                anchors.top:       parent.top
                                anchors.bottom:    parent.bottom
                                verticalAlignment: TextInput.AlignVCenter
                                color:             Theme.text
                                font.pixelSize:    12
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
                        height:             32
                        radius:             8
                        color: schemeBtnMA.containsMouse 
                               ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                               : (content.schemePopupOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : Qt.rgba(1,1,1,0.04))
                        border.color: (content.schemePopupOpen || schemeBtnMA.containsMouse)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                            : Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            id:                 schemeBtnRow; anchors.centerIn: parent; spacing: 7
                            Text {
                                text:                   "󰏘"
                                font.pixelSize:         14
                                color:                  (content.schemePopupOpen || schemeBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.55)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color       { ColorAnimation { duration: 100 } }
                            }
                            Text {
                                text:                   WallpaperService.scheme
                                font.pixelSize:         12
                                color:                  (content.schemePopupOpen || schemeBtnMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.7)
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color       { ColorAnimation { duration: 100 } }
                            }
                            Text {
                                text:                   content.schemePopupOpen ? "▴" : "▾"
                                font.pixelSize:         8
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
                    width:                  active ? 90 : 0
                    height:                 32
                    radius:                 8
                    opacity:                active ? 1 : 0
                    clip:                   true
                    color: applyBtnMA.containsMouse
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                    border.color: applyBtnMA.containsMouse
                        ? Theme.active
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                    border.width: 1
                    Behavior on width        { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity      { NumberAnimation { duration: 160 } }
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text:             WallpaperService.applying ? "…" : "Apply"
                        font.pixelSize:   12
                        font.weight:      Font.Medium 
                        color:            Theme.active
                        opacity:          applyBtn.active ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
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

            width:  schemeDropdownCol.implicitWidth + 32
            height: schemeDropdownCol.implicitHeight + 16
            radius: Theme.cornerRadius

            color:        Theme.background
            border.color: Theme.active
            border.width: 1

            opacity:            content.schemePopupOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }

            onVisibleChanged: {
                if (visible) {
                    var pos = schemeBtn.mapToItem(sizer, 0, 0)
                    x = Math.min(pos.x, sizer.width - width - 4)
                    y = pos.y - height - 6
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked:    {}
            }

            ColumnLayout {
                id:               schemeDropdownCol
                anchors.centerIn: parent
                spacing:          4

                Repeater {
                    model: WallpaperService.schemes
                    delegate: Rectangle {
                        id: schemeItem
                        required property string modelData
                        property bool sel: WallpaperService.scheme === modelData

                        Layout.fillWidth: true
                        // Pad minimumWidth to ensure space between text and rectangle edges
                        Layout.minimumWidth: schemeItemText.implicitWidth + 40 
                        Layout.preferredHeight: 32
                        
                        radius: 8
                        color: schemeItemMA.containsMouse 
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) 
                            : (sel ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : "transparent")
                        
                        border.color: (sel || schemeItemMA.containsMouse) 
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                            : "transparent"
                        border.width: 1

                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            spacing: 10
                            
                            Text {
                                text:                   sel ? "●" : "○"
                                font.pixelSize:         10
                                color:                  (sel || schemeItemMA.containsMouse) ? Theme.active : Qt.rgba(1,1,1,0.3)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id:                     schemeItemText
                                text:                   modelData
                                font.pixelSize:         13
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

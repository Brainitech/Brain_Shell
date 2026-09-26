import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../components"
import "../../"

RowLayout {
    id: root
    property real localScale: 1.0

    ListView {
        id: trayRow
        Layout.alignment: Qt.AlignVCenter
        orientation: ListView.Horizontal
        spacing: Math.round(4 * localScale)
        
        property bool isOpen: false
        property int activeMenuIndex: -1
        
        onIsOpenChanged: {
            if (!isOpen) {
                activeMenuIndex = -1
            }
        }
        
        onActiveMenuIndexChanged: {
            if (activeMenuIndex !== -1) {
                Popups.closeAll()
            }
        }

        Connections {
            target: Popups
            function onAnyOpenChanged() {
                if (Popups.anyOpen) {
                    trayRow.activeMenuIndex = -1
                }
            }
        }

        visible: opacity > 0
        opacity: isOpen ? 1 : 0
        Layout.maximumWidth: Math.round(60 * localScale)
        property real calculatedWidth: trayRow.count > 0 ? (trayRow.count * Math.round(26 * localScale)) + ((trayRow.count - 1) * spacing) : 0
        Layout.preferredWidth: isOpen ? Math.min(calculatedWidth, Layout.maximumWidth) : 0
        Layout.preferredHeight: Math.round(26 * localScale)
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic} }

        model: SystemTray.items
        delegate: Item {
            id: delegateRoot
            width: Math.round(26 * localScale)
            height: Math.round(26 * localScale)
            
            property bool isMenuOpen: trayRow.activeMenuIndex === index

            Rectangle {
                anchors.fill: parent
                radius: Math.round(6 * localScale)
                color: trayHover.hovered || isMenuOpen ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
            }
            
            Image {
                width: Math.round(16 * localScale)
                height: Math.round(16 * localScale)
                anchors.centerIn: parent
                source: modelData.icon
                smooth: true
            }

            QsMenuOpener {
                id: menuOpener
                menu: modelData.menu
            }
            
            HyprlandFocusGrab {
                windows: [customMenu, delegateRoot.QsWindow.window]
                active: isMenuOpen
                onCleared: {
                    if (trayRow.activeMenuIndex === index) {
                        trayRow.activeMenuIndex = -1
                    }
                }
            }

            PopupWindow {
                id: customMenu
                visible: bgRect.opacity > 0
                color: "transparent"
                
                anchor.item: delegateRoot
                anchor.edges: Edges.Bottom
                
                implicitWidth: Math.max(Math.round(150 * localScale), (menuList.contentItem ? menuList.contentItem.childrenRect.width : 0) + Math.round(16 * localScale))
                implicitHeight: menuList.contentHeight + Math.round(16 * localScale)
                
                Rectangle {
                    id: bgRect
                    anchors.fill: parent
                    color: Theme.background
                    radius: Theme.cornerRadius
                    
                    opacity: isMenuOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
                    
                    // Flatten top corners to merge seamlessly with the top bar notch style
                    Rectangle {
                        width: parent.width
                        height: Theme.cornerRadius
                        color: Theme.background
                        anchors.top: parent.top
                    }
                    
                    ListView {
                        id: menuList
                        anchors.fill: parent
                        anchors.margins: Math.round(8 * localScale)
                        model: menuOpener.children
                        clip: true
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: modelData.isSeparator ? Math.round(8 * localScale) : Math.round(30 * localScale)
                            color: itemHover.hovered && !modelData.isSeparator ? Theme.active : "transparent"
                            radius: Math.round(4 * localScale)
                            
                            Rectangle {
                                visible: modelData.isSeparator
                                width: parent.width - Math.round(16 * localScale)
                                height: Math.round(1 * localScale)
                                color: Theme.border
                                anchors.centerIn: parent
                            }

                            Text {
                                visible: !modelData.isSeparator
                                text: modelData.text || ""
                                color: Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Math.round(8 * localScale)
                            }
                            
                            HoverHandler {
                                id: itemHover
                                enabled: !modelData.isSeparator
                                cursorShape: Qt.PointingHandCursor
                            }
                            
                            TapHandler {
                                enabled: !modelData.isSeparator
                                onTapped: {
                                    modelData.triggered()
                                    trayRow.activeMenuIndex = -1
                                }
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: trayHover
                cursorShape: Qt.PointingHandCursor
            }

            Process {
                id: focusProc
                command: ["sh", "-c", "sleep 0.15 && hyprctl dispatch focusurgentorlast"]
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (eventPoint, button) => {
                    if (button === Qt.LeftButton) {
                        modelData.activate()
                        trayRow.activeMenuIndex = -1
                        focusProc.running = false
                        focusProc.running = true
                    } else if (button === Qt.RightButton) {
                        if (trayRow.activeMenuIndex === index) {
                            trayRow.activeMenuIndex = -1
                        } else {
                            trayRow.activeMenuIndex = index
                        }
                    }
                }
            }
        }
    }

    // Tray Toggle Button
    IconBtn {
        localScale: root.localScale
        Layout.alignment: Qt.AlignVCenter
        text: trayRow.isOpen ? "" : ""
        onClicked: trayRow.isOpen = !trayRow.isOpen
    }
}
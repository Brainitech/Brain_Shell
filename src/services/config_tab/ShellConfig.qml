import QtQuick
import "../"
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0
    property string _page: "general"

    readonly property var _tabs: [
        { key: "general",    icon: "󰒓", label: "General"            },
        { key: "visuals",    icon: "󰏘", label: "Visuals & Behavior" },
        { key: "keybinds",   icon: "󰌌", label: "Keybinds"          },
        { key: "data",       icon: "󰋊", label: "Data & Storage"    },
        { key: "misc",       icon: "󰒓", label: "Misc"               },
    ]

    Row {
        anchors {
            fill:    parent
            margins: Math.round(8 * localScale)
        }
        spacing: Math.round(12 * localScale)

        // ── Left: tab column (30%) ────────────────────────────────────────────
        Rectangle {
            width:  Math.floor((parent.width - parent.spacing) * 0.30)
            height: parent.height
            radius: Math.round(Theme.cornerRadius * localScale)
            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
            border.color: Theme.border
            border.width: 1

            TabSwitcher {
                localScale:  root.localScale
                orientation: "vertical"
                anchors {
                    top:              parent.top
                    bottom:           parent.bottom
                    left:             parent.left
                    right:            parent.right
                    topMargin:        Math.round(8 * localScale)
                    bottomMargin:     Math.round(8 * localScale)
                    leftMargin:       Math.round(6 * localScale)
                    rightMargin:      Math.round(6 * localScale)
                }
                currentPage: root._page
                model:       root._tabs
                onPageChanged: function(key) { root._page = key }
            }
        }

        // ── Right: content area (70%) ─────────────────────────────────────────
        Rectangle {
            width:  parent.width - Math.floor((parent.width - parent.spacing) * 0.30) - parent.spacing
            height: parent.height
            radius: Math.round(Theme.cornerRadius * localScale)
            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
            border.color: Theme.border
            border.width: 1
            clip:   true

            Item {
                id: pageArea
                anchors {
                    fill: parent
                    margins: Math.round(12 * localScale)
                }

                property int pageIdx: Math.max(0, ["general", "visuals", "keybinds", "data", "misc"].indexOf(root._page))
                
                property int oldIdx: pageIdx
                property int newIdx: pageIdx
                property real progress: 1.0
                
                NumberAnimation {
                    id: progressAnim
                    target: pageArea
                    property: "progress"
                    from: 0.0
                    to: 1.0
                    duration: Anim.style === "none" ? 0 : Anim.transition
                    easing.type: Anim.outCubic
                }
                
                onPageIdxChanged: {
                    oldIdx = newIdx;
                    newIdx = pageIdx;
                    progress = 0.0;
                    if (Anim.style !== "none") progressAnim.restart();
                    else progress = 1.0;
                }

                component VerticalSlidePage: Item {
                    property int myIdx
                    property bool isCurrent: myIdx === pageArea.pageIdx
                    property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                    
                    property bool isIncoming: myIdx === pageArea.newIdx
                    property bool isOutgoing: myIdx === pageArea.oldIdx
                    property int slideDir: pageArea.newIdx > pageArea.oldIdx ? 1 : -1
                    
                    width: parent.width; height: parent.height
                    
                    y: {
                        if (Anim.style === "none") return 0;
                        if (isIncoming) {
                            return slideDir * parent.height * (1.0 - pageArea.progress);
                        } else if (isOutgoing) {
                            return -slideDir * parent.height * parallaxFactor * pageArea.progress;
                        } else {
                            return myIdx < pageArea.newIdx ? -parent.height : parent.height;
                        }
                    }
                    
                    opacity: {
                        if (Anim.style !== "parallax") return 1.0;
                        if (isIncoming) return pageArea.progress;
                        if (isOutgoing) return 1.0 - pageArea.progress;
                        return 0.0;
                    }
                    
                    visible: isCurrent || (isOutgoing && pageArea.progress < 1.0)
                }

                VerticalSlidePage {
                    myIdx: 0
                    GeneralPage { anchors.fill: parent; localScale: root.localScale }
                }
                VerticalSlidePage {
                    myIdx: 1
                    VisualsBehaviorPage { anchors.fill: parent; localScale: root.localScale }
                }
                VerticalSlidePage {
                    myIdx: 2
                    KeybindsPage { anchors.fill: parent; localScale: root.localScale }
                }
                VerticalSlidePage {
                    myIdx: 3
                    DataPage { anchors.fill: parent; localScale: root.localScale }
                }
                VerticalSlidePage {
                    myIdx: 4
                    MiscPage { anchors.fill: parent; localScale: root.localScale }
                }
            }
        }
    }
}
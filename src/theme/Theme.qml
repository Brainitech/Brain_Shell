pragma Singleton
import QtQuick
import "."

QtObject {
    // ── Bindings to Modular Singletons ────────────────────────────────────────
    // Note: property alias cannot point to other singletons, so we use direct bindings.
    
    // Colors
    property color background: Colors.background
    property color active:     Colors.active
    property color text:       Colors.text
    property color subtext:    Colors.subtext
    property color icon:       Colors.icon
    property color border:     Colors.border
    property color iconFont:   Colors.iconFont

    property color wsBackground: Colors.wsBackground
    property color wsActive:     Colors.wsActive
    property color wsOccupied:   Colors.wsOccupied
    property color wsEmpty:      Colors.wsEmpty
    property color wsOverlay:    Colors.wsOverlay
    property color wsUrgent:     Colors.wsUrgent

    // Metrics
    property bool barEnabled: Metrics.barEnabled
    
    property int borderWidth:   Metrics.borderWidth
    property int cornerRadius:  Metrics.cornerRadius
    property int notchRadius:   Metrics.notchRadius
    property int notchHeight:   Metrics.notchHeight
    property int exclusionGap:  Metrics.exclusionGap
    property int spacing:       Metrics.spacing

    property int notchPadding:           Metrics.notchPadding
    property int notchHorizontalPadding: Metrics.notchHorizontalPadding
    property int notchVerticalPadding:   Metrics.notchVerticalPadding
    property int notchSideMargin:        Metrics.notchSideMargin

    property int lNotchMinWidth: Metrics.lNotchMinWidth
    property int lNotchMaxWidth: Metrics.lNotchMaxWidth
    property int cNotchMinWidth: Metrics.cNotchMinWidth
    property int cNotchMaxWidth: Metrics.cNotchMaxWidth
    property int rNotchMinWidth: Metrics.rNotchMinWidth
    property int rNotchMaxWidth: Metrics.rNotchMaxWidth

    property int dashboardWidth:  Metrics.dashboardWidth
    property int dashboardHeight: Metrics.dashboardHeight

    property int notificationsWidth: Metrics.notificationsWidth
    property int notificationToastWidth: Metrics.notificationToastWidth
    property int networkPopupWidth:  Metrics.networkPopupWidth

    property int popupMinWidth:   Metrics.popupMinWidth
    property int popupMaxWidth:   Metrics.popupMaxWidth
    property int popupMinHeight:   Metrics.popupMinHeight
    property int popupMaxHeight:  Metrics.popupMaxHeight
    property int popupPadding:     Metrics.popupPadding

    property int wsDotSize:     Metrics.wsDotSize
    property int wsActiveWidth: Metrics.wsActiveWidth
    property int wsSpacing:     Metrics.wsSpacing
    property int wsPadding:     Metrics.wsPadding
    property int wsRadius:      Metrics.wsRadius

}

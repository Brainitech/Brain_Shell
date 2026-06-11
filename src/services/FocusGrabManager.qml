pragma Singleton
import QtQuick

/*!
    FocusGrabManager — centralized input focus coordination for popups.

    Fixes the "Input Focus Delays" known issue in Brain_Shell by ensuring
    only one popup grabs focus at a time and releases it cleanly on close.

    Usage:
        // When opening a popup
        FocusGrabManager.requestGrab(myPopupContent)

        // When closing
        FocusGrabManager.releaseGrab(myPopupContent)
*/
QtObject {
    id: root

    property var _currentGrab: null

    function requestGrab(item) {
        if (!item) return;
        if (_currentGrab && _currentGrab !== item && _currentGrab.visible) {
            // Release previous grab gracefully
            _currentGrab.focus = false;
        }
        _currentGrab = item;
        // Defer to avoid race with popup open animation
        Qt.callLater(function() {
            if (_currentGrab === item && item.visible) {
                item.forceActiveFocus();
            }
        });
    }

    function releaseGrab(item) {
        if (_currentGrab === item) {
            _currentGrab = null;
        }
        if (item) {
            item.focus = false;
        }
    }

    function releaseAll() {
        if (_currentGrab) {
            _currentGrab.focus = false;
            _currentGrab = null;
        }
    }
}

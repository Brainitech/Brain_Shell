import QtQuick
import Quickshell.Io
import "../../components"
import "../../"

Item {
    id: root
    property real localScale: 1.0

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + Math.round(40 * localScale)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: Math.round(32 * localScale)
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * localScale)

            // Animations
            SettingsGroup {
                localScale: root.localScale
                title: "Animations"
                description: "Control the speed and feel of the interface."

                SettingsButton {
                    localScale: root.localScale
                    text: "Animation Style"
                    description: "Global transition style (Slide, Parallax, None)."
                    inputType: "options"
                    options: ["slide", "parallax", "none"]
                    selectedOption: Anim.style
                    buttonText: selectedOption
                    defaultValue: "slide"
                    onOptionSelected: function(opt) { if (opt !== Anim.style) Anim.setStyle(opt) }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsButton {
                    localScale: root.localScale
                    text: "Easing Curve"
                    description: "The mathematical curve for animations."
                    inputType: "options"
                    options: ["smooth", "spring", "linear", "cinematic"]
                    selectedOption: Anim.curveStyle
                    buttonText: selectedOption
                    defaultValue: "smooth"
                    onOptionSelected: function(opt) { if (opt !== Anim.curveStyle) Anim.setCurve(opt) }
                }
                SettingsDivider { localScale: root.localScale }
                SettingsSlider {
                    localScale: root.localScale
                    text: "Animation Speed"
                    description: "Speed multiplier. Higher is faster."
                    from: 0.1; to: 2.0; stepSize: 0.1; value: Anim.speedMultiplier
                    defaultValue: 1.0
                    onValueChanged: { if (value !== Anim.speedMultiplier) Anim.setSpeedMultiplier(value) }
                    valueSuffix: "x"
                }
            }

            // Sizing & Borders
            Item {
                width: parent.width
                height: sizingGroup.height

                SettingsGroup {
                    id: sizingGroup
                    localScale: root.localScale
                    title: "Sizing & Borders"
                    SettingsSlider {
                        localScale: root.localScale
                        text: "Border Width"
                        description: "Thickness of panel borders."
                        from: 0; to: 10; stepSize: 1; value: PrefsService.borderWidth
                        defaultValue: 6
                        onValueChanged: { if (value !== PrefsService.borderWidth) { PrefsService.borderWidth = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                    SettingsDivider { localScale: root.localScale }
                    SettingsSlider {
                        localScale: root.localScale
                        text: "Container Roundness"
                        description: "Corner radius of windows and popups."
                        from: 0; to: 32; stepSize: 2; value: PrefsService.cornerRadius
                        defaultValue: 17
                        onValueChanged: { if (value !== PrefsService.cornerRadius) { PrefsService.cornerRadius = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                    SettingsDivider { localScale: root.localScale }
                    SettingsSlider {
                        localScale: root.localScale
                        text: "Notch Roundness"
                        description: "Corner radius of the top bar notches."
                        from: 0; to: 32; stepSize: 2; value: PrefsService.notchRadius
                        defaultValue: 15
                        onValueChanged: { if (value !== PrefsService.notchRadius) { PrefsService.notchRadius = value; PrefsService.saveConfig() } }
                        valueSuffix: "px"
                    }
                }
            }

            // Popup Behavior
            SettingsGroup {
                id: popupGroup
                localScale: root.localScale
                title: "Popup Behavior"
                description: "Trigger conditions and delays for popups."

                property bool dropdownExpanded: false
                Component.onCompleted: dropdownExpanded = PrefsService.globalHoverMode

                Item {
                    width: parent.width
                    height: globalHoverToggle.height

                    ToggleButton {
                        id: globalHoverToggle
                        width: parent.width
                        localScale: root.localScale
                        text: "Hover-to-Open Mode"
                        description: "Popups open on hover instead of requiring a click."
                        checked: PrefsService.globalHoverMode
                        defaultValue: false
                        onToggled: { 
                            PrefsService.globalHoverMode = checked; 
                            if (checked) popupGroup.dropdownExpanded = true;
                            PrefsService.saveConfig(); 
                        }
                    }

                    Rectangle {
                        visible: PrefsService.globalHoverMode
                        width: Math.round(28 * localScale)
                        height: Math.round(28 * localScale)
                        radius: Math.round(6 * localScale)
                        anchors {
                            right: parent.right
                            rightMargin: Math.round(84 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        color: chevronHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: popupGroup.dropdownExpanded ? "▲" : "▼"
                            color: Theme.text
                            font.pixelSize: Math.round(10 * localScale)
                        }

                        HoverHandler { id: chevronHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: popupGroup.dropdownExpanded = !popupGroup.dropdownExpanded
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: (globalHoverToggle.checked && popupGroup.dropdownExpanded) ? hoverContentCol.height : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: Anim.fast
                            easing.type: Anim.globalCurve
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(2 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        radius: Math.round(1 * localScale)
                        anchors.leftMargin: Math.round(12 * localScale)
                    }

                    Column {
                        id: hoverContentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(24 * localScale)
                        spacing: Math.round(4 * localScale)

                        SettingsDivider { localScale: root.localScale }

                        ToggleButton {
                            localScale: root.localScale
                            text: "Dashboard"
                            description: "Dashboard expands when hovering top edge."
                            checked: PrefsService.hoverDashboard
                            defaultValue: false
                            onToggled: { PrefsService.hoverDashboard = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Network"
                            checked: PrefsService.hoverNetwork
                            defaultValue: false
                            onToggled: { PrefsService.hoverNetwork = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            id: audioHoverToggle
                            localScale: root.localScale
                            text: "Audio"
                            checked: PrefsService.hoverAudio
                            Binding on checked { value: PrefsService.hoverAudio; restoreMode: Binding.RestoreBinding }
                            defaultValue: false
                            onToggled: { 
                                PrefsService.hoverAudio = checked; 
                                if (checked) PrefsService.hoverQuick = false;
                                PrefsService.saveConfig();
                                audioHoverToggle.checked = Qt.binding(function() { return PrefsService.hoverAudio });
                            }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            id: quickHoverToggle
                            localScale: root.localScale
                            text: "Quick Controls"
                            checked: PrefsService.hoverQuick
                            enabled: !PrefsService.hoverAudio
                            opacity: PrefsService.hoverAudio ? 0.4 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
                            Binding on checked { value: PrefsService.hoverQuick; restoreMode: Binding.RestoreBinding }
                            defaultValue: true
                            onToggled: { 
                                PrefsService.hoverQuick = checked; 
                                PrefsService.saveConfig();
                                quickHoverToggle.checked = Qt.binding(function() { return PrefsService.hoverQuick });
                            }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Power Menu"
                            checked: PrefsService.hoverArchMenu
                            defaultValue: false
                            onToggled: { PrefsService.hoverArchMenu = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Notifications"
                            checked: PrefsService.hoverNotifications
                            defaultValue: false
                            onToggled: { PrefsService.hoverNotifications = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Clipboard"
                            checked: PrefsService.hoverClipboard
                            defaultValue: false
                            onToggled: { PrefsService.hoverClipboard = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        ToggleButton {
                            localScale: root.localScale
                            text: "Wallpaper Picker"
                            checked: PrefsService.hoverWallpaper
                            defaultValue: false
                            onToggled: { PrefsService.hoverWallpaper = checked; PrefsService.saveConfig() }
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Open Delay"
                            description: "Time before a popup opens when hovered."
                            from: 0; to: 1000; stepSize: 50; value: PrefsService.hoverOpenDelay
                            defaultValue: 150
                            onValueChanged: { if (value !== PrefsService.hoverOpenDelay) { PrefsService.hoverOpenDelay = value; PrefsService.saveConfig() } }
                            valueSuffix: "ms"
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsSlider {
                            localScale: root.localScale
                            text: "Hover Close Delay"
                            description: "Time before a popup closes after the mouse leaves."
                            from: 0; to: 1000; stepSize: 50; value: PrefsService.hoverCloseDelay
                            defaultValue: 300
                            onValueChanged: { if (value !== PrefsService.hoverCloseDelay) { PrefsService.hoverCloseDelay = value; PrefsService.saveConfig() } }
                            valueSuffix: "ms"
                        }
                    }
                }
            }

            // Appearance
            SettingsGroup {
                id: appearanceGroup
                localScale: root.localScale
                title: "Appearance"

                property bool dropdownExpanded: false
                Component.onCompleted: dropdownExpanded = PrefsService.dynamicThemeOverride

                SettingsSlider {
                    localScale: root.localScale
                    text: "Background Opacity"
                    description: "Transparency level of main window and popup backgrounds."
                    from: 0.1; to: 1.0; stepSize: 0.05; value: PrefsService.bgOpacity
                    defaultValue: 1.0
                    onValueChanged: { if (Math.abs(value - PrefsService.bgOpacity) > 0.001) { PrefsService.bgOpacity = value; PrefsService.saveConfig() } }
                    valueSuffix: ""
                    formatValue: function(v) { return Math.round(v * 100) + "%" }
                }

                ToggleButton {
                    width: parent.width
                    localScale: root.localScale
                    text: "Background Blur"
                    description: "Enable blur effect behind transparent backgrounds."
                    checked: PrefsService.bgBlur
                    defaultValue: false
                    onToggled: { PrefsService.bgBlur = checked; PrefsService.saveConfig() }
                }
                SettingsDivider { localScale: root.localScale }

                Item {
                    width: parent.width
                    height: dynamicThemeToggle.height

                    ToggleButton {
                        id: dynamicThemeToggle
                        width: parent.width
                        localScale: root.localScale
                        text: "Dynamic Theme Override"
                        description: "Bypass wallpaper-derived colors in favor of a static theme."
                        checked: PrefsService.dynamicThemeOverride
                        defaultValue: false
                        onToggled: { 
                            PrefsService.dynamicThemeOverride = checked; 
                            if (checked) appearanceGroup.dropdownExpanded = true;
                            PrefsService.saveConfig(); 
                        }
                    }

                    Rectangle {
                        visible: PrefsService.dynamicThemeOverride
                        width: Math.round(28 * localScale)
                        height: Math.round(28 * localScale)
                        radius: Math.round(6 * localScale)
                        anchors {
                            right: parent.right
                            rightMargin: Math.round(84 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        color: themeChevHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: appearanceGroup.dropdownExpanded ? "▲" : "▼"
                            color: Theme.text
                            font.pixelSize: Math.round(10 * localScale)
                        }

                        HoverHandler { id: themeChevHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: appearanceGroup.dropdownExpanded = !appearanceGroup.dropdownExpanded
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: (dynamicThemeToggle.checked && appearanceGroup.dropdownExpanded) ? themeContentCol.height : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: Anim.fast
                            easing.type: Anim.globalCurve
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(2 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        radius: Math.round(1 * localScale)
                        anchors.leftMargin: Math.round(12 * localScale)
                    }

                    Column {
                        id: themeContentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(24 * localScale)
                        spacing: Math.round(4 * localScale)

                        SettingsDivider { localScale: root.localScale }

                        SettingsButton {
                            localScale: root.localScale
                            text: "Background Color"
                            description: "Main background (" + (PrefsService.overrideBg !== "" ? PrefsService.overrideBg : "Default") + ")"
                            swatchColor: PrefsService.overrideBg !== "" ? PrefsService.overrideBg : Theme.background
                            onClicked: chartPopup.open("bg")
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsButton {
                            localScale: root.localScale
                            text: "Active Accent Color"
                            description: "Primary highlight (" + (PrefsService.overrideActive !== "" ? PrefsService.overrideActive : "Default") + ")"
                            swatchColor: PrefsService.overrideActive !== "" ? PrefsService.overrideActive : Theme.active
                            onClicked: chartPopup.open("active")
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsButton {
                            localScale: root.localScale
                            text: "Text Color"
                            description: "Primary typography (" + (PrefsService.overrideText !== "" ? PrefsService.overrideText : "Default") + ")"
                            swatchColor: PrefsService.overrideText !== "" ? PrefsService.overrideText : Theme.text
                            onClicked: chartPopup.open("text")
                        }
                        SettingsDivider { localScale: root.localScale }
                        SettingsButton {
                            localScale: root.localScale
                            text: "Border Color"
                            description: "Surface outline (" + (PrefsService.overrideBorder !== "" ? PrefsService.overrideBorder : "Default") + ")"
                            swatchColor: PrefsService.overrideBorder !== "" ? PrefsService.overrideBorder : Theme.border
                            onClicked: chartPopup.open("border")
                        }
                    }
                }
            }
        }
    }

    // ── Native HLS Color Studio Modal ─────────────────────────────────────────
    Rectangle {
        id: chartPopup
        anchors.fill: parent
        z: 300
        visible: false
        onVisibleChanged: {
            Popups.colorPickerActive = visible;
            if (visible) Popups.dashboardPinned = true;
        }
        color: Qt.rgba(0, 0, 0, 0.75)

        property string activeTarget: ""
        property real hue: 210
        property real lit: 60
        property real sat: 80
        property bool copiedToast: false

        Timer {
            id: toastTimer
            interval: 1500
            onTriggered: chartPopup.copiedToast = false
        }

        Process {
            id: copyProc
            command: []
        }

        Connections {
            target: Popups
            function onDashboardOpenChanged() {
                if (!Popups.dashboardOpen) chartPopup.visible = false;
            }
        }

        Process {
            id: eyeProc
            command: ["bash", "-c", "geom=$(slurp -p -b 00000000 -c 00000000 2>/dev/null) || exit 0; rgb=$(grim -g \"$geom\" -t ppm - 2>/dev/null | tail -c 3 | od -An -t u1) || exit 0; echo \"$rgb\" | awk '{ r=$1+0; g=$2+0; b=$3+0; printf \"#%02x%02x%02x\\n\", r, g, b }'"]
            onExited: Popups.colorPickerActive = false
            stdout: SplitParser {
                onRead: function(line) {
                    if (!line || !line.startsWith("#")) return;
                    chartPopup.setFromHex(line.trim());
                }
            }
        }

        function launchEyedropper() {
            Popups.colorPickerActive = true;
            Popups.dashboardPinned = true;
            eyeProc.running = false;
            eyeProc.running = true;
        }

        function copyToClipboard(hex) {
            copyProc.command = ["bash", "-c", "printf '%s' '" + hex + "' | { if command -v wl-copy >/dev/null 2>&1; then setsid -f wl-copy; elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; else xsel --clipboard --input 2>/dev/null; fi; }"];
            copyProc.running = false;
            copyProc.running = true;
            copiedToast = true;
            toastTimer.restart();
        }

        function hexAt(h, s, l) {
            var l_norm = l / 100;
            var a = (s * Math.min(l_norm, 1 - l_norm)) / 100;
            var f = n => {
                var k = (n + h / 30) % 12;
                var c = l_norm - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
                return Math.round(255 * c).toString(16).padStart(2, '0');
            };
            return "#" + f(0) + f(8) + f(4);
        }

        readonly property string currentHex: hexAt(hue, sat, lit)
        readonly property string pureHex: hexAt(hue, sat, 50)
        readonly property string grayHex: hexAt(hue, 0, lit)
        readonly property string fullSatHex: hexAt(hue, 100, lit)

        function setFromHex(hexStr) {
            var hex = hexStr.startsWith("#") ? hexStr : "#" + hexStr;
            if (hex.length < 7) return;
            var r = parseInt(hex.slice(1,3), 16) / 255;
            var g = parseInt(hex.slice(3,5), 16) / 255;
            var b = parseInt(hex.slice(5,7), 16) / 255;
            var max = Math.max(r, g, b), min = Math.min(r, g, b);
            var h = 0, s = 0, l = (max + min) / 2;
            if (max !== min) {
                var d = max - min;
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
                else if (max === g) h = (b - r) / d + 2;
                else if (max === b) h = (r - g) / d + 4;
                h /= 6;
            }
            hue = h * 360;
            sat = s * 100;
            lit = l * 100;
        }

        function open(prop) {
            activeTarget = prop;
            var cur = "";
            if (prop === "bg") cur = PrefsService.overrideBg !== "" ? PrefsService.overrideBg : Theme.background;
            else if (prop === "active") cur = PrefsService.overrideActive !== "" ? PrefsService.overrideActive : Theme.active;
            else if (prop === "text") cur = PrefsService.overrideText !== "" ? PrefsService.overrideText : Theme.text;
            else if (prop === "subtext") cur = PrefsService.overrideSubtext !== "" ? PrefsService.overrideSubtext : Theme.subtext;
            else if (prop === "iconFont") cur = PrefsService.overrideIconFont !== "" ? PrefsService.overrideIconFont : Theme.iconFont;
            else if (prop === "border") cur = PrefsService.overrideBorder !== "" ? PrefsService.overrideBorder : Theme.border;
            else if (prop === "icon") cur = PrefsService.overrideIcon !== "" ? PrefsService.overrideIcon : Theme.icon;
            
            if (cur.startsWith("#") && cur.length >= 7) {
                setFromHex(cur.slice(0, 7));
            }
            visible = true;
        }

        function applyColor(hex) {
            if (activeTarget === "bg") PrefsService.overrideBg = hex;
            else if (activeTarget === "active") PrefsService.overrideActive = hex;
            else if (activeTarget === "text") PrefsService.overrideText = hex;
            else if (activeTarget === "subtext") PrefsService.overrideSubtext = hex;
            else if (activeTarget === "iconFont") PrefsService.overrideIconFont = hex;
            else if (activeTarget === "border") PrefsService.overrideBorder = hex;
            else if (activeTarget === "icon") PrefsService.overrideIcon = hex;
            PrefsService.saveConfig();
            visible = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: chartPopup.visible = false
        }

        Rectangle {
            width: Math.round(350 * root.localScale)
            height: Math.round(385 * root.localScale)
            anchors.centerIn: parent
            color: Theme.background
            radius: Math.round(16 * root.localScale)
            border.color: Theme.border
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {} // prevent backdrop click-through
            }

            Column {
                anchors { fill: parent; margins: Math.round(16 * root.localScale) }
                spacing: Math.round(8 * root.localScale)

                // Header
                Item {
                    width: parent.width
                    height: Math.round(24 * root.localScale)
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "COLOR PICKER  •  " + chartPopup.activeTarget.toUpperCase()
                        color: Theme.text
                        font.pixelSize: Math.round(12 * root.localScale)
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(22 * root.localScale); height: width; radius: width/2
                        color: clH.hovered ? Theme.border : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.text; font.pixelSize: Math.round(11 * root.localScale) }
                        HoverHandler { id: clH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: chartPopup.visible = false }
                    }
                }

                Rectangle { height: 1; width: parent.width; color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.45) }

                // Preview & Action Row
                Row {
                    width: parent.width
                    spacing: Math.round(14 * root.localScale)

                    Rectangle {
                        width: Math.round(84 * root.localScale)
                        height: Math.round(84 * root.localScale)
                        radius: Math.round(14 * root.localScale)
                        color: chartPopup.currentHex
                        border.color: Theme.border; border.width: 1

                        HoverHandler { id: prevHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chartPopup.copyToClipboard(chartPopup.currentHex)
                        }

                        Text {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(6 * root.localScale); anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰆏 COPY"
                            color: chartPopup.lit > 65 ? "#000000" : "#ffffff"
                            font.pixelSize: Math.round(9 * root.localScale); font.weight: Font.Bold
                            opacity: prevHov.hovered ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(6 * root.localScale)
                        width: parent.width - Math.round(98 * root.localScale)

                        Text {
                            text: "HEX COLOR / EYEDROPPER"
                            color: Theme.subtext
                            font.pixelSize: Math.round(8 * root.localScale)
                            font.weight: Font.Bold
                        }

                        Row {
                            width: parent.width
                            spacing: Math.round(6 * root.localScale)

                            Rectangle {
                                width: parent.width - Math.round(68 * root.localScale)
                                height: Math.round(30 * root.localScale)
                                radius: Math.round(6 * root.localScale)
                                color: Qt.rgba(0,0,0,0.2)
                                border.color: hexInput.activeFocus ? Theme.active : Theme.border
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: hexInput.forceActiveFocus()
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: "#"
                                        color: Theme.text
                                        font.pixelSize: Math.round(13 * root.localScale)
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                    }
                                    TextInput {
                                        id: hexInput
                                        color: Theme.text
                                        font.pixelSize: Math.round(13 * root.localScale)
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        maximumLength: 6
                                        selectByMouse: true
                                        verticalAlignment: TextInput.AlignVCenter

                                        Component.onCompleted: text = chartPopup.currentHex.slice(1).toUpperCase()

                                        Connections {
                                            target: chartPopup
                                            function onHueChanged() { if (!hexInput.activeFocus) hexInput.text = chartPopup.currentHex.slice(1).toUpperCase() }
                                            function onLitChanged() { if (!hexInput.activeFocus) hexInput.text = chartPopup.currentHex.slice(1).toUpperCase() }
                                            function onSatChanged() { if (!hexInput.activeFocus) hexInput.text = chartPopup.currentHex.slice(1).toUpperCase() }
                                        }

                                        onTextChanged: {
                                            var clean = text.replace(/[^0-9A-Fa-f]/g, "").slice(0, 6).toUpperCase();
                                            if (text !== clean) {
                                                var pos = cursorPosition;
                                                text = clean;
                                                cursorPosition = Math.min(pos, clean.length);
                                            }
                                            if (clean.length === 6) {
                                                chartPopup.setFromHex("#" + clean);
                                            }
                                        }
                                        onAccepted: {
                                            if (text.length === 6) chartPopup.applyColor("#" + text);
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: Math.round(30 * root.localScale)
                                height: Math.round(30 * root.localScale)
                                radius: Math.round(6 * root.localScale)
                                color: chartPopup.copiedToast ? Theme.active : (copyBtnHov.hovered ? Theme.border : Qt.rgba(0,0,0,0.2))
                                border.color: Theme.border; border.width: 1
                                HoverHandler { id: copyBtnHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: chartPopup.copyToClipboard(chartPopup.currentHex)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: chartPopup.copiedToast ? "✓" : "󰆏"
                                    color: chartPopup.copiedToast ? "#000000" : Theme.text
                                    font.pixelSize: Math.round(13 * root.localScale)
                                }
                            }

                            Rectangle {
                                width: Math.round(30 * root.localScale)
                                height: Math.round(30 * root.localScale)
                                radius: Math.round(6 * root.localScale)
                                color: eyeBtnHov.hovered ? Theme.border : Qt.rgba(0,0,0,0.2)
                                border.color: Theme.border; border.width: 1
                                HoverHandler { id: eyeBtnHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: chartPopup.launchEyedropper()
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰈊"
                                    color: Theme.text
                                    font.pixelSize: Math.round(14 * root.localScale)
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.round(30 * root.localScale)
                            radius: Math.round(6 * root.localScale)
                            color: Theme.active

                            HoverHandler { id: apH2; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: chartPopup.applyColor(chartPopup.currentHex)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Apply Color"
                                color: "#000000"
                                font.pixelSize: Math.round(11 * root.localScale)
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                // Sleek Sliders
                Column {
                    width: parent.width
                    spacing: Math.round(8 * root.localScale)

                    // Hue
                    Column {
                        width: parent.width; spacing: Math.round(3 * root.localScale)
                        Item {
                            width: parent.width; height: Math.round(14 * root.localScale)
                            Text { anchors.left: parent.left; text: "HUE"; color: Theme.subtext; font.pixelSize: Math.round(9 * root.localScale); font.weight: Font.Bold }
                            Text { anchors.right: parent.right; text: Math.round(chartPopup.hue) + "°"; color: Theme.text; font.pixelSize: Math.round(10 * root.localScale); font.family: "JetBrains Mono"; font.weight: Font.Bold }
                        }
                        Rectangle {
                            width: parent.width; height: Math.round(14 * root.localScale); radius: height/2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ff0000" }
                                GradientStop { position: 0.16; color: "#ffff00" }
                                GradientStop { position: 0.33; color: "#00ff00" }
                                GradientStop { position: 0.50; color: "#00ffff" }
                                GradientStop { position: 0.66; color: "#0000ff" }
                                GradientStop { position: 0.83; color: "#ff00ff" }
                                GradientStop { position: 1.0; color: "#ff0000" }
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width, (chartPopup.hue / 360) * (parent.width - width)))
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(18 * root.localScale); height: width; radius: width/2; color: "#ffffff"; border.color: Qt.rgba(0,0,0,0.5); border.width: 2
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                                function upd(m) { chartPopup.hue = Math.max(0, Math.min(360, (m.x / width) * 360)) }
                                onPressed: (m) => upd(m)
                                onPositionChanged: (m) => { if (pressed) upd(m) }
                            }
                        }
                    }

                    // Lightness
                    Column {
                        width: parent.width; spacing: Math.round(3 * root.localScale)
                        Item {
                            width: parent.width; height: Math.round(14 * root.localScale)
                            Text { anchors.left: parent.left; text: "LIGHTNESS"; color: Theme.subtext; font.pixelSize: Math.round(9 * root.localScale); font.weight: Font.Bold }
                            Text { anchors.right: parent.right; text: Math.round(chartPopup.lit) + "%"; color: Theme.text; font.pixelSize: Math.round(10 * root.localScale); font.family: "JetBrains Mono"; font.weight: Font.Bold }
                        }
                        Rectangle {
                            width: parent.width; height: Math.round(14 * root.localScale); radius: height/2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#000000" }
                                GradientStop { position: 0.5; color: chartPopup.pureHex }
                                GradientStop { position: 1.0; color: "#ffffff" }
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width, (chartPopup.lit / 100) * (parent.width - width)))
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(18 * root.localScale); height: width; radius: width/2; color: "#ffffff"; border.color: Qt.rgba(0,0,0,0.5); border.width: 2
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                                function updL(m) { chartPopup.lit = Math.max(0, Math.min(100, (m.x / width) * 100)) }
                                onPressed: (m) => updL(m)
                                onPositionChanged: (m) => { if (pressed) updL(m) }
                            }
                        }
                    }

                    // Saturation
                    Column {
                        width: parent.width; spacing: Math.round(3 * root.localScale)
                        Item {
                            width: parent.width; height: Math.round(14 * root.localScale)
                            Text { anchors.left: parent.left; text: "SATURATION"; color: Theme.subtext; font.pixelSize: Math.round(9 * root.localScale); font.weight: Font.Bold }
                            Text { anchors.right: parent.right; text: Math.round(chartPopup.sat) + "%"; color: Theme.text; font.pixelSize: Math.round(10 * root.localScale); font.family: "JetBrains Mono"; font.weight: Font.Bold }
                        }
                        Rectangle {
                            width: parent.width; height: Math.round(14 * root.localScale); radius: height/2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: chartPopup.grayHex }
                                GradientStop { position: 1.0; color: chartPopup.fullSatHex }
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width, (chartPopup.sat / 100) * (parent.width - width)))
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(18 * root.localScale); height: width; radius: width/2; color: "#ffffff"; border.color: Qt.rgba(0,0,0,0.5); border.width: 2
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                                function updS(m) { chartPopup.sat = Math.max(0, Math.min(100, (m.x / width) * 100)) }
                                onPressed: (m) => updS(m)
                                onPositionChanged: (m) => { if (pressed) updS(m) }
                            }
                        }
                    }
                }

                Rectangle { height: 1; width: parent.width; color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.45) }

                // Quick Palette
                Column {
                    width: parent.width; spacing: Math.round(6 * root.localScale)
                    Text { text: "QUICK PALETTE"; color: Theme.subtext; font.pixelSize: Math.round(9 * root.localScale); font.weight: Font.Bold }
                    
                    Grid {
                        columns: 7; columnSpacing: Math.round(8 * root.localScale); rowSpacing: Math.round(8 * root.localScale)
                        anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: ["#f5e0dc", "#f2cdcd", "#f5c2e7", "#cba6f7", "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb", "#89b4fa", "#b4befe", "#1e1e2e", "#eff1f5"]
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.round(33 * root.localScale); height: width; radius: width/2
                                color: modelData
                                border.color: palH.hovered ? Theme.text : (chartPopup.currentHex.toLowerCase() === modelData ? Theme.active : Qt.rgba(0,0,0,0.2))
                                border.width: (chartPopup.currentHex.toLowerCase() === modelData || palH.hovered) ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                HoverHandler { id: palH; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: chartPopup.setFromHex(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."
import "../Services"
import "../Popups"
import "../Notification"
import  "."

PanelWindow {
    id: root

    anchors { top: true; bottom: true; right: true }

    width: 450
    color: "transparent"
    visible: false

    exclusionMode:               ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool panelOpen: false

    readonly property color  cardColor:          Colors.md3.surface_container_low
    readonly property color  sectionColor:        Colors.md3.surface_container
    readonly property int    cardRadius:          24
    readonly property int    sectionRadius:       16
    readonly property int    cardMargin:          8
    readonly property color  chipColor:           Colors.md3.surface_container
    readonly property color  chipHoverColor:      Colors.md3.surface_container_highest
    readonly property color  chipActiveColor:     Colors.md3.primary
    readonly property color  chipActiveText:      Colors.md3.on_primary
    readonly property int    uptimeChipHeight:    36
    readonly property int    uptimeChipRadius:    18
    readonly property int    iconBtnSize:         36
    readonly property int    iconBtnRadius:       18
    readonly property int    iconBtnPixelSize:    16
    readonly property color  powerHoverBg:        Qt.rgba(Colors.md3.error.r,
                                                          Colors.md3.error.g,
                                                          Colors.md3.error.b, 0.20)
    readonly property color  powerHoverIcon:      Colors.md3.error
    readonly property int    sliderRowHeight:     52
    readonly property int    sliderRowRadius:     16
    readonly property int    sliderTrackH:        6
    readonly property int    sliderTrackR:        3
    readonly property int    sliderThumbW:        4
    readonly property int    sliderThumbH:        28
    readonly property color  sliderFillColor:     Colors.md3.primary
    readonly property real   sliderFillOpacity:   0.88
    readonly property color  sliderTrackBg:       Qt.rgba(Colors.md3.on_surface.r,
                                                          Colors.md3.on_surface.g,
                                                          Colors.md3.on_surface.b, 0.10)
    readonly property string fontSans:            "Google Sans Flex"
    readonly property string fontMono:            "JetBrainsMono Nerd Font"
    readonly property color  colorPrimary:        Colors.md3.primary
    readonly property color  colorOnSurface:      Colors.md3.on_surface
    readonly property color  colorMuted:          Colors.md3.on_surface_variant
    readonly property int    animDuration:        380
    readonly property int    pillHeight:          80
    readonly property int    pillRadius:          20

    // ── WiFi state — fully reactive bindings ──────────────────────────────────
    readonly property var wifiDevice: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i]
        }
        return null
    }

    readonly property bool wifiConnected: {
        if (!root.wifiDevice) return false
        const nets = root.wifiDevice.networks.values
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return true
        }
        return root.wifiDevice.connected
    }

    readonly property string wifiSsid: {
        if (!root.wifiDevice) return ""
        const nets = root.wifiDevice.networks.values
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i].name
        }
        return ""
    }

    // ── Bluetooth state ───────────────────────────────────────────────────────
    property bool   btEnabled:       false
    property string btConnectedName: ""

    Connections {
        target: Bluetooth
        function onAdaptersChanged() { root.updateBt() }
        function onDevicesChanged()  { root.updateBt() }
    }
    function updateBt() {
        var adapters = Bluetooth.adapters.values
        if (adapters.length === 0) { root.btEnabled = false; root.btConnectedName = ""; return }
        root.btEnabled = adapters[0].powered
        var devs = Bluetooth.devices.values
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected) { root.btConnectedName = devs[i].name; return }
        }
        root.btConnectedName = ""
    }

    Component.onCompleted: { root.updateBt() }

    // ── Uptime ────────────────────────────────────────────────────────────────
    property string uptimeString: "0m"
    FileView { id: uptimeFile; path: "/proc/uptime" }
    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            uptimeFile.reload()
            const raw     = uptimeFile.text()
            const seconds = Math.floor(parseFloat(raw.split(" ")[0]))
            const d = Math.floor(seconds / 86400)
            const h = Math.floor((seconds % 86400) / 3600)
            const m = Math.floor((seconds % 3600) / 60)
            if (d > 0)      root.uptimeString = d + "d " + h + "h"
            else if (h > 0) root.uptimeString = h + "h " + m + "m"
            else            root.uptimeString = m + "m"
        }
    }

    // ── Focus grab ────────────────────────────────────────────────────────────
    HyprlandFocusGrab {
        id: focusGrab; windows: [root]; active: false
        onCleared: root.close()
    }

    // ── Panel card ────────────────────────────────────────────────────────────
    Rectangle {
        id: panel

        width:  360
        anchors.top:          parent.top
        anchors.bottom:       parent.bottom
        anchors.right:        parent.right
        anchors.topMargin:    root.cardMargin
        anchors.bottomMargin: root.cardMargin
        anchors.rightMargin:  root.cardMargin

        radius: root.cardRadius
        color:  root.cardColor
        clip:   true

        transform: Translate {
            x: root.panelOpen ? 0 : panel.width + root.cardMargin + 8
            Behavior on x {
                NumberAnimation { duration: root.animDuration; easing.type: Easing.OutQuint }
            }
        }
        opacity: root.panelOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        // ── Top controls (fixed, not scrollable) ──────────────────────────────
        ColumnLayout {
            id: topSection
            anchors {
                top:   parent.top;   topMargin:   12
                left:  parent.left;  leftMargin:  12
                right: parent.right; rightMargin: 12
            }
            spacing: 8

            // ── Section 1: Uptime · Wallpaper · Power ─────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: root.sectionRadius
                color:  root.sectionColor
                implicitHeight: s1Row.implicitHeight + 20

                RowLayout {
                    id: s1Row
                    anchors {
                        left: parent.left; leftMargin: 14
                        right: parent.right; rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    // Uptime chip
                    Rectangle {
                        height:        root.uptimeChipHeight
                        radius:        root.uptimeChipRadius
                        color:         Colors.md3.surface_container_highest
                        implicitWidth: uptimeRow.implicitWidth + 22

                        Row {
                            id: uptimeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰔚"; font.family: root.fontMono; font.pixelSize: 14
                                color: root.colorPrimary; renderType: Text.NativeRendering
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.uptimeString
                                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                                color: root.colorOnSurface; renderType: Text.NativeRendering
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: root.iconBtnSize; height: root.iconBtnSize; radius: root.iconBtnRadius
                        color: wallHov.containsMouse ? root.chipHoverColor : Colors.md3.surface_container_highest
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent; text: "󰸉"
                            font.family: root.fontMono; font.pixelSize: root.iconBtnPixelSize
                            color: root.colorOnSurface; renderType: Text.NativeRendering
                        }
                        MouseArea {
                            id: wallHov; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WindowState.toggleWallpaper()
                        }
                    }

                    Rectangle {
                        width: root.iconBtnSize; height: root.iconBtnSize; radius: root.iconBtnRadius
                        color: powerHov.containsMouse ? root.powerHoverBg : Colors.md3.surface_container_highest
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent; text: "󰐥"
                            font.family: root.fontMono; font.pixelSize: root.iconBtnPixelSize
                            color: powerHov.containsMouse ? root.powerHoverIcon : root.colorOnSurface
                            renderType: Text.NativeRendering
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: powerHov; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerMenu.toggle()
                        }
                    }
                }
            }

            // ── Section 2: Brightness slider ──────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: root.sliderRowHeight
                radius: root.sectionRadius
                color:  Colors.md3.surface_container_high

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10

                    Text {
                        text: "󰃝"; font.family: root.fontMono; font.pixelSize: 16
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }

                    Item {
                        Layout.fillWidth: true
                        height: root.sliderThumbH

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: root.sliderTrackH

                            Rectangle {
                                width: parent.width; height: parent.height
                                radius: root.sliderTrackR
                                color: root.sliderFillColor; opacity: 0.18
                            }
                            Item {
                                width: Math.max(root.sliderTrackR * 2,
                                       (BrightnessService.brightnessPercent / 100) * parent.width)
                                height: parent.height
                                clip: true
                                Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                                Rectangle {
                                    width: parent.parent.width; height: parent.height
                                    radius: root.sliderTrackR
                                    color: root.sliderFillColor; opacity: root.sliderFillOpacity
                                }
                            }
                        }

                        Rectangle {
                            x: Math.max(root.sliderTrackR * 2,
                               (BrightnessService.brightnessPercent / 100) * parent.width) - (root.sliderThumbW / 2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.sliderThumbW; height: root.sliderThumbH
                            radius: 2; color: "#ffffff"; opacity: 0.95
                            Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            function set(mx) {
                                const pct = Math.min(Math.max(mx / width, 0), 1)
                                BrightnessService.setBrightness(Math.round(pct * 100))
                            }
                            onClicked:         (e) => set(e.x)
                            onPositionChanged: (e) => { if (pressed) set(e.x) }
                            onWheel: (e) => {
                                if (e.angleDelta.y > 0) BrightnessService.increaseBrightness(5)
                                else                    BrightnessService.decreaseBrightness(5)
                            }
                        }
                    }

                    Text {
                        text: "󰃠"; font.family: root.fontMono; font.pixelSize: 16
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                }
            }

            // ── Section 3: Wi-Fi · Bluetooth ──────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: root.sectionRadius
                color:  "transparent"
                implicitHeight: wifibtRow.implicitHeight + 16

                RowLayout {
                    id: wifibtRow
                    anchors {
                        left: parent.left; leftMargin: 10
                        right: parent.right; rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 10

                    // Wi-Fi pill
                    Rectangle {
                        Layout.fillWidth: true
                        height: root.pillHeight; radius: root.pillRadius
                        color: root.wifiConnected
                               ? root.chipActiveColor
                               : (wifiArea.containsMouse ? root.chipHoverColor : Colors.md3.surface_container_highest)
                        Behavior on color { ColorAnimation { duration: 130 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.wifiConnected ? "󰖩" : "󰖪"
                                font.family: root.fontMono; font.pixelSize: 22
                                color: root.wifiConnected ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "Wi-Fi"
                                font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                color: root.wifiConnected ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.wifiConnected
                                      ? (root.wifiSsid !== "" ? root.wifiSsid : "Connected")
                                      : "Not connected"
                                font.family: root.fontSans; font.pixelSize: 9
                                color: root.wifiConnected
                                       ? Qt.rgba(root.chipActiveText.r, root.chipActiveText.g, root.chipActiveText.b, 0.80)
                                       : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.60)
                                renderType: Text.NativeRendering; elide: Text.ElideRight
                                width: Math.min(implicitWidth, 90)
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        MouseArea {
                            id: wifiArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifiPopup.visible ? wifiPopup.close() : wifiPopup.open()
                        }
                    }

                    // Bluetooth pill
                    Rectangle {
                        Layout.fillWidth: true
                        height: root.pillHeight; radius: root.pillRadius
                        color: root.btEnabled
                               ? root.chipActiveColor
                               : (btArea.containsMouse ? root.chipHoverColor : Colors.md3.surface_container_highest)
                        Behavior on color { ColorAnimation { duration: 130 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.btEnabled ? "󰂯" : "󰂲"
                                font.family: root.fontMono; font.pixelSize: 22
                                color: root.btEnabled ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "Bluetooth"
                                font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                color: root.btEnabled ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.btEnabled
                                      ? (root.btConnectedName !== "" ? root.btConnectedName : "On")
                                      : "Off"
                                font.family: root.fontSans; font.pixelSize: 9
                                color: root.btEnabled
                                       ? Qt.rgba(root.chipActiveText.r, root.chipActiveText.g, root.chipActiveText.b, 0.80)
                                       : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.60)
                                renderType: Text.NativeRendering; elide: Text.ElideRight
                                width: Math.min(implicitWidth, 90)
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        MouseArea {
                            id: btArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["blueman-manager"])
                        }
                    }
                }
            }

            // ── Section 4: DND · Eye Care ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: root.sectionRadius
                color:  "transparent"
                implicitHeight: dndEyeRow.implicitHeight + 16

                RowLayout {
                    id: dndEyeRow
                    anchors {
                        left: parent.left; leftMargin: 10
                        right: parent.right; rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 10

                    // DND pill
                    Rectangle {
                        Layout.fillWidth: true
                        height: root.pillHeight; radius: root.pillRadius
                        color: NotificationService.doNotDisturb
                               ? root.chipActiveColor
                               : (dndArea.containsMouse ? root.chipHoverColor : Colors.md3.surface_container_highest)
                        Behavior on color { ColorAnimation { duration: 130 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "󰂛"
                                font.family: root.fontMono; font.pixelSize: 22
                                color: NotificationService.doNotDisturb ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "Do Not Disturb"
                                font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                color: NotificationService.doNotDisturb ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: NotificationService.doNotDisturb ? "Active" : "Inactive"
                                font.family: root.fontSans; font.pixelSize: 9
                                color: NotificationService.doNotDisturb
                                       ? Qt.rgba(root.chipActiveText.r, root.chipActiveText.g, root.chipActiveText.b, 0.80)
                                       : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.60)
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        MouseArea {
                            id: dndArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
                        }
                    }

                    // Eye Care pill
                    Rectangle {
                        Layout.fillWidth: true
                        height: root.pillHeight; radius: root.pillRadius
                        color: eyeCarePopup.active
                               ? root.chipActiveColor
                               : (eyeArea.containsMouse ? root.chipHoverColor : Colors.md3.surface_container_highest)
                        Behavior on color { ColorAnimation { duration: 130 } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "󰛊"
                                font.family: root.fontMono; font.pixelSize: 22
                                color: eyeCarePopup.active ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter; text: "Eye Care"
                                font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                color: eyeCarePopup.active ? root.chipActiveText : root.colorMuted
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: eyeCarePopup.active ? "Active" : "Inactive"
                                font.family: root.fontSans; font.pixelSize: 9
                                color: eyeCarePopup.active
                                       ? Qt.rgba(root.chipActiveText.r, root.chipActiveText.g, root.chipActiveText.b, 0.80)
                                       : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.60)
                                renderType: Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        MouseArea {
                            id: eyeArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: eyeCarePopup.visible ? eyeCarePopup.close() : eyeCarePopup.open()
                        }
                    }
                }
            }
        }

        // ── Tray ──────────────────────────────────────────────────────────────
        Tray {
            id: tray
            anchors {
                top:    topSection.bottom; topMargin:    8
                left:   panel.left;        leftMargin:   12
                right:  panel.right;       rightMargin:  12
                bottom: panel.bottom;      bottomMargin: 12
            }

            fontSans:       root.fontSans
            fontMono:       root.fontMono
            colorPrimary:   root.colorPrimary
            colorOnSurface: root.colorOnSurface
            colorMuted:     root.colorMuted
            chipColor:      root.chipColor
            chipHover:      root.chipHoverColor
            errorColor:     Colors.md3.error
        }

        // ── Popups (layered above everything inside the card) ─────────────────
        EyeCarePopup {
            id: eyeCarePopup
            fontSans:       root.fontSans
            fontMono:       root.fontMono
            colorPrimary:   root.colorPrimary
            colorOnSurface: root.colorOnSurface
            colorMuted:     root.colorMuted
            chipHoverColor: root.chipHoverColor
            sliderTrackBg:  root.sliderTrackBg
        }

        WifiPopup {
            id: wifiPopup
        }
    }

    // ── Panel open/close logic ────────────────────────────────────────────────
    Timer {
        id: closeTimer; interval: root.animDuration + 40; repeat: false
        onTriggered: { if (!root.panelOpen) root.visible = false }
    }

    function toggle() {
        if (root.visible && root.panelOpen) { close() }
        else {
            root.visible     = true
            root.panelOpen   = true
            focusGrab.active = true
        }
    }

    function close() {
        root.panelOpen       = false
        focusGrab.active     = false
        eyeCarePopup.visible = false
        wifiPopup.visible    = false
        closeTimer.start()
    }

    Keys.onEscapePressed: root.close()
}

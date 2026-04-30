import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import ".."

Rectangle {
    id: root
    visible: false

    property string fontSans:       "Google Sans Flex"
    property string fontMono:       "JetBrainsMono Nerd Font"
    property color  colorPrimary:   Colors.md3.primary
    property color  colorOnSurface: Colors.md3.on_surface
    property color  colorMuted:     Colors.md3.on_surface_variant
    property color  colorError:     Colors.md3.error
    property color  chipHoverColor: Colors.md3.surface_container_highest
    property color  colorSurface:   Colors.md3.surface_container

    // ── Sizing / positioning ──────────────────────────────────────────────────
    anchors.fill: parent
    color:        "transparent"
    z:            20

    // ── Backdrop ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(0, 0, 0, 0.32)
        radius:       parent.parent ? parent.parent.radius : 0
        opacity:      root.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width:  parent.width - 28
        height: Math.min(contentCol.implicitHeight + 52, 560)
        anchors.centerIn: parent
        radius: 20
        color:  root.colorSurface
        clip:   true

        // Inner border
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.color: Qt.rgba(root.colorOnSurface.r, root.colorOnSurface.g, root.colorOnSurface.b, 0.06)
            border.width: 1; z: 99
        }

        scale:   root.visible ? 1.0 : 0.95
        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ── Wifi device ───────────────────────────────────────────────────────
        readonly property var wifiDevice: {
            for (let i = 0; i < Networking.devices.values.length; i++) {
                const d = Networking.devices.values[i]
                if (d.type === DeviceType.Wifi) return d
            }
            return null
        }
        readonly property bool wifiOn:     Networking.wifiEnabled
        readonly property bool isScanning: wifiOn && wifiDevice !== null && wifiDevice.scannerEnabled

        onVisibleChanged: {
            if (visible && wifiDevice && wifiOn) wifiDevice.scannerEnabled = true
            else if (!visible && wifiDevice)     wifiDevice.scannerEnabled = false
        }

        Connections {
            target: card
            function onWifiOnChanged() {
                if (card.wifiDevice) card.wifiDevice.scannerEnabled = (root.visible && card.wifiOn)
            }
        }

        function signalBars(strength) {
            if (strength >= 0.75) return 4
            if (strength >= 0.50) return 3
            if (strength >= 0.25) return 2
            return 1
        }

        function failReasonText(reason) {
            if (reason === ConnectionFailReason.NoSecrets)
                return "Wrong password — double-check and try again."
            if (reason === ConnectionFailReason.WifiAuthTimeout)
                return "Authentication timed out. The network may be too far away."
            if (reason === ConnectionFailReason.WifiNetworkLost)
                return "Network not found. It may be out of range."
            if (reason === ConnectionFailReason.WifiClientFailed)
                return "Wi-Fi supplicant failed. Try again."
            if (reason === ConnectionFailReason.WifiClientDisconnected)
                return "Disconnected by the supplicant. Try again."
            return "Connection failed for an unknown reason."
        }

        // ── Spinner component ─────────────────────────────────────────────────
        component SpinnerRing: Item {
            id: spinItem
            property color ringColor: root.colorPrimary
            property int   ringSize:  16
            width: ringSize; height: ringSize

            Canvas {
                id: spinCanvas
                anchors.fill: parent
                property real angle: 0
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const cx = width / 2, cy = height / 2
                    const r  = (Math.min(width, height) - 2.5) / 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, angle, angle + Math.PI * 1.35)
                    ctx.strokeStyle = Qt.rgba(spinItem.ringColor.r,
                                              spinItem.ringColor.g,
                                              spinItem.ringColor.b, 0.90)
                    ctx.lineWidth   = 2.2
                    ctx.lineCap     = "round"
                    ctx.stroke()
                }
                NumberAnimation on angle {
                    from: 0; to: Math.PI * 2
                    duration: 800; loops: Animation.Infinite
                    running: spinItem.visible; easing.type: Easing.Linear
                }
                onAngleChanged: requestPaint()
            }
        }

        // ── Layout ────────────────────────────────────────────────────────────
        ColumnLayout {
            id: contentCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
            spacing: 0

            // ── Header ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 12
                spacing: 10

                // Icon badge
                Rectangle {
                    width: 34; height: 34; radius: 10
                    color: card.wifiOn
                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.15)
                           : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.10)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text {
                        anchors.centerIn: parent
                        text: card.wifiOn ? "󰖩" : "󰖪"
                        font.family: root.fontMono; font.pixelSize: 17
                        color: card.wifiOn ? root.colorPrimary : root.colorMuted
                        renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Title + subtitle
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Wi-Fi"
                        font.family: root.fontSans; font.pixelSize: 14; font.weight: Font.SemiBold
                        color: root.colorOnSurface; renderType: Text.NativeRendering
                    }
                    Text {
                        visible: card.wifiOn && card.wifiDevice !== null
                        text: {
                            if (!card.wifiDevice) return ""
                            const nets = card.wifiDevice.networks.values
                            for (let i = 0; i < nets.length; i++) {
                                if (nets[i].connected) return nets[i].name
                            }
                            return card.isScanning ? "Scanning…" : "Not connected"
                        }
                        font.family: root.fontSans; font.pixelSize: 10
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                }

                Item { Layout.fillWidth: true }

                // Toggle switch
                Rectangle {
                    width: 48; height: 26; radius: 13
                    color: card.wifiOn
                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.25)
                           : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.12)
                    border.color: card.wifiOn
                                  ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.35)
                                  : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.20)
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: card.wifiOn ? parent.width - width - 4 : 4
                        color: card.wifiOn ? root.colorPrimary : root.colorMuted
                        Behavior on x     { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation  { duration: 160 } }
                        Rectangle {
                            anchors.centerIn: parent; width: 6; height: 6; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.6); visible: card.wifiOn
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                // Close button
                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: closeHov.containsMouse
                           ? Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.15)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "󰅖"
                        font.family: root.fontMono; font.pixelSize: 13
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: closeHov; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // ── Scan sweep bar ────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.leftMargin: -16; Layout.rightMargin: -16
                height: 2; Layout.bottomMargin: 12
                visible: card.wifiOn; clip: true
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.10)
                }
                Rectangle {
                    id: scanSweep
                    width: parent.width * 0.38; height: parent.height
                    visible: card.isScanning
                    color: root.ColorPrimary
                    NumberAnimation on x {
                        from: -scanSweep.width; to: scanSweep.parent.width
                        duration: 1600; loops: Animation.Infinite
                        running: card.isScanning; easing.type: Easing.InOutSine
                    }
                }
            }

            // ── WiFi off placeholder ──────────────────────────────────────────
            Item {
                visible: !card.wifiOn
                Layout.fillWidth: true; height: 100
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 10
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 48; height: 48; radius: 14
                        color: Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.08)
                        Text {
                            anchors.centerIn: parent; text: "󰖪"
                            font.family: root.fontMono; font.pixelSize: 24
                            color: root.colorMuted; renderType: Text.NativeRendering
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter; text: "Wi-Fi is turned off"
                        font.family: root.fontSans; font.pixelSize: 12
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                }
            }

            // ── Network list ──────────────────────────────────────────────────
            Item {
                visible: card.wifiOn
                Layout.fillWidth: true
                implicitHeight: networkList.height

                ListView {
                    id: networkList
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: Math.min(contentHeight, 380)
                    model:  card.wifiDevice !== null ? card.wifiDevice.networks : null
                    spacing: 2; clip: true
                    interactive: contentHeight > height
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: netRow
                        required property var modelData

                        readonly property string netName:  modelData.name
                        readonly property bool   isConn:   modelData.connected
                        readonly property real   strength: modelData.signalStrength
                        readonly property bool   secured:  modelData.security !== WifiSecurityType.None
                        readonly property bool   known:    modelData.known

                        width: networkList.width
                        height: expanded ? expandedCol.implicitHeight + 24 : 52
                        radius: 14; clip: true

                        color: isConn
                               ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.10)
                               : (rowHov.containsMouse && !expanded
                                   ? Qt.rgba(root.colorOnSurface.r, root.colorOnSurface.g, root.colorOnSurface.b, 0.05)
                                   : "transparent")
                        Behavior on color  { ColorAnimation { duration: 120 } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                        property bool   expanded:     false
                        property string passwordInput: ""
                        property bool   showPassword:  false
                        property string connectStatus: "idle"
                        property string errorDetail:   ""
                        property bool   thisRowConnecting: connectStatus === "connecting"
                        property bool   isDisconnecting:   false
                        property bool   isForgetting:      false

                        Connections {
                            target: netRow.modelData
                            function onConnectionFailed(reason) {
                                if (netRow.connectStatus !== "connecting") return
                                if (reason === ConnectionFailReason.NoSecrets) {
                                    netRow.connectStatus = "needsPassword"
                                    netRow.errorDetail   = "Enter the Wi-Fi password to connect."
                                    netRow.expanded      = true
                                } else {
                                    netRow.connectStatus = "failed"
                                    netRow.errorDetail   = card.failReasonText(reason)
                                    Quickshell.execDetached([
                                        "notify-send", "-u", "critical", "-i", "network-wireless-offline",
                                        "Wi-Fi — " + netRow.netName, netRow.errorDetail
                                    ])
                                    clearFailTimer.restart()
                                }
                            }
                        }

                        onIsConnChanged: {
                            if (isConn && netRow.thisRowConnecting) {
                                netRow.connectStatus   = "connected"
                                netRow.errorDetail     = ""
                                netRow.isDisconnecting = false
                                collapseTimer.start()
                            }
                            if (!isConn && netRow.isDisconnecting) {
                                netRow.isDisconnecting = false
                                netRow.expanded        = false
                            }
                        }

                        Timer { id: collapseTimer;  interval: 1000; repeat: false
                            onTriggered: netRow.expanded = false }
                        Timer { id: clearFailTimer; interval: 8000; repeat: false
                            onTriggered: { netRow.connectStatus = "idle"; netRow.errorDetail = "" } }
                        Timer { id: forgetTimer;    interval: 4000; repeat: false
                            onTriggered: { netRow.isForgetting = false; netRow.expanded = false } }

                        function doConnect() {
                            netRow.errorDetail = ""
                            if (netRow.secured) {
                                if (netRow.passwordInput.length === 0) {
                                    if (netRow.known) {
                                        netRow.connectStatus = "connecting"
                                        netRow.modelData.connect()
                                    } else {
                                        netRow.connectStatus = "needsPassword"
                                        netRow.errorDetail   = "Enter the Wi-Fi password to connect."
                                    }
                                    clearFailTimer.restart()
                                    return
                                }
                                netRow.connectStatus = "connecting"
                                netRow.modelData.connectWithPsk(netRow.passwordInput)
                            } else {
                                netRow.connectStatus = "connecting"
                                netRow.modelData.connect()
                            }
                            clearFailTimer.restart()
                        }

                        ColumnLayout {
                            id: expandedCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 10

                            // ── Info row ──────────────────────────────────────
                            RowLayout {
                                Layout.fillWidth: true; spacing: 10

                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 20; height: 20
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            required property int index
                                            width: 3; radius: 1.5
                                            height: 5 + index * 3.5
                                            anchors.bottom: parent.bottom
                                            x: index * 5
                                            color: {
                                                const lit = (index + 1) <= card.signalBars(netRow.strength)
                                                if (netRow.connectStatus === "failed")
                                                    return lit ? root.colorError : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.25)
                                                if (netRow.thisRowConnecting || netRow.isConn)
                                                    return lit ? root.colorPrimary : Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.22)
                                                return lit ? root.colorMuted : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.22)
                                            }
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 1
                                    Text {
                                        Layout.fillWidth: true; text: netRow.netName
                                        font.family: root.fontSans; font.pixelSize: 13
                                        font.weight: netRow.isConn ? Font.SemiBold : Font.Normal
                                        color: netRow.connectStatus === "failed" ? root.colorError
                                               : netRow.isConn ? root.colorPrimary : root.colorOnSurface
                                        renderType: Text.NativeRendering; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        visible: text !== ""
                                        text: {
                                            if (netRow.thisRowConnecting)                 return "Connecting…"
                                            if (netRow.isDisconnecting)                   return "Disconnecting…"
                                            if (netRow.isForgetting)                      return "Forgetting…"
                                            if (netRow.connectStatus === "needsPassword") return "Password required"
                                            if (netRow.connectStatus === "failed")        return "Failed to connect"
                                            if (netRow.connectStatus === "connected")     return "Connected ✓"
                                            if (netRow.isConn)                            return "Connected"
                                            if (netRow.known)                             return "Saved"
                                            return ""
                                        }
                                        font.family: root.fontSans; font.pixelSize: 10
                                        color: netRow.connectStatus === "failed"
                                               ? root.colorError
                                               : Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.75)
                                        renderType: Text.NativeRendering
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                Rectangle {
                                    visible: netRow.secured; Layout.alignment: Qt.AlignVCenter
                                    width: 20; height: 20; radius: 6
                                    color: netRow.isConn
                                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.12)
                                           : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.10)
                                    Text {
                                        anchors.centerIn: parent; text: "󰌾"
                                        font.family: root.fontMono; font.pixelSize: 10
                                        color: netRow.isConn
                                               ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.70)
                                               : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.65)
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Rectangle {
                                    visible: netRow.isConn && !netRow.thisRowConnecting && !netRow.isDisconnecting
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 20; height: 20; radius: 6
                                    color: Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.15)
                                    Text {
                                        anchors.centerIn: parent; text: "󰄬"
                                        font.family: root.fontMono; font.pixelSize: 14
                                        color: root.colorPrimary; renderType: Text.NativeRendering
                                    }
                                }
                            }

                            // ── Connected: Forget + Disconnect ────────────────
                            RowLayout {
                                visible: netRow.expanded && netRow.isConn && !netRow.thisRowConnecting
                                Layout.fillWidth: true; spacing: 8

                                Rectangle {
                                    height: 30; radius: 8; implicitWidth: 80
                                    color: forgConnHov.containsMouse
                                           ? Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.18)
                                           : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Item {
                                        anchors.centerIn: parent
                                        width: forgInner.implicitWidth; height: 20
                                        Row {
                                            id: forgInner; anchors.centerIn: parent; spacing: 6
                                            SpinnerRing {
                                                visible: netRow.isForgetting
                                                ringColor: root.colorMuted; ringSize: 14
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Forget"
                                                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                                                color: root.colorMuted; renderType: Text.NativeRendering
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: forgConnHov; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        enabled: !netRow.isForgetting
                                        onClicked: {
                                            netRow.isForgetting = true; forgetTimer.start()
                                            netRow.modelData.forget()
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 30; radius: 8; implicitWidth: 110
                                    color: discHov.containsMouse
                                           ? Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.18)
                                           : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Item {
                                        anchors.centerIn: parent
                                        width: discInner.implicitWidth; height: 20
                                        Row {
                                            id: discInner; anchors.centerIn: parent; spacing: 6
                                            SpinnerRing {
                                                visible: netRow.isDisconnecting
                                                ringColor: root.colorError; ringSize: 14
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Disconnect"
                                                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                                                color: root.colorError; renderType: Text.NativeRendering
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: discHov; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        enabled: !netRow.isDisconnecting
                                        onClicked: {
                                            netRow.isDisconnecting = true
                                            netRow.modelData.disconnect()
                                        }
                                    }
                                }
                            }

                            // ── Not connected: password + connect ─────────────
                            ColumnLayout {
                                visible: netRow.expanded && !netRow.isConn
                                Layout.fillWidth: true; spacing: 8

                                Rectangle {
                                    visible: (netRow.secured && !netRow.known)
                                             || netRow.connectStatus === "needsPassword"
                                    Layout.fillWidth: true; height: 40; radius: 10
                                    color: Qt.rgba(root.colorOnSurface.r, root.colorOnSurface.g, root.colorOnSurface.b, 0.06)
                                    border.color: pwInput.activeFocus
                                                  ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.55)
                                                  : (netRow.connectStatus === "failed" || netRow.connectStatus === "needsPassword"
                                                     ? Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.40)
                                                     : Qt.rgba(root.colorOnSurface.r, root.colorOnSurface.g, root.colorOnSurface.b, 0.10))
                                    border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 } spacing: 6
                                        Text {
                                            text: "󰌾"; font.family: root.fontMono; font.pixelSize: 13
                                            color: pwInput.activeFocus ? root.colorPrimary : root.colorMuted
                                            renderType: Text.NativeRendering
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                        TextInput {
                                            id: pwInput
                                            Layout.fillWidth: true
                                            echoMode: netRow.showPassword ? TextInput.Normal : TextInput.Password
                                            color: root.colorOnSurface
                                            font.family: root.fontSans; font.pixelSize: 13
                                            selectionColor: Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.35)
                                            onTextChanged: netRow.passwordInput = text
                                            Keys.onReturnPressed: netRow.doConnect()
                                            Keys.onPressed: (event) => { event.accepted = true }
                                            Text {
                                                visible: pwInput.text.length === 0; text: "Password"
                                                anchors.verticalCenter: parent.verticalCenter
                                                font.family: root.fontSans; font.pixelSize: 13
                                                color: root.colorMuted; renderType: Text.NativeRendering
                                            }
                                        }
                                        Rectangle {
                                            width: 26; height: 26; radius: 7
                                            color: eyeHov.containsMouse
                                                   ? Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.15)
                                                   : "transparent"
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: netRow.showPassword ? "󰛑" : "󰛐"
                                                font.family: root.fontMono; font.pixelSize: 13
                                                color: root.colorMuted; renderType: Text.NativeRendering
                                            }
                                            MouseArea {
                                                id: eyeHov; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: netRow.showPassword = !netRow.showPassword
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: netRow.connectStatus === "failed" || netRow.connectStatus === "needsPassword"
                                    Layout.fillWidth: true
                                    implicitHeight: errorPanelCol.implicitHeight + 18
                                    radius: 10
                                    color: netRow.connectStatus === "needsPassword"
                                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.07)
                                           : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.07)
                                    border.color: netRow.connectStatus === "needsPassword"
                                                  ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.20)
                                                  : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.20)
                                    border.width: 1
                                    Behavior on color        { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    ColumnLayout {
                                        id: errorPanelCol
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                        spacing: 4
                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                Layout.alignment: Qt.AlignVCenter
                                                text: netRow.connectStatus === "needsPassword" ? "󰋗" : "󰅚"
                                                font.family: root.fontMono; font.pixelSize: 13
                                                color: netRow.connectStatus === "needsPassword" ? root.colorPrimary : root.colorError
                                                renderType: Text.NativeRendering
                                            }
                                            Text {
                                                Layout.alignment: Qt.AlignVCenter
                                                text: netRow.connectStatus === "needsPassword" ? "Password required" : "Connection failed"
                                                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.SemiBold
                                                color: netRow.connectStatus === "needsPassword" ? root.colorPrimary : root.colorError
                                                renderType: Text.NativeRendering
                                            }
                                        }
                                        Text {
                                            visible: netRow.errorDetail.length > 0; text: netRow.errorDetail
                                            font.family: root.fontSans; font.pixelSize: 11
                                            color: netRow.connectStatus === "needsPassword"
                                                   ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.75)
                                                   : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.80)
                                            renderType: Text.NativeRendering; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        RowLayout {
                                            visible: netRow.connectStatus === "failed"
                                            spacing: 6; Layout.topMargin: 2
                                            Rectangle {
                                                height: 24; radius: 6; implicitWidth: tryAgainLbl.implicitWidth + 16
                                                color: tryAgainHov.containsMouse
                                                       ? Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.20)
                                                       : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.10)
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text { id: tryAgainLbl; anchors.centerIn: parent; text: "Try again"
                                                    font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                                    color: root.colorError; renderType: Text.NativeRendering }
                                                MouseArea { id: tryAgainHov; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: { netRow.connectStatus = "idle"; netRow.errorDetail = ""
                                                        pwInput.text = ""; netRow.passwordInput = ""; clearFailTimer.stop() } }
                                            }
                                            Rectangle {
                                                visible: netRow.known; height: 24; radius: 6
                                                implicitWidth: forgetErrLbl.implicitWidth + 16
                                                color: forgetErrHov.containsMouse
                                                       ? Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.20)
                                                       : Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.10)
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text { id: forgetErrLbl; anchors.centerIn: parent; text: "Forget network"
                                                    font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                                                    color: root.colorError; renderType: Text.NativeRendering }
                                                MouseArea { id: forgetErrHov; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: { netRow.modelData.forget(); netRow.connectStatus = "idle"
                                                        netRow.errorDetail = ""; netRow.expanded = false } }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    visible: !netRow.thisRowConnecting

                                    Rectangle {
                                        visible: netRow.known && netRow.connectStatus !== "failed"
                                        height: 30; radius: 8; implicitWidth: 70
                                        color: forgetIdleHov.containsMouse
                                               ? Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.15)
                                               : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Row {
                                            anchors.centerIn: parent; spacing: 5
                                            SpinnerRing {
                                                visible: netRow.isForgetting
                                                ringColor: root.colorMuted; ringSize: 13
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text { text: "Forget"
                                                font.family: root.fontSans; font.pixelSize: 12
                                                color: root.colorMuted; renderType: Text.NativeRendering
                                                anchors.verticalCenter: parent.verticalCenter }
                                        }
                                        MouseArea { id: forgetIdleHov; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor; enabled: !netRow.isForgetting
                                            onClicked: { netRow.isForgetting = true; forgetTimer.start()
                                                netRow.modelData.forget(); netRow.expanded = false } }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        height: 30; radius: 8; implicitWidth: cancelLbl.implicitWidth + 20
                                        color: cancelHov.containsMouse
                                               ? Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.15)
                                               : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { id: cancelLbl; anchors.centerIn: parent; text: "Cancel"
                                            font.family: root.fontSans; font.pixelSize: 12
                                            color: root.colorMuted; renderType: Text.NativeRendering }
                                        MouseArea { id: cancelHov; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { netRow.expanded = false; netRow.passwordInput = ""
                                                netRow.connectStatus = "idle"; netRow.errorDetail = ""
                                                netRow.showPassword = false; pwInput.text = "" } }
                                    }

                                    Rectangle {
                                        height: 30; radius: 8; implicitWidth: 90
                                        color: connectBtnHov.containsMouse
                                               ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.80)
                                               : root.colorPrimary
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Row {
                                            anchors.centerIn: parent; spacing: 6
                                            SpinnerRing {
                                                visible: netRow.thisRowConnecting
                                                ringColor: Colors.md3.on_primary; ringSize: 14
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text { text: "Connect"
                                                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                                                color: Colors.md3.on_primary; renderType: Text.NativeRendering
                                                anchors.verticalCenter: parent.verticalCenter }
                                        }
                                        MouseArea { id: connectBtnHov; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: netRow.doConnect() }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowHov; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1
                            onClicked: {
                                if (!netRow.expanded) {
                                    netRow.expanded      = true
                                    netRow.connectStatus = "idle"
                                    netRow.errorDetail   = ""
                                    netRow.showPassword  = false
                                    pwInput.text         = ""
                                    netRow.passwordInput = ""
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer ────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 1
                Layout.topMargin: 10; Layout.bottomMargin: 6
                color: Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.10)
            }

            RowLayout {
                Layout.fillWidth: true; Layout.bottomMargin: 4; spacing: 8
                Rectangle {
                    height: 28; radius: 8; implicitWidth: detailsLbl.implicitWidth + 18
                    color: detailsHov.containsMouse ? root.chipHoverColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { id: detailsLbl; anchors.centerIn: parent; text: "Details"
                        font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                        color: root.colorPrimary; renderType: Text.NativeRendering }
                    MouseArea { id: detailsHov; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    height: 28; radius: 8; implicitWidth: doneLbl.implicitWidth + 18
                    color: doneHov.containsMouse ? root.chipHoverColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { id: doneLbl; anchors.centerIn: parent; text: "Done"
                        font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                        color: root.colorPrimary; renderType: Text.NativeRendering }
                    MouseArea { id: doneHov; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }
            }
        }
    }

    function open()  { root.visible = true  }
    function close() { root.visible = false }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick
import "."

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: Colors.md3.surface

    property int  cpuUsage: 0
    property int  ramUsage: 0
    property int  gpuUsage: 0
    property real lastCpuTotal: 0
    property real lastCpuIdle: 0

    property int brightnessVal: 50
    property int brightnessMax: 100

    // ── Pipewire binding — required for volume/mute to work ───────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property var  pwSink:  Pipewire.defaultAudioSink
    property var  pwAudio: pwSink ? pwSink.audio : null
    property real volPct:  pwAudio ? Math.round(pwAudio.volume * 100) : 0
    property bool volMuted: pwAudio ? pwAudio.muted : false

    // ── Processes ─────────────────────────────────────────────────
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p     = data.trim().split(/\s+/)
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (bar.lastCpuTotal > 0) {
                    var dt = total - bar.lastCpuTotal
                    var di = idle  - bar.lastCpuIdle
                    bar.cpuUsage = Math.round(100 * (1 - di / dt))
                }
                bar.lastCpuTotal = total
                bar.lastCpuIdle  = idle
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used  = parseInt(parts[2]) || 0
                bar.ramUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                bar.gpuUsage = parseInt(data.trim()) || 0
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: brightnessGetProc
        command: ["sh", "-c", "brightnessctl get"]
        stdout: SplitParser {
            onRead: data => { if (data.trim()) bar.brightnessVal = parseInt(data.trim()) || 0 }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: brightnessMaxProc
        command: ["sh", "-c", "brightnessctl max"]
        stdout: SplitParser {
            onRead: data => { if (data.trim()) bar.brightnessMax = parseInt(data.trim()) || 100 }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: brightnessSetProc
        property int targetVal: 0
        command: ["brightnessctl", "set", brightnessSetProc.targetVal.toString()]
        onRunningChanged: if (!running) brightnessGetProc.running = true
    }

    Process {
        id: nmtuiProc
        command: ["kitty", "-e", "nmtui"]
    }

    Process {
        id: bluemanProc
        command: ["blueman-manager"]
      }

Process {
    id: pwvucontrolProc
    command: ["pavucontrol"]
}

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
            gpuProc.running = true
        }
    }

    // ── Calendar popup ────────────────────────────────────────────
    PopupWindow {
        id: calendarPopup
        color: "transparent"
        visible: false
        anchor {
            window: bar
            rect.x: (bar.width - 280) / 2
            rect.y: bar.implicitHeight + 4
            rect.width: 280
            rect.height: 1
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
        }
        Calendar { id: cal; anchors.fill: parent }
        implicitWidth: 280
        implicitHeight: cal.height
    }

    // ── Battery popup ─────────────────────────────────────────────
    PopupWindow {
        id: batteryPopupWindow
        color: "transparent"
        visible: false
        anchor {
            window: bar
            rect.x: bar.width - 280 - 8
            rect.y: bar.implicitHeight + 4
            rect.width: 280
            rect.height: 1
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
        }
        Battery { id: bat; anchors.fill: parent }
        implicitWidth: 280
        implicitHeight: bat.height
      }

PopupWindow {
    id: playerPopupWindow
    color: "transparent"
    visible: false
    anchor {
        window: bar
      rect.x: (bar.width - 280) / 8
            rect.y: bar.implicitHeight + 4
        rect.width: 380
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }
    Player { id: playerWidget; anchors.fill: parent }
    implicitWidth: 480
    implicitHeight: playerWidget.height
}

    // ── Bar content ───────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        // ── Left — logo + workspaces ──────────────────────────────
        Row {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 6

            Rectangle {
                width: 36; height: 28; radius: 14
                color: Colors.md3.surface
                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 26
                    color: Colors.md3.on_surface
                }
            }

            Rectangle {
                height: 28
                width: workspaceRow.width + 8
                radius: 14
                color: Colors.md3.surface

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 9
                        Rectangle {
                            required property int index
                            property int  wsId:     index + 1
                            property bool isActive: Hyprland.focusedWorkspace
                                                    && Hyprland.focusedWorkspace.id === wsId
                            width:  isActive ? 28 : 22
                            height: 22
                            radius: 11
                            color:  isActive ? Colors.md3.primary : "transparent"

                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation  { duration: 200; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: wsId
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 13
                                color: parent.isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                            }
                        }
                    }
                }
              }

// ── Media pill ────────────────────────────────────────────
Rectangle {
    id: mediaPill
    height: 28
    width: mediaRow.width + 16
    radius: 14
    color: playerPopupWindow.visible ? Colors.md3.surface_container_high : Colors.md3.surface
    visible: Mpris.players.values.length > 0
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                var p = Mpris.players.values[0]
                if (!p) return ""
                return p.isPlaying ? "" : ""
            }
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 20
            color: Colors.md3.primary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                var p = Mpris.players.values[0]
                if (!p) return ""
                var title = p.trackTitle || ""
                return title.length > 32 ? title.substring(0, 32) + "…" : title
            }
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 13
            color: Colors.md3.primary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: playerPopupWindow.visible = !playerPopupWindow.visible
    }
}
        }

        // ── Center — clock ────────────────────────────────────────
        Rectangle {
            id: clockPill
            anchors.centerIn: parent
            height: 28
            width: clockRow.width + 20
            radius: 14
            color: calendarPopup.visible ? Colors.md3.surface_container_high : Colors.md3.surface
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    id: timeText
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    color: Colors.md3.on_surface
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    color: Colors.md3.outline_variant
                }
                Text {
                    id: dateText
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 12
                    color: Colors.md3.on_surface_variant
                }
            }

            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    var now    = new Date()
                    timeText.text = Qt.formatTime(now, "hh:mm AP")
                    var days   = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                    var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
                    var day    = String(now.getDate()).padStart(2, "0")
                    dateText.text = days[now.getDay()] + ", " + day + " " + months[now.getMonth()]
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarPopup.visible = !calendarPopup.visible
            }
        }

        // ── Right pills ───────────────────────────────────────────
        Row {
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 6

            // ── Stats ─────────────────────────────────────────────
            Rectangle {
                height: 28
                width: statsRow.width + 16
                radius: 14
                color: Colors.md3.surface

                Row {
                    id: statsRow
                    anchors.centerIn: parent
                    spacing: 12

                    Row {
                        spacing: 4; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 20; color: Colors.md3.primary }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: bar.cpuUsage; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13; color: Colors.md3.on_surface }
                    }
                    Row {
                        spacing: 4; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰓅"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 20; color: Colors.md3.primary }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: bar.gpuUsage; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13; color: Colors.md3.on_surface }
                    }
                    Row {
                        spacing: 4; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 20; color: Colors.md3.primary }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: bar.ramUsage; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13; color: Colors.md3.on_surface }
                    }
                }
            }

            // ── Wifi ──────────────────────────────────────────────
            Item {
                height: 28
                width: wifiPillRect.width

                Repeater {
                    id: deviceRep
                    model: Networking.devices
                    delegate: Item {
                        visible: false
                        required property var modelData
                        property string connectedSsid: networkRep.ssid
                        Repeater {
                            id: networkRep
                            model: modelData.type === DeviceType.Wifi ? modelData.networks : null
                            property string ssid: ""
                            delegate: Item {
                                visible: false
                                required property var modelData
                                Component.onCompleted: if (modelData.connected) networkRep.ssid = modelData.name
                                onModelDataChanged:    if (modelData.connected) networkRep.ssid = modelData.name
                                                       else if (networkRep.ssid === modelData.name) networkRep.ssid = ""
                            }
                        }
                    }
                }

                property bool   wifiConnected: Networking.connectivity === NetworkConnectivity.Full
                                            || Networking.connectivity === NetworkConnectivity.Limited
                property string wifiSsid: {
                    for (var i = 0; i < deviceRep.count; i++) {
                        var s = deviceRep.itemAt(i).connectedSsid
                        if (s !== "") return s
                    }
                    return ""
                }

                Rectangle {
                    id: wifiPillRect
                    height: 28
                    width: wifiRow.width + 16
                    radius: 14
                    color: Colors.md3.surface
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Row {
                        id: wifiRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.parent.wifiConnected ? "󰤨" : "󰤭"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 20
                            color:   parent.parent.parent.wifiConnected ? Colors.md3.primary : Colors.md3.on_surface_variant
                            opacity: parent.parent.parent.wifiConnected ? 1.0 : 0.4
                            Behavior on color   { ColorAnimation  { duration: 200 } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.parent.wifiSsid
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 12
                            color: Colors.md3.primary
                            visible: parent.parent.parent.wifiConnected && parent.parent.parent.wifiSsid !== ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: nmtuiProc.running = true
                    }
                }
            }

            // ── Bluetooth ─────────────────────────────────────────
            Item {
                height: 28
                width: btPillRect.width

                Repeater {
                    id: btDeviceRep
                    model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
                    delegate: Item {
                        visible: false
                        required property var modelData
                        property bool   isConnected: modelData.connected
                        property string deviceName:  modelData.name
                    }
                }

                property bool   btEnabled: Bluetooth.defaultAdapter !== null
                                        && Bluetooth.defaultAdapter.enabled
                property bool   btConnected: {
                    for (var i = 0; i < btDeviceRep.count; i++)
                        if (btDeviceRep.itemAt(i).isConnected) return true
                    return false
                }
                property string btDeviceName: {
                    for (var i = 0; i < btDeviceRep.count; i++) {
                        var item = btDeviceRep.itemAt(i)
                        if (item.isConnected) return item.deviceName
                    }
                    return ""
                }

                Rectangle {
                    id: btPillRect
                    height: 28
                    width: btRow.width + 16
                    radius: 14
                    color: Colors.md3.surface
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Row {
                        id: btRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.parent.btConnected ? "󰂱"
                                : parent.parent.parent.btEnabled   ? "󰂯"
                                :                                    "󰂲"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 18
                            color:   parent.parent.parent.btConnected ? Colors.md3.primary : Colors.md3.on_surface_variant
                            opacity: parent.parent.parent.btEnabled ? 1.0 : 0.4
                            Behavior on color   { ColorAnimation  { duration: 200 } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluemanProc.running = true
                    }
                }
            }

            // ── Brightness ────────────────────────────────────────
            Rectangle {
                id: brightnessPill
                height: 28
                width: brightnessRow.width + 16
                radius: 14
                color: Colors.md3.surface

                property int brightPct: bar.brightnessMax > 0
                    ? Math.round(bar.brightnessVal * 100 / bar.brightnessMax)
                    : 0

                Row {
                    id: brightnessRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            var p = brightnessPill.brightPct
                            if (p <= 0)  return "󰃞"
                            if (p <= 25) return "󰃟"
                            if (p <= 50) return "󰃠"
                            if (p <= 75) return "󰃡"
                            return "󰃠"
                        }
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 20
                        color: Colors.md3.on_surface
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: brightnessPill.brightPct
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                        color: Colors.md3.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onWheel: wheel => {
                        var step = Math.round(bar.brightnessMax * 0.05)
                        var next = bar.brightnessVal + (wheel.angleDelta.y > 0 ? step : -step)
                        next = Math.max(1, Math.min(bar.brightnessMax, next))
                        brightnessSetProc.targetVal = next
                        brightnessSetProc.running   = true
                    }
                }
              }

// ── Volume ────────────────────────────────────────────────────────
Rectangle {
    id: volumePill
    height: 28
    width: volumeRow.width + 16
    radius: 14
    color: Colors.md3.surface

    Timer {
        id: scrollDebounce
        interval: 50
        repeat: false
    }

    Row {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (bar.volMuted || bar.volPct === 0) return "󰝟"
                if (bar.volPct <= 33) return "󰕿"
                if (bar.volPct <= 66) return "󰖀"
                return "󰕾"
            }
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 18
            color:   bar.volMuted ? Colors.md3.on_surface_variant : Colors.md3.on_surface
            opacity: bar.volMuted ? 0.5 : 1.0
            Behavior on color   { ColorAnimation  { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.volPct
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 13
            color:   bar.volMuted ? Colors.md3.on_surface_variant : Colors.md3.on_surface
            opacity: bar.volMuted ? 0.5 : 1.0
            Behavior on color   { ColorAnimation  { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

// in volumePill MouseArea
MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: pwvucontrolProc.running = true
    onWheel: wheel => {
        if (!bar.pwAudio || scrollDebounce.running) return
        scrollDebounce.start()
        var direction = wheel.angleDelta.y > 0 ? 1 : -1
        bar.pwAudio.volume = Math.max(0.0, Math.min(1.0, bar.pwAudio.volume + direction * 0.05))
    }
}
}

                

            // ── Battery ───────────────────────────────────────────
            Rectangle {
                id: batteryPill
                height: 28
                width: batteryRow.width + 16
                radius: 14
                color: batteryPopupWindow.visible ? Colors.md3.surface_container_high : Colors.md3.surface
                visible: UPower.displayDevice.isLaptopBattery
                Behavior on color { ColorAnimation { duration: 150 } }

                property int pct: Math.round(UPower.displayDevice.percentage * 100)

                Row {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            var p = batteryPill.pct
                            if (!UPower.onBattery) {
                                if (p >= 100) return "󰂅"
                                if (p >= 90)  return "󰂄"
                                if (p >= 80)  return "󰂋"
                                if (p >= 60)  return "󰂊"
                                if (p >= 40)  return "󰂉"
                                if (p >= 20)  return "󰂈"
                                return "󰂇"
                            }
                            if (p <= 10) return "󰁺"
                            if (p <= 20) return "󰁻"
                            if (p <= 30) return "󰁼"
                            if (p <= 40) return "󰁽"
                            if (p <= 50) return "󰁾"
                            if (p <= 60) return "󰁿"
                            if (p <= 70) return "󰂀"
                            if (p <= 80) return "󰂁"
                            if (p <= 90) return "󰂂"
                            return "󰁹"
                        }
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 15
                        color: Colors.md3.on_surface
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: batteryPill.pct + "%"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                        color: Colors.md3.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: batteryPopupWindow.visible = !batteryPopupWindow.visible
                }
            }
        }
    }
}

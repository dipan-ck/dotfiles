import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick
import "."

Rectangle {
    id: batteryPopup
    width: 260
    height: col.height + 40
    radius: 18
    color: Colors.md3.surface
    border.width: 1
    border.color: Colors.md3.outline_variant

    Process {
        id: notifyProc
        property string message: ""
        command: ["notify-send", "-i", "battery", "Power Profile", notifyProc.message]
    }

    Column {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 10

        // ── Header row ────────────────────────────────────────────
        Row {
            width: parent.width
            height: 48
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var pct = Math.round(UPower.displayDevice.percentage * 100)
                    if (!UPower.displayDevice.isLaptopBattery) return "󰂑"
                    if (UPower.onBattery) {
                        if (pct <= 10) return "󰁺"
                        if (pct <= 20) return "󰁻"
                        if (pct <= 30) return "󰁼"
                        if (pct <= 40) return "󰁽"
                        if (pct <= 50) return "󰁾"
                        if (pct <= 60) return "󰁿"
                        if (pct <= 70) return "󰂀"
                        if (pct <= 80) return "󰂁"
                        if (pct <= 90) return "󰂂"
                        return "󰁹"
                    } else {
                        if (pct >= 100) return "󰂅"
                        if (pct >= 90)  return "󰂄"
                        if (pct >= 80)  return "󰂋"
                        if (pct >= 60)  return "󰂊"
                        if (pct >= 40)  return "󰂉"
                        if (pct >= 20)  return "󰂈"
                        return "󰂇"
                    }
                }
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 30
                color: {
                    var pct = Math.round(UPower.displayDevice.percentage * 100)
                    if (!UPower.displayDevice.isLaptopBattery) return Colors.md3.on_surface_variant
                    if (pct <= 20 && UPower.onBattery) return Colors.md3.error
                    if (!UPower.onBattery) return Colors.md3.primary
                    return Colors.md3.on_surface
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: UPower.displayDevice.isLaptopBattery
                        ? Math.round(UPower.displayDevice.percentage * 100) + "%"
                        : "No Battery"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 17
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                }

                Text {
                    text: UPower.onBattery ? "On battery" : "Plugged in"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                }
            }
        }

        // ── Progress bar ──────────────────────────────────────────
        Rectangle {
            visible: UPower.displayDevice.isLaptopBattery
            width: parent.width
            height: 5
            radius: 3
            color: Colors.md3.surface_container_high

            Rectangle {
                width: parent.width * UPower.displayDevice.percentage
                height: parent.height
                radius: parent.radius
                color: {
                    var pct = Math.round(UPower.displayDevice.percentage * 100)
                    if (pct <= 20 && UPower.onBattery) return Colors.md3.error
                    if (!UPower.onBattery) return Colors.md3.primary
                    return Colors.md3.secondary
                }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // ── Time remaining ────────────────────────────────────────
        Rectangle {
            visible: UPower.displayDevice.isLaptopBattery
            width: parent.width
            height: 52
            radius: 12
            color: Colors.md3.surface_container_high

            Row {
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; margins: 14 }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: UPower.onBattery ? "󱑿" : "󰚥"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 20
                    color: Colors.md3.on_surface_variant
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: UPower.onBattery ? "Time remaining" : "Until fully charged"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        color: Colors.md3.on_surface_variant
                    }

                    Text {
                        text: {
                            function fmt(s) {
                                if (s <= 0) return UPower.onBattery ? "Calculating…" : "Fully charged"
                                var h = Math.floor(s / 3600)
                                var m = Math.floor((s % 3600) / 60)
                                var parts = []
                                if (h > 0) parts.push(h + "h")
                                if (m > 0) parts.push(m + "m")
                                return parts.join(" ") || "< 1m"
                            }
                            return UPower.onBattery
                                ? fmt(UPower.displayDevice.timeToEmpty)
                                : fmt(UPower.displayDevice.timeToFull)
                        }
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface
                    }
                }
            }
        }

        // ── Divider ───────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 1
            color: Colors.md3.outline_variant
            opacity: 0.5
        }

        // ── Power profile label ───────────────────────────────────
        Text {
            text: "Power Profile"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 10
            color: Colors.md3.on_surface_variant
            leftPadding: 2
        }

        // ── Profile buttons ───────────────────────────────────────
        Row {
            width: parent.width
            spacing: 6

            Repeater {
                model: [
                    { label: "󰌪", name: "Saver",       value: 0, icon: "🍃" },
                    { label: "󰾅", name: "Balanced",    value: 1, icon: "⚖️"  },
                    { label: "󰓅", name: "Performance", value: 2, icon: "🚀" }
                ]

                Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 3
                    height: 44
                    radius: 10
                    color: PowerProfiles.profile === modelData.value
                        ? Colors.md3.primary
                        : Colors.md3.surface_container
                    border.width: PowerProfiles.profile === modelData.value ? 0 : 0
                    border.color: Colors.md3.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 16
                            color: PowerProfiles.profile === modelData.value
                                ? Colors.md3.on_primary
                                : Colors.md3.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 9
                            color: PowerProfiles.profile === modelData.value
                                ? Colors.md3.on_primary
                                : Colors.md3.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            PowerProfiles.profile = modelData.value
                            notifyProc.message = modelData.icon + " Switched to " + modelData.name
                            notifyProc.running = true
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import ".."

PopupWindow {
    id: root
    width: 280
    implicitHeight: mainCol.implicitHeight + 32
    color: "transparent"

    readonly property var  bat:      UPower.displayDevice
    readonly property real pct:      bat.percentage * 100
    // onBattery = true means discharging; false means on AC (charging or full)
    readonly property bool charging: !UPower.onBattery
    readonly property bool full:     bat.state === UPowerDeviceState.FullyCharged
    readonly property bool low:      pct <= 20 && UPower.onBattery

    function batteryIcon() {
        if (full || pct >= 100) return "󰂅"
        if (charging) {
            if (pct >= 90) return "󰂋"
            if (pct >= 80) return "󰂊"
            if (pct >= 70) return "󰂉"
            if (pct >= 60) return "󰂈"
            if (pct >= 50) return "󰂇"
            if (pct >= 40) return "󰂆"
            if (pct >= 30) return "󰂅"
            if (pct >= 20) return "󰂄"
            if (pct >= 10) return "󰢜"
            return "󰢟"
        }
        if (pct >= 90) return "󰂂"
        if (pct >= 80) return "󰂁"
        if (pct >= 70) return "󰂀"
        if (pct >= 60) return "󱊢"
        if (pct >= 50) return "󰁾"
        if (pct >= 40) return "󰁽"
        if (pct >= 30) return "󰁼"
        if (pct >= 20) return "󰁻"
        if (pct >= 10) return "󰁺"
        return "󰂎"
    }

    function stateLabel() {
        if (full)     return "Fully charged"
        if (charging) return "Charging"
        return "Discharging"
    }

    function formatTime(secs) {
        if (secs <= 0) return "—"
        var h = Math.floor(secs / 3600)
        var m = Math.floor((secs % 3600) / 60)
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    Rectangle {
        anchors.fill: parent
        radius:       12
        color:        Colors.md3.surface_container_low
        border.color: Colors.md3.outline_variant
        border.width: 0

        ColumnLayout {
            id: mainCol
            anchors.fill:    parent
            anchors.margins: 16
            spacing:         12

            // ── Header ────────────────────────────────────────────
            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text:           root.batteryIcon()
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    color:          root.low ? Colors.md3.error : Colors.md3.primary
                }
                Text {
                    text:           "Battery"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 14
                    font.weight:    Font.Medium
                    color:          Colors.md3.on_surface
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           Math.round(root.pct) + "%"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 14
                    font.weight:    Font.Bold
                    color:          root.low ? Colors.md3.error : Colors.md3.primary
                }
            }

            Rectangle {
                height:           1
                Layout.fillWidth: true
                color:            Colors.md3.outline_variant
                opacity:          0.5
            }

            // ── Status ────────────────────────────────────────────
            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text:           root.charging ? "󰚥" : (root.full ? "󰂅" : "󰚦")
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color:          Colors.md3.on_surface_variant
                }
                Text {
                    text:           "Status:"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    color:          Colors.md3.on_surface_variant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           root.stateLabel()
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    color:          Colors.md3.on_surface
                }
            }

            // ── Time remaining ────────────────────────────────────
            RowLayout {
                visible: (root.charging && root.bat.timeToFull > 0) ||
                         (!root.charging && !root.full && root.bat.timeToEmpty > 0)
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text:           root.charging ? "󰄉" : "󰅐"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color:          Colors.md3.on_surface_variant
                }
                Text {
                    text:           root.charging ? "Time to full:" : "Time to empty:"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    color:          Colors.md3.on_surface_variant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           root.charging
                                    ? root.formatTime(root.bat.timeToFull)
                                    : root.formatTime(root.bat.timeToEmpty)
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    color:          Colors.md3.on_surface
                }
            }

            // ── Wattage ───────────────────────────────────────────
            RowLayout {
                visible: root.bat.changeRate !== 0
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text:           "󱐋"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color:          Colors.md3.on_surface_variant
                }
                Text {
                    text:           root.charging ? "Charging at:" : "Discharging at:"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    color:          Colors.md3.on_surface_variant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           Math.abs(root.bat.changeRate).toFixed(1) + " W"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    color:          Colors.md3.on_surface
                }
            }

            // ── Health ────────────────────────────────────────────
            RowLayout {
                visible: root.bat.healthSupported
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text:           root.bat.healthPercentage > 80 ? "󰪜" :
                                    root.bat.healthPercentage > 50 ? "󰪛" : "󰪚"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color:          root.bat.healthPercentage > 80 ? Colors.md3.primary :
                                    root.bat.healthPercentage > 50 ? Colors.md3.secondary : Colors.md3.error
                }
                Text {
                    text:           "Health:"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    color:          Colors.md3.on_surface_variant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           root.bat.healthPercentage.toFixed(1) + "%"
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    color:          Colors.md3.on_surface
                }
            }

            // ── Divider ───────────────────────────────────────────
            Rectangle {
                height:           1
                Layout.fillWidth: true
                color:            Colors.md3.outline_variant
                opacity:          0.5
            }

            // ── Power profile switcher ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing:          6

                Repeater {
                    model: [
                        { profile: PowerProfile.PowerSaver,  icon: "󰌪", label: "Saver"    },
                        { profile: PowerProfile.Balanced,    icon: "󰊚", label: "Balanced"  },
                        { profile: PowerProfile.Performance, icon: "󱐋", label: "Boost"    }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height:           42
                        radius:           8

                        readonly property bool isActive: PowerProfiles.profile === modelData.profile

                        color:        isActive ? Colors.md3.primary : Colors.md3.surface_container
                        border.color: isActive ? Qt.darker(Colors.md3.primary, 1.15) : Colors.md3.outline_variant
                        border.width: 0

                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Column {
                            anchors.centerIn: parent
                            spacing:          2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           modelData.icon
                                font.family:    "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color:          isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                                renderType:     Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           modelData.label
                                font.family:    "Google Sans Flex"
                                font.pixelSize: 10
                                font.weight:    Font.Medium
                                color:          isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                                renderType:     Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    PowerProfiles.profile = modelData.profile
                        }
                    }
                }
            }
        }
    }
}

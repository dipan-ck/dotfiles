import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."
import "../Popups"
import "../Services"

Scope {
    id: barScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            height: 32
            color:  "transparent"

            // ── design tokens ─────────────────────────────────────────
            readonly property int   pillHeight:    28
            readonly property int   pillRadius:    200
            readonly property int   pillSpacing:   8
            readonly property int   barMargin:     12

            readonly property color colorSurface:  Colors.md3.surface_container_low
            readonly property color colorAccent:   Colors.md3.primary
            readonly property color colorOnAccent: Colors.md3.on_primary
            readonly property color colorText:     Colors.md3.on_surface
            readonly property color colorInactive: Colors.md3.on_surface_variant
            readonly property color colorWarning:  Colors.md3.error

            // ── root layout ───────────────────────────────────────────
            RowLayout {
                anchors {
                    fill:        parent
                    leftMargin:  bar.barMargin
                    rightMargin: bar.barMargin
                }
                spacing: 0

                // ── LEFT ─────────────────────────────────────────────
                Row {
                    spacing:          bar.pillSpacing
                    Layout.alignment: Qt.AlignVCenter

                    ArchLogo {
                        pillHeight:   bar.pillHeight
                        pillRadius:   bar.pillRadius
                        colorSurface: bar.colorSurface
                        colorAccent:  bar.colorAccent
                    }

                    TimePill {
                        pillHeight:        bar.pillHeight
                        pillRadius:        bar.pillRadius
                        colorSurface:      bar.colorSurface
                        colorText:         bar.colorText
                        windowContentItem: bar.contentItem
                        onClicked: (centerX, bottomY) => {
                            calendarPopup.anchor.rect.x = centerX - calendarPopup.width / 2
                            calendarPopup.anchor.rect.y = bottomY + 6
                            calendarPopup.visible = !calendarPopup.visible
                        }
                    }
                }

                // ── CENTRE ───────────────────────────────────────────
                Item {
                    Layout.fillWidth: true

                    Row {
                        anchors.centerIn: parent
                        spacing:          bar.pillSpacing

                        ResourcePill {
                            pillHeight:   bar.pillHeight
                            pillRadius:   bar.pillRadius
                            colorSurface: bar.colorSurface
                            colorText:    bar.colorText
                            colorAccent:  bar.colorAccent
                        }

                        WorkspacePill {
                            pillHeight:    bar.pillHeight
                            pillRadius:    bar.pillRadius
                            colorSurface:  bar.colorSurface
                            colorAccent:   bar.colorAccent
                            colorOnAccent: bar.colorOnAccent
                            colorText:     bar.colorText
                            colorInactive: bar.colorInactive
                        }

                        BatteryBrightnessPill {
                            pillHeight:        bar.pillHeight
                            pillRadius:        bar.pillRadius
                            colorSurface:      bar.colorSurface
                            colorText:         bar.colorText
                            colorAccent:       bar.colorAccent
                            colorOnAccent:     bar.colorOnAccent
                            colorInactive:     bar.colorInactive
                            colorWarning:      bar.colorWarning
                            windowContentItem: bar.contentItem
                            onBatteryClicked: (centerX, bottomY) => {
                                batteryPopup.anchor.rect.x = centerX - batteryPopup.width / 2
                                batteryPopup.anchor.rect.y = bottomY + 6
                                batteryPopup.visible = !batteryPopup.visible
                            }
                        }
                    }
                }

                // ── RIGHT ────────────────────────────────────────────
                Row {
                    spacing:          bar.pillSpacing
                    Layout.alignment: Qt.AlignVCenter

                    SystemTrayPill {
                        pillHeight:        bar.pillHeight
                        pillRadius:        bar.pillRadius
                        colorSurface:      bar.colorSurface
                        colorText:         bar.colorText
                        colorAccent:       bar.colorAccent
                        colorWarning:      bar.colorWarning
                        colorInactive:     bar.colorInactive
                        windowContentItem: bar.contentItem
                    }

                    WifiBluetoothPowerPill {
                        pillHeight:   bar.pillHeight
                        pillRadius:   bar.pillRadius
                        colorSurface: bar.colorSurface
                        colorText:    bar.colorText
                        colorPrimary: bar.colorAccent
                        colorDull:    bar.colorInactive
                        onClicked:      notificationPanel.toggle()
                    }
                }
            }

            // ── popups & panels ───────────────────────────────────────
            BatteryPopup {
                id:            batteryPopup
                visible:       false
                anchor.window: bar
            }

            CalendarPopup {
                id:            calendarPopup
                visible:       false
                anchor.window: bar
            }

            NotificationPanel {
                id: notificationPanel
            }
        }
    }
}

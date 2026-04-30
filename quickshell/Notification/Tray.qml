import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../"
import "../Services"
import "."

Item {
    id: root

    property string fontSans:       "Google Sans Flex"
    property string fontMono:       "JetBrainsMono Nerd Font"
    property color  colorPrimary:   Colors.md3.primary
    property color  colorOnSurface: Colors.md3.on_surface
    property color  colorMuted:     Colors.md3.on_surface_variant
    property color  chipColor:      Colors.md3.surface_container
    property color  chipHover:      Colors.md3.surface_container_highest
    property color  errorColor:     Colors.md3.error

    // surface_container_high sits one step above surface_container —
    // used as the section card background so it reads as a distinct layer
    property color  sectionBg:      Colors.md3.surface_container_high

    property var trackedNotifs: NotificationService.server.trackedNotifications

    property int _tick: 0
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root._tick++ }

    Process {
        id: trayClipboard
        running: false
    }

    // ── Notification header card (top-anchored) ───────────────────
    Rectangle {
        id: notifHeader
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: headerRow.implicitHeight + 20
        radius: 16
        color: root.sectionBg

        RowLayout {
            id: headerRow
            anchors {
                left: parent.left; leftMargin: 14
                right: parent.right; rightMargin: 14
                verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.trackedNotifs.values.length === 0 ? "󰂚" : "󰂞"
                font.family: root.fontMono; font.pixelSize: 15
                color: root.trackedNotifs.values.length === 0
                       ? root.colorMuted : root.colorPrimary
                renderType: Text.NativeRendering
            }
            Text {
                property int cnt: root.trackedNotifs.values.length
                text: cnt === 0 ? "No notifications"
                                : cnt + " notification" + (cnt === 1 ? "" : "s")
                font.family: root.fontSans; font.pixelSize: 12; font.weight: Font.Medium
                color: root.colorOnSurface; renderType: Text.NativeRendering
                Layout.fillWidth: true
                leftPadding: 6
            }

            // Clear all — fixed container width, no overflow
            Item {
                id: clearContainer
                implicitWidth: 28
                implicitHeight: 28
                visible: root.trackedNotifs.values.length > 0
                // Grow with button but never past panel edge
                width:  clearBtn.width
                height: clearBtn.height
                clip: true

                Rectangle {
                    id: clearBtn
                    height: 28; radius: 14
                    // No width animation — instant expand/collapse as requested
                    width: clearHov.hovered
                           ? Math.min(clearLbl.implicitWidth + 24, 96)
                           : 28
                    color: clearHov.hovered
                           ? Qt.rgba(root.errorColor.r, root.errorColor.g, root.errorColor.b, 0.18)
                           : Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.10)
                    clip: true
                    // No Behavior on width — instant as requested

                    HoverHandler { id: clearHov }

                    Text {
                        id: clearLbl
                        anchors.centerIn: parent
                        // Always show the delete icon; label appears alongside on hover
                        text: "󰆴"
                        font.family: root.fontMono
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: clearHov.hovered ? root.errorColor : root.colorMuted
                        renderType: Text.NativeRendering
                        // No Behavior on color — instant
                    }

                    TapHandler { onTapped: NotificationService.clearAll() }
                }
            }
        }
    }


    // ── Notification list card (fills remaining space) ────────────
    Rectangle {
        anchors {
            top:    notifHeader.bottom;    topMargin:    8
            bottom: calendarSection.top;   bottomMargin: 8
            left:   parent.left
            right:  parent.right
        }
        radius: 16
        color: root.sectionBg
        clip: true

        // Empty state
        Item {
            anchors.fill: parent
            visible: root.trackedNotifs.values.length === 0

            ColumnLayout {
                anchors.centerIn: parent; spacing: 6
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂚"; font.family: root.fontMono; font.pixelSize: 26
                    color: root.colorMuted; renderType: Text.NativeRendering
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "You're all caught up"
                    font.family: root.fontSans; font.pixelSize: 11
                    color: root.colorMuted; renderType: Text.NativeRendering
                }
            }
        }

        // Scrollable list — padding inside the card
        Flickable {
            id: notifFlickable
            anchors {
                fill: parent
                topMargin: 8; bottomMargin: 8
                leftMargin: 8; rightMargin: 8
            }
            visible: root.trackedNotifs.values.length > 0
            contentWidth: width
            contentHeight: notifColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: notifColumn.implicitHeight > notifFlickable.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                width: 4
            }

            ColumnLayout {
                id: notifColumn
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.trackedNotifs.values.length
                    delegate: TrayItem {
                        required property int index
                        Layout.fillWidth: true

                        property var notif: root.trackedNotifs.values[index]

                        fontSans:       root.fontSans
                        fontMono:       root.fontMono
                        colorPrimary:   root.colorPrimary
                        colorOnSurface: root.colorOnSurface
                        colorMuted:     root.colorMuted
                        chipColor:      root.chipColor
                        chipHover:      root.chipHover
                        errorColor:     root.errorColor
                        notification:   notif
                        tick:           root._tick

                        onCopyRequested: {
                            var text = notif.summary
                            if (notif.body !== "") text += "\n" + notif.body
                            trayClipboard.command = ["sh", "-c",
                                "printf '%s' " + JSON.stringify(text) + " | wl-copy"]
                            trayClipboard.running = true
                        }
                        onDismissRequested: NotificationService.dismissTrayEntry(notif)
                    }
                }
            }
        }
    }
}

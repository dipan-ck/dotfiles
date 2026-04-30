import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import  "."

Rectangle {
    id: item

    property string fontSans:       "Google Sans Flex"
    property string fontMono:       "JetBrainsMono Nerd Font"
    property color  colorPrimary:   Colors.md3.primary
    property color  colorOnSurface: Colors.md3.on_surface
    property color  colorMuted:     Colors.md3.on_surface_variant
    property color  chipColor:      Colors.md3.surface_container
    property color  chipHover:      Colors.md3.surface_container_highest
    property color  errorColor:     Colors.md3.error
    property var    notification:   null
    property int    tick:           0

    signal dismissRequested()
    signal copyRequested()

    property bool expanded: false

    function relTime() {
        var _ = tick
        return storedTs > 0 ? timeFmt(storedTs) : ""
    }
    property real storedTs: 0
    Component.onCompleted: storedTs = Date.now()

    function timeFmt(ts) {
        var diff = Math.floor((Date.now() - ts) / 1000)
        if (diff < 60)    return "just now"
        if (diff < 3600)  return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        return Math.floor(diff / 86400) + "d ago"
    }

    function notifUrgency() {
        if (!notification) return 1
        var u = notification.urgency
        return (u === undefined || u === null) ? 1 : u
    }

    radius: 14
    color: headerHov.hovered && !expanded ? item.chipHover : item.chipColor
    Behavior on color { ColorAnimation { duration: 120 } }

    implicitHeight: itemCol.implicitHeight + 20
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    clip: true

    // NO accent bar — removed as requested

    ColumnLayout {
        id: itemCol
        anchors {
            left: parent.left; leftMargin: 12
            right: parent.right; rightMargin: 12
            top: parent.top; topMargin: 10
        }
        spacing: 0

        // ── Header row ────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight

            HoverHandler { id: headerHov }
            TapHandler   { onTapped: item.expanded = !item.expanded }

            RowLayout {
                id: headerRow
                anchors { left: parent.left; right: parent.right; top: parent.top }
                spacing: 8

                // Icon
                Item {
                    width: 34; height: 34

                    Image {
                        id: trayNotifImg
                        anchors.fill: parent
                        source: notification && notification.image !== "" ? notification.image : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: status === Image.Ready
                        layer.enabled: visible
                    }

                    IconImage {
                        id: trayAppIcon
                        anchors.fill: parent
                        source: notification ? notification.appIcon : ""
                        smooth: true
                        visible: !trayNotifImg.visible &&
                                 notification !== null &&
                                 notification.appIcon !== ""
                    }

                    Rectangle {
                        anchors.fill: parent; radius: 9
                        color: Qt.rgba(item.colorPrimary.r, item.colorPrimary.g,
                                       item.colorPrimary.b, 0.15)
                        visible: !trayNotifImg.visible && !trayAppIcon.visible

                        Text {
                            anchors.centerIn: parent; text: "󰂚"
                            font.family: item.fontMono; font.pixelSize: 18
                            color: item.colorPrimary; renderType: Text.NativeRendering
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2

                    Text {
                        text: notification ? notification.appName : ""
                        font.family: item.fontSans; font.pixelSize: 10; font.weight: Font.Medium
                        color: item.colorMuted; renderType: Text.NativeRendering
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        text: notification ? notification.summary : ""
                        font.family: item.fontSans; font.pixelSize: 12; font.weight: Font.SemiBold
                        color: item.colorOnSurface; renderType: Text.NativeRendering
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        visible: !item.expanded && notification && notification.body !== ""
                        text: notification ? notification.body : ""
                        font.family: item.fontSans; font.pixelSize: 11
                        color: item.colorMuted; renderType: Text.NativeRendering
                        elide: Text.ElideRight; maximumLineCount: 1
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignTop

                    Text {
                        text: item.relTime()
                        font.family: item.fontMono; font.pixelSize: 9
                        color: item.colorMuted; renderType: Text.NativeRendering
                    }

                    // Chevron — no animation on hover, just instant icon
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: chevHov.hovered
                               ? Qt.rgba(item.colorMuted.r, item.colorMuted.g,
                                         item.colorMuted.b, 0.20) : "transparent"
                        // No Behavior — instant color change as requested

                        HoverHandler { id: chevHov }

                        Text {
                            anchors.centerIn: parent
                            // Always show expand/collapse icon, no animation swap
                            text: item.expanded ? "󰅃" : "󰅀"
                            font.family: item.fontMono; font.pixelSize: 13
                            color: item.colorMuted; renderType: Text.NativeRendering
                        }

                        TapHandler {
                            onTapped: item.expanded = !item.expanded
                        }
                    }
                }
            }
        }

        // ── Expanded body + actions ───────────────────────────────
        ColumnLayout {
            visible: item.expanded
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(item.colorMuted.r, item.colorMuted.g,
                               item.colorMuted.b, 0.15)
            }

            Text {
                visible: notification && notification.body !== ""
                text: notification ? notification.body : ""
                font.family: item.fontSans; font.pixelSize: 11
                color: item.colorOnSurface; renderType: Text.NativeRendering
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Action buttons — distinct backgrounds
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Dismiss — error-tinted bg always, darker on hover
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: 10
                    color: dismissHov.hovered
                           ? Qt.rgba(item.errorColor.r, item.errorColor.g,
                                     item.errorColor.b, 0.28)
                           : Qt.rgba(item.errorColor.r, item.errorColor.g,
                                     item.errorColor.b, 0.12)

                    HoverHandler { id: dismissHov }

                    Text {
                        anchors.centerIn: parent; text: "Dismiss"
                        font.family: item.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                        color: item.errorColor
                        renderType: Text.NativeRendering
                    }

                    TapHandler { onTapped: item.dismissRequested() }
                }

                // Copy — primary-tinted bg always, darker on hover
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: 10
                    color: copyHov.hovered
                           ? Qt.rgba(item.colorPrimary.r, item.colorPrimary.g,
                                     item.colorPrimary.b, 0.28)
                           : Qt.rgba(item.colorPrimary.r, item.colorPrimary.g,
                                     item.colorPrimary.b, 0.12)

                    HoverHandler { id: copyHov }

                    Text {
                        anchors.centerIn: parent; text: "Copy"
                        font.family: item.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                        color: item.colorPrimary
                        renderType: Text.NativeRendering
                    }

                    TapHandler { onTapped: item.copyRequested() }
                }
            }

            Item { height: 2 }
        }
    }
}

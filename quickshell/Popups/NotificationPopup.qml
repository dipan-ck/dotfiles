import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import "../Services" as Services
import ".."

PanelWindow {
    id: root

    anchors { top: true; right: true }
    margins { top: 48; right: 14 }

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "notifications"
    exclusionMode:               ExclusionMode.Ignore

    width:   380
    height:  Math.min(stack.implicitHeight + 1, 640)
    color:   "transparent"
    visible: Services.NotificationService.activeNotifications.count > 0

    Process {
        id: clipProc
        running: false
    }

    Column {
        id: stack
        anchors { top: parent.top; right: parent.right }
        width: parent.width
        spacing: 10

        Repeater {
            model: Services.NotificationService.activeNotifications

            delegate: NotifCard {
                required property var modelData

                nid:          modelData.nid
                appName:      modelData.appName
                appIcon:      modelData.appIcon
                notifImage:   modelData.image
                summary:      modelData.summary
                body:         modelData.body
                urgency:      modelData.urgency
                duration:     modelData.duration
                notification: modelData.notification

                onDismissRequested: Services.NotificationService.dismissById(nid)
                onExpireRequested:  Services.NotificationService.expireById(nid)
                onCopyRequested: {
                    var t = summary
                    if (body !== "") t += "\n" + body
                    clipProc.command = ["sh", "-c",
                        "printf '%s' " + JSON.stringify(t) + " | wl-copy"]
                    clipProc.running = true
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    component NotifCard: Item {
        id: card

        property int    nid
        property string appName:    ""
        property string appIcon:    ""
        property string notifImage: ""
        property string summary:    ""
        property string body:       ""
        property int    urgency:    NotificationUrgency.Normal
        property int    duration:   6000
        property var    notification: null

        signal dismissRequested()
        signal expireRequested()
        signal copyRequested()

        property bool expanded:    false
        property real swipeX:      0
        property bool _alive:      false
        property bool _dismissing: false

        width:         parent.width
        implicitHeight: bubble.implicitHeight
        opacity:       _alive ? 1.0 : 0.0

        Component.onCompleted: _alive = true
        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        // Auto-expire
        Timer {
            interval: card.duration
            running:  card.duration > 0 && !drag.active && !card._dismissing
            repeat:   false
            onTriggered: {
                card._dismissing = true
                card.expireRequested()
            }
        }

        // Commit swipe-out
        Timer {
            id: swipeCommit
            interval: 300
            repeat:   false
            onTriggered: card.dismissRequested()
        }

        DragHandler {
            id: drag
            target:        null
            xAxis.enabled: true
            yAxis.enabled: false
            xAxis.minimum: 0
            xAxis.maximum: card.width * 2.2

            onTranslationChanged: card.swipeX = Math.max(0, translation.x)
            onActiveChanged: {
                if (!active) {
                    if (card.swipeX > card.width * 0.36) {
                        card.swipeX = card.width * 1.8
                        swipeCommit.start()
                    } else {
                        card.swipeX = 0
                    }
                }
            }
        }

        Rectangle {
            id: bubble
            width:          parent.width
            implicitHeight: contentCol.implicitHeight
            radius:         20
            clip:           true

            color: card.urgency === NotificationUrgency.Critical
                   ? Qt.rgba(Colors.md3.error_container.r,
                             Colors.md3.error_container.g,
                             Colors.md3.error_container.b, 0.18)
                   : Colors.md3.surface_container_low

            x:        card.swipeX
            opacity:  Math.max(0, 1.0 - card.swipeX / (card.width * 0.65))
            rotation: card.swipeX * 0.011

            Behavior on x        { enabled: !drag.active; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity  { enabled: !drag.active; NumberAnimation { duration: 300 } }
            Behavior on rotation { enabled: !drag.active; NumberAnimation { duration: 300 } }

            // Border ring
            Rectangle {
                anchors.fill: parent
                radius:       parent.radius
                color:        "transparent"
                border.width: 1
                border.color: card.urgency === NotificationUrgency.Critical
                              ? Qt.rgba(Colors.md3.error.r,
                                        Colors.md3.error.g,
                                        Colors.md3.error.b, 0.45)
                              : Qt.rgba(Colors.md3.outline_variant.r,
                                        Colors.md3.outline_variant.g,
                                        Colors.md3.outline_variant.b, 0.28)
                z: 20
            }

            // Critical left accent bar
            Rectangle {
                visible: card.urgency === NotificationUrgency.Critical
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width:  3
                radius: 2
                color:  Colors.md3.error
                z:      15
            }

            Column {
                id: contentCol
                width: parent.width

                // ── Header row ────────────────────────────────────────────
                Item {
                    width:  parent.width
                    height: 68

                    // ── Icon (36×36) ──────────────────────────────────────
                    // Priority: notifImage → appIcon (IconImage) → bell glyph
                    Item {
                        id: iconArea
                        width:  36
                        height: 36
                        anchors {
                            left:           parent.left
                            leftMargin:     16
                            verticalCenter: parent.verticalCenter
                        }

                        // 1. Notification image (profile pic / album art)
                        //    IconImage also has .status — Image.Ready means loaded OK
                        ClippingWrapperRectangle {
                            anchors.fill: parent
                            radius:       18
                            visible:      notifImg.status === Image.Ready

                            Image {
                                id: notifImg
                                anchors.fill: parent
                                source:       card.notifImage !== "" ? card.notifImage : ""
                                fillMode:     Image.PreserveAspectCrop
                                smooth:       true
                            }
                        }

                        // 2. App icon via IconImage — supports theme names + paths
                        //    Only shown when notifImage didn't load AND appIcon is set
                        //    IconImage.status works exactly like Image.status
                        ClippingWrapperRectangle {
                            anchors.fill: parent
                            radius:       6
                            visible:      notifImg.status !== Image.Ready &&
                                          card.appIcon !== "" &&
                                          appIconImg.status === Image.Ready

                            IconImage {
                                id:           appIconImg
                                anchors.fill: parent
                                source:       card.appIcon
                                smooth:       true
                            }
                        }

                        // 3. Bell glyph fallback — shown when both above failed/empty
                        Rectangle {
                            anchors.fill: parent
                            radius:       18
                            visible:      notifImg.status  !== Image.Ready &&
                                          (card.appIcon === "" ||
                                           appIconImg.status !== Image.Ready)
                            color:        Qt.rgba(Colors.md3.primary.r,
                                                  Colors.md3.primary.g,
                                                  Colors.md3.primary.b, 0.16)

                            Text {
                                anchors.centerIn: parent
                                text:        "󰂚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color:       Colors.md3.primary
                                renderType:  Text.NativeRendering
                            }
                        }
                    }

                    // ── Text block ────────────────────────────────────────
                    Column {
                        id: textBlock
                        anchors {
                            left:           iconArea.right
                            leftMargin:     12
                            right:          chevronBtn.left
                            rightMargin:    8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 3

                        // App name (small muted label)
                        Text {
                            text:             card.appName
                            visible:          card.appName !== ""
                            width:            parent.width
                            font.family:      "Google Sans Flex"
                            font.pixelSize:   11
                            color:            Colors.md3.on_surface_variant
                            opacity:          0.65
                            elide:            Text.ElideRight
                            maximumLineCount: 1
                            renderType:       Text.NativeRendering
                        }

                        // Summary
                        Text {
                            text:             card.summary !== "" ? card.summary : card.appName
                            width:            parent.width
                            font.family:      "Google Sans Flex"
                            font.pixelSize:   13
                            font.weight:      Font.SemiBold
                            color:            card.urgency === NotificationUrgency.Critical
                                              ? Colors.md3.error
                                              : Colors.md3.on_surface
                            elide:            Text.ElideRight
                            maximumLineCount: 1
                            renderType:       Text.NativeRendering
                        }

                        // Body preview (one line, only when collapsed)
                        Text {
                            text:             card.body
                            visible:          card.body !== "" && !card.expanded
                            width:            parent.width
                            font.family:      "Google Sans Flex"
                            font.pixelSize:   12
                            color:            Colors.md3.on_surface_variant
                            elide:            Text.ElideRight
                            maximumLineCount: 1
                            textFormat:       Text.PlainText
                            renderType:       Text.NativeRendering
                        }
                    }

                    // ── Expand chevron ────────────────────────────────────
                    Rectangle {
                        id: chevronBtn
                        anchors {
                            right:          parent.right
                            rightMargin:    14
                            verticalCenter: parent.verticalCenter
                        }
                        width:  28; height: 28
                        radius: 14
                        color:  chevronMa.containsMouse
                                ? Qt.rgba(Colors.md3.on_surface.r,
                                          Colors.md3.on_surface.g,
                                          Colors.md3.on_surface.b, 0.10)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text:        card.expanded ? "󰅃" : "󰅀"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color:       Colors.md3.on_surface_variant
                            renderType:  Text.NativeRendering
                        }

                        MouseArea {
                            id: chevronMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    card.expanded = !card.expanded
                        }
                    }
                }

                // ── Expanded section ──────────────────────────────────────
                Item {
                    width:          parent.width
                    implicitHeight: card.expanded ? expandCol.implicitHeight : 0
                    clip:           true

                    Behavior on implicitHeight {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    Column {
                        id: expandCol
                        width: parent.width

                        // Divider
                        Rectangle {
                            width:  parent.width - 32
                            height: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            color:  Qt.rgba(Colors.md3.outline_variant.r,
                                            Colors.md3.outline_variant.g,
                                            Colors.md3.outline_variant.b, 0.22)
                        }

                        // Spacer
                        Item { width: 1; height: 10 }

                        // Full body text
                        Text {
                            visible:          card.body !== ""
                            text:             card.body
                            width:            parent.width - 32
                            anchors.left:     parent.left
                            anchors.leftMargin: 16
                            font.family:      "Google Sans Flex"
                            font.pixelSize:   12
                            color:            Colors.md3.on_surface_variant
                            wrapMode:         Text.WordWrap
                            maximumLineCount: 6
                            textFormat:       Text.PlainText
                            renderType:       Text.NativeRendering
                        }

                        // Spacer before actions
                        Item {
                            visible: card.body !== ""
                            width:   1
                            height:  8
                        }

                        // App-provided action buttons
                        Item {
                            visible:  card.notification !== null &&
                                      card.notification.actions.length > 0
                            width:    parent.width - 32
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            height:   visible ? actionsRow.implicitHeight : 0

                            Row {
                                id: actionsRow
                                spacing: 8

                                Repeater {
                                    model: card.notification ? card.notification.actions : []
                                    delegate: Rectangle {
                                        required property var modelData

                                        height: 30
                                        width:  actLabel.implicitWidth + 24
                                        radius: 15
                                        color:  actMa.containsMouse
                                                ? Colors.md3.secondary_container
                                                : Qt.rgba(Colors.md3.secondary.r,
                                                          Colors.md3.secondary.g,
                                                          Colors.md3.secondary.b, 0.12)
                                        Behavior on color { ColorAnimation { duration: 110 } }

                                        Text {
                                            id: actLabel
                                            anchors.centerIn: parent
                                            text:           modelData.text
                                            font.family:    "Google Sans Flex"
                                            font.pixelSize: 12
                                            font.weight:    Font.Medium
                                            color:          Colors.md3.on_secondary_container
                                            renderType:     Text.NativeRendering
                                        }

                                        MouseArea {
                                            id: actMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape:  Qt.PointingHandCursor
                                            onClicked:    modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }

                        // Spacer before utility buttons
                        Item { width: 1; height: 10 }

                        // Copy + Dismiss row
                        Row {
                            anchors { left: parent.left; leftMargin: 16 }
                            spacing: 8

                            Rectangle {
                                height: 30
                                width:  cpRow.implicitWidth + 22
                                radius: 15
                                color:  cpMa.containsMouse
                                        ? Colors.md3.secondary_container
                                        : Qt.rgba(Colors.md3.secondary.r,
                                                  Colors.md3.secondary.g,
                                                  Colors.md3.secondary.b, 0.10)
                                Behavior on color { ColorAnimation { duration: 110 } }

                                Row {
                                    id: cpRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text:        "󰆏"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color:       Colors.md3.on_surface_variant
                                        anchors.verticalCenter: parent.verticalCenter
                                        renderType:  Text.NativeRendering
                                    }
                                    Text {
                                        text:           "Copy"
                                        font.family:    "Google Sans Flex"
                                        font.pixelSize: 12
                                        font.weight:    Font.Medium
                                        color:          Colors.md3.on_surface_variant
                                        anchors.verticalCenter: parent.verticalCenter
                                        renderType:     Text.NativeRendering
                                    }
                                }

                                MouseArea {
                                    id: cpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked:    card.copyRequested()
                                }
                            }

                            Rectangle {
                                height: 30
                                width:  dmRow.implicitWidth + 22
                                radius: 15
                                color:  dmMa.containsMouse
                                        ? Colors.md3.error_container
                                        : Qt.rgba(Colors.md3.error.r,
                                                  Colors.md3.error.g,
                                                  Colors.md3.error.b, 0.08)
                                Behavior on color { ColorAnimation { duration: 110 } }

                                Row {
                                    id: dmRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text:        "󰅖"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color:       Colors.md3.error
                                        anchors.verticalCenter: parent.verticalCenter
                                        renderType:  Text.NativeRendering
                                    }
                                    Text {
                                        text:           "Dismiss"
                                        font.family:    "Google Sans Flex"
                                        font.pixelSize: 12
                                        font.weight:    Font.Medium
                                        color:          Colors.md3.error
                                        anchors.verticalCenter: parent.verticalCenter
                                        renderType:     Text.NativeRendering
                                    }
                                }

                                MouseArea {
                                    id: dmMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked:    card.dismissRequested()
                                }
                            }
                        }

                        // Bottom padding
                        Item { width: 1; height: 12 }
                    }
                }
            }
        }
    }
}

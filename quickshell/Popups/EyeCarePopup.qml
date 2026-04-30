import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

Rectangle {
    id: root
    visible: false

    property string fontSans:       "Google Sans Flex"
    property string fontMono:       "JetBrainsMono Nerd Font"
    property color  colorPrimary:   Colors.md3.primary
    property color  colorOnSurface: Colors.md3.on_surface
    property color  colorMuted:     Colors.md3.on_surface_variant
    property color  chipHoverColor: Colors.md3.surface_container_highest
    property color  sliderTrackBg:  Qt.rgba(Colors.md3.on_surface.r,
                                            Colors.md3.on_surface.g,
                                            Colors.md3.on_surface.b, 0.10)
    property color  sliderFill:     Colors.md3.primary
    property int    trackH:         6
    property int    trackR:         3
    property int    thumbW:         4
    property int    thumbH:         22

    property bool active:      false
    property int  temperature: 3400
    property int  intensity:   100

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
        anchors.centerIn: parent
        implicitHeight:   content.implicitHeight + 48
        radius: 20
        color:  Colors.md3.surface_container
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

        function applyFilter() {
            if (!root.active) {
                Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
                return
            }
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature",
                                      root.temperature.toString()])
            Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma",
                                      root.intensity.toString()])
        }

        ColumnLayout {
            id: content
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            spacing: 18

            // ── Header ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 10

                // Icon badge
                Rectangle {
                    width: 34; height: 34; radius: 10
                    color: root.active
                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.15)
                           : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.10)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text {
                        anchors.centerIn: parent; text: "󰛊"
                        font.family: root.fontMono; font.pixelSize: 17
                        color: root.active ? root.colorPrimary : root.colorMuted
                        renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Title + subtitle
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Eye Care"
                        font.family: root.fontSans; font.pixelSize: 14; font.weight: Font.SemiBold
                        color: root.colorOnSurface; renderType: Text.NativeRendering
                    }
                    Text {
                        text: root.active ? temperature + " K  ·  " + intensity + "% gamma" : "Adjust warm filter & gamma"
                        font.family: root.fontSans; font.pixelSize: 10
                        color: root.colorMuted; renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Item { Layout.fillWidth: true }

                // Toggle switch
                Rectangle {
                    width: 48; height: 26; radius: 13
                    color: root.active
                           ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.25)
                           : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.12)
                    border.color: root.active
                                  ? Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.35)
                                  : Qt.rgba(root.colorMuted.r,   root.colorMuted.g,   root.colorMuted.b,   0.20)
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.active ? parent.width - width - 4 : 4
                        color: root.active ? root.colorPrimary : root.colorMuted
                        Behavior on x     { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation  { duration: 160 } }
                        Rectangle {
                            anchors.centerIn: parent; width: 6; height: 6; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.6); visible: root.active
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.active = !root.active; card.applyFilter() }
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

            // ── Divider ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(root.colorMuted.r, root.colorMuted.g, root.colorMuted.b, 0.12)
            }

            // ── Color Temperature slider ──────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                opacity: root.active ? 1.0 : 0.38
                Behavior on opacity { NumberAnimation { duration: 150 } }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Color Temperature"
                        font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.temperature + " K"
                        font.family: root.fontMono; font.pixelSize: 11
                        color: root.colorPrimary; renderType: Text.NativeRendering
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: root.thumbH

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: root.trackH

                        Rectangle {
                            width: parent.width; height: parent.height
                            radius: root.trackR
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0;  color: "#C0392B" }
                                GradientStop { position: 0.30; color: "#E8783A" }
                                GradientStop { position: 0.55; color: "#F5CBA7" }
                                GradientStop { position: 1.0;  color: "#4A90D9" }
                            }
                            opacity: 0.22
                        }
                        Item {
                            width: Math.max(root.trackR * 2,
                                   ((root.temperature - 1000) / 5500) * parent.width)
                            height: parent.height; clip: true
                            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                            Rectangle {
                                width: parent.parent.width; height: parent.height
                                radius: root.trackR
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0;  color: "#C0392B" }
                                    GradientStop { position: 0.30; color: "#E8783A" }
                                    GradientStop { position: 0.55; color: "#F5CBA7" }
                                    GradientStop { position: 1.0;  color: "#4A90D9" }
                                }
                                opacity: 0.92
                            }
                        }
                    }

                    Rectangle {
                        x: Math.max(root.trackR * 2,
                           ((root.temperature - 1000) / 5500) * parent.width) - (root.thumbW / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.thumbW; height: root.thumbH
                        radius: 2; color: "#ffffff"; opacity: 0.95
                        Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        enabled: root.active
                        cursorShape: root.active ? Qt.PointingHandCursor : Qt.ArrowCursor
                        function set(mx) {
                            const pct = Math.min(Math.max(mx / width, 0), 1)
                            root.temperature = Math.round(1000 + pct * 5500)
                            card.applyFilter()
                        }
                        onClicked:         (e) => set(e.x)
                        onPositionChanged: (e) => { if (pressed) set(e.x) }
                        onWheel: (e) => {
                            root.temperature = Math.min(6500, Math.max(1000,
                                root.temperature + (e.angleDelta.y > 0 ? 100 : -100)))
                            card.applyFilter()
                        }
                    }
                }
            }

            // ── Gamma slider ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                opacity: root.active ? 1.0 : 0.38
                Behavior on opacity { NumberAnimation { duration: 150 } }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Gamma"
                        font.family: root.fontSans; font.pixelSize: 11; font.weight: Font.Medium
                        color: root.colorMuted; renderType: Text.NativeRendering
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.intensity + "%"
                        font.family: root.fontMono; font.pixelSize: 11
                        color: root.colorPrimary; renderType: Text.NativeRendering
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: root.thumbH

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: root.trackH

                        Rectangle {
                            width: parent.width; height: parent.height
                            radius: root.trackR; color: root.sliderFill; opacity: 0.20
                        }
                        Item {
                            width: Math.max(root.trackR * 2,
                                   ((root.intensity - 20) / 80) * parent.width)
                            height: parent.height; clip: true
                            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                            Rectangle {
                                width: parent.parent.width; height: parent.height
                                radius: root.trackR; color: root.sliderFill; opacity: 0.90
                            }
                        }
                    }

                    Rectangle {
                        x: Math.max(root.trackR * 2,
                           ((root.intensity - 20) / 80) * parent.width) - (root.thumbW / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.thumbW; height: root.thumbH
                        radius: 2; color: "#ffffff"; opacity: 0.95
                        Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        enabled: root.active
                        cursorShape: root.active ? Qt.PointingHandCursor : Qt.ArrowCursor
                        function set(mx) {
                            const pct = Math.min(Math.max(mx / width, 0), 1)
                            root.intensity = Math.round(20 + pct * 80)
                            card.applyFilter()
                        }
                        onClicked:         (e) => set(e.x)
                        onPositionChanged: (e) => { if (pressed) set(e.x) }
                        onWheel: (e) => {
                            root.intensity = Math.min(100, Math.max(20,
                                root.intensity + (e.angleDelta.y > 0 ? 5 : -5)))
                            card.applyFilter()
                        }
                    }
                }
            }

            Item { height: 2 }
        }
    }

    function open()  { root.visible = true  }
    function close() { root.visible = false }
}

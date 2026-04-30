import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Services"
import ".."

PanelWindow {
    id: root

    visible: false

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    exclusionMode:               ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    // ── Design tokens ─────────────────────────────────────────────────────────
    readonly property color  colorSurface:   Colors.md3.surface_container_low
    readonly property color  colorSection:   Colors.md3.surface_container
    readonly property color  colorHigh:      Colors.md3.surface_container_highest
    readonly property color  colorPrimary:   Colors.md3.primary
    readonly property color  colorOnPrimary: Colors.md3.on_primary
    readonly property color  colorOnSurface: Colors.md3.on_surface
    readonly property color  colorMuted:     Colors.md3.on_surface_variant
    readonly property color  colorSubtle:    Colors.md3.outline_variant
    readonly property color  colorError:     Colors.md3.error
    readonly property string fontSans:       "Google Sans Flex"
    readonly property string fontMono:       "JetBrainsMono Nerd Font"

    // ── State ─────────────────────────────────────────────────────────────────
    property var    images:     []
    property bool   isLoading:  false
    property string statusText: ""
    readonly property string home: Quickshell.env("HOME") ?? ""

    onVisibleChanged: {
        if (!visible) return
        images     = []
        statusText = ""
        isLoading  = true
        findImages.running = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.visible = false
    }

    // ── Process: find images ──────────────────────────────────────────────────
    Process {
        id: findImages
command: [
    "sh", "-c",
    `find "${root.home}/.config/wall" \
     -maxdepth 1 -type f \
     \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.avif' \\) \
     2>/dev/null | sort`
]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(l => l.length > 0)
                root.images    = lines
                root.isLoading = false
                if (lines.length === 0)
                    root.statusText = "No images found in ~/Pictures or ~/Downloads"
            }
        }
    }

    // ── Process chain: swww → matugen → notify ────────────────────────────────
    Process {
        id: swwwProc
        onRunningChanged: {
            if (!running && matugenProc.command.length > 0)
                matugenProc.running = true
        }
    }
    Process {
        id: matugenProc
        onRunningChanged: {
            if (!running && notifyProc.command.length > 0)
                notifyProc.running = true
        }
    }
    Process { id: notifyProc }

    function applyWallpaper(path) {
        var fname = path.split("/").pop()
        swwwProc.command = [
            "awww", "img", path,
            "--transition-type",     "grow",
            "--transition-pos",      "center",
            "--transition-duration", "1.5",
            "--transition-fps",      "60"
        ]
        matugenProc.command = [
            "matugen", "image", "--prefer", "lightness", path
        ]
        notifyProc.command = [
            "notify-send", 
            "Wallpaper Applied", fname + "\nColor scheme regenerated"
        ]
        swwwProc.running = true
        root.visible     = false
    }

    // ── Dim backdrop ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(0, 0, 0, 0.55)
        MouseArea {
            anchors.fill: parent
            onClicked:    root.visible = false
        }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        width:            Math.min(980, parent.width  - 80)
        height:           Math.min(660, parent.height - 80)
        anchors.centerIn: parent
        radius:           24
        color:            root.colorSurface
        border.width:     1
        border.color:     root.colorSubtle
        layer.enabled:    true

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors {
                fill:    parent
                margins: 20
            }
            spacing: 12

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: root.colorSection
                    Text {
                        anchors.centerIn: parent
                        text:            "󰸉"
                        font.family:     root.fontMono
                        font.pixelSize:  18
                        color:           root.colorPrimary
                        renderType:      Text.NativeRendering
                    }
                }

                Text {
                    text:           "Wallpaper Picker"
                    color:          root.colorOnSurface
                    font.family:    root.fontSans
                    font.pixelSize: 16
                    font.weight:    Font.SemiBold
                    renderType:     Text.NativeRendering
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: closeHov.containsMouse
                           ? Qt.rgba(root.colorError.r, root.colorError.g, root.colorError.b, 0.18)
                           : root.colorSection
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text:            "󰅖"
                        font.family:     root.fontMono
                        font.pixelSize:  15
                        color:           closeHov.containsMouse ? root.colorError : root.colorMuted
                        renderType:      Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id:           closeHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.visible = false
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           1
                color:            root.colorSubtle
                opacity:          0.6
            }

            // ── Loading / empty state ─────────────────────────────────────
            Item {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                visible:           root.isLoading || root.statusText !== ""

                Column {
                    anchors.centerIn: parent
                    spacing:          16

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36; height: 36; radius: 18
                        color: "transparent"
                        border.width: 3
                        border.color: root.colorPrimary
                        visible:      root.isLoading

                        RotationAnimation on rotation {
                            running:  root.isLoading
                            loops:    Animation.Infinite
                            from:     0; to: 360
                            duration: 900
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:            root.isLoading ? "Scanning images…" : root.statusText
                        color:           root.colorMuted
                        font.family:     root.fontSans
                        font.pixelSize:  14
                        renderType:      Text.NativeRendering
                    }
                }
            }

            // ── Grid ──────────────────────────────────────────────────────
            ScrollView {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                visible:           !root.isLoading && root.statusText === ""
                clip:              true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy:   ScrollBar.AsNeeded

                GridView {
                    id:    grid
                    width: parent.width
                    model: root.images

                    readonly property int cols: 4
                    readonly property int gap:  10
                    cellWidth:  Math.floor((width - gap * (cols - 1)) / cols)
                    cellHeight: Math.floor(cellWidth * 9 / 16)

                    delegate: Item {
                        width:  grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors { fill: parent; margins: grid.gap / 2 }
                            radius: 16
                            color:  root.colorSection
                            clip:   true

                            border.width: tileHov.containsMouse ? 2 : 0
                            border.color: root.colorPrimary
                            Behavior on border.width { NumberAnimation { duration: 120 } }

                            Image {
                                id:           img
                                anchors.fill: parent
                                source:       "file://" + modelData
                                fillMode:     Image.PreserveAspectCrop
                                asynchronous: true
                                smooth:       true

                                Rectangle {
                                    anchors.fill: parent
                                    color:        root.colorSection
                                    visible:      img.status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent
                                        text:            img.status === Image.Loading ? "󰋩" : "󰱱"
                                        font.family:     root.fontMono
                                        font.pixelSize:  28
                                        color:           root.colorMuted
                                        renderType:      Text.NativeRendering
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius:       0
                                color:        Qt.rgba(0, 0, 0, 0.52)
                                opacity:      tileHov.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 130 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing:          6

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text:            "󰄬  Apply"
                                        font.family:     root.fontSans
                                        font.pixelSize:  14
                                        font.weight:     Font.SemiBold
                                        color:           root.colorOnPrimary
                                        renderType:      Text.NativeRendering
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: {
                                            var f = modelData.split("/").pop()
                                            return f.length > 24 ? f.substring(0, 22) + "…" : f
                                        }
                                        font.family:     root.fontSans
                                        font.pixelSize:  10
                                        color:           Qt.rgba(1, 1, 1, 0.70)
                                        renderType:      Text.NativeRendering
                                    }
                                }
                            }

                            MouseArea {
                                id:           tileHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    root.applyWallpaper(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

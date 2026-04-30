import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."

PanelWindow {
    id: root

    visible: false

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive
                                         : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:    true
        left:   true
        right:  true
        bottom: true
    }

    color: "transparent"

    function toggle() {
        root.visible = !root.visible
    }

    Process {
        id: proc
        property string cmd: ""
        command: ["sh", "-c", cmd]
        onRunningChanged: if (!running && cmd !== "") root.visible = false
    }

    function run(command) {
        proc.cmd     = command
        proc.running = true
    }

    // ── animation state ───────────────────────────────────────────────
    property real showProgress: 0.0

    onVisibleChanged: {
        if (visible) {
            showAnim.restart()
        } else {
            showProgress = 0.0
        }
    }

    NumberAnimation {
        id:       showAnim
        target:   root
        property: "showProgress"
        from:     0.0
        to:       1.0
        duration: 320
        easing.type: Easing.OutExpo
    }

    // ── key handling — needs a focused Item to catch Escape ───────────
    Item {
        anchors.fill: parent
        focus:        true

        Keys.onShortcutOverride: (event) => {
            event.accepted = (event.key === Qt.Key_Escape)
        }
        Keys.onEscapePressed: root.visible = false

        // ── background — solid surface color, no transparency ─────────
        Rectangle {
            anchors.fill: parent
            color:        Colors.md3.background

            opacity: root.showProgress
            Behavior on opacity {
                NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
            }

            // dismiss on click outside buttons
            MouseArea {
                anchors.fill: parent
                onClicked:    root.visible = false
            }

            // ── content — slides up + fades in ────────────────────────
            ColumnLayout {
                anchors.centerIn: parent
                spacing:          0

                opacity:          root.showProgress
                transform: Translate {
                    y: (1.0 - root.showProgress) * 40
                }

                Text {
                    Layout.alignment:    Qt.AlignHCenter
                    Layout.bottomMargin: 48
                    text:            "What do you want to do?"
                    color:           Colors.md3.on_surface_variant
                    font.pixelSize:  15
                    font.family:     "JetBrainsMono Nerd Font"
                    renderType:      Text.NativeRendering
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing:          24

                    component ActionButton: Rectangle {
                        id: btn
                        property string icon:    ""
                        property string label:   ""
                        property string command: ""

                        implicitWidth:  110
                        implicitHeight: 130
                        radius:         28

                        color: btnArea.containsMouse
                            ? Qt.rgba(
                                Qt.color(Colors.md3.primary_container).r,
                                Qt.color(Colors.md3.primary_container).g,
                                Qt.color(Colors.md3.primary_container).b,
                                1)
                            : Colors.md3.surface_container

                        border.color: btnArea.containsMouse
                            ? Colors.md3.primary
                            : Qt.rgba(
                                Qt.color(Colors.md3.outline).r,
                                Qt.color(Colors.md3.outline).g,
                                Qt.color(Colors.md3.outline).b,
                                0.35)
                        border.width: 1.5

                        scale: btnArea.containsMouse ? 1.06 : 1.0

                        Behavior on color        { ColorAnimation  { duration: 180 } }
                        Behavior on border.color { ColorAnimation  { duration: 180 } }
                        Behavior on scale        { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        MouseArea {
                            id:           btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    if (btn.command !== "") root.run(btn.command)
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing:          10

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text:             btn.icon
                                font.family:      "JetBrainsMono Nerd Font"
                                font.pixelSize:   36
                                color:            btnArea.containsMouse
                                                  ? Colors.md3.primary
                                                  : Colors.md3.on_surface
                                renderType:       Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text:             btn.label
                                font.family:      "JetBrainsMono Nerd Font"
                                font.pixelSize:   12
                                color:            btnArea.containsMouse
                                                  ? Colors.md3.primary
                                                  : Colors.md3.on_surface_variant
                                renderType:       Text.NativeRendering
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }
                    }

                    ActionButton { icon: "󰌾"; label: "Lock";     command: "hyprlock" }
                    ActionButton { icon: "󰍃"; label: "Logout";   command: "hyprctl dispatch exit" }
                    ActionButton { icon: "󰒲"; label: "Suspend";  command: "systemctl suspend" }
                    ActionButton { icon: "󰜉"; label: "Reboot";   command: "systemctl reboot" }
                    ActionButton { icon: "󰐥"; label: "Shutdown"; command: "systemctl poweroff" }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    text:             "Press  Esc  to cancel"
                    color:            Colors.md3.outline
                    font.pixelSize:   12
                    font.family:      "JetBrainsMono Nerd Font"
                    renderType:       Text.NativeRendering
                }
            }
        }
    }
}

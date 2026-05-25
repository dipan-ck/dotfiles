import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: eyeCare

    visible: false
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    property string activeMode:    "off"
    property int    selectedIndex: 0
    property real   cardProgress:  0.0
    property real   dimProgress:   0.0

    // ── processes ─────────────────────────────────────────────────
    Process {
        id: killProc
        command: ["pkill", "hyprsunset"]
        onRunningChanged: if (!running && applyProc.tempArg !== "") applyProc.running = true
    }
    Process {
        id: applyProc
        property string tempArg: ""
        command: ["hyprsunset", "-t", tempArg]
    }
    Process {
        id: notifyProc
        property string body: ""; property string icon: ""
        command: ["dunstify", "-u", "low", "--replace=699", icon + " Eye Care", body]
    }
    Process {
        id: stateWrite
        property string mode: ""
        command: ["sh", "-c", "echo " + mode + " > /tmp/hyprsunset_state"]
    }
    Process {
        id: stateRead
        command: ["sh", "-c", "cat /tmp/hyprsunset_state 2>/dev/null || echo off"]
        stdout: SplitParser {
            onRead: data => {
                var m = data.trim()
                if (["off","warm","warmer","hot"].indexOf(m) >= 0) eyeCare.activeMode = m
            }
        }
        Component.onCompleted: running = true
    }

    // ── helpers ───────────────────────────────────────────────────
    function open() {
        stateRead.running = true
        selectedIndex = ["off","warm","warmer","hot"].indexOf(activeMode)
        if (selectedIndex < 0) selectedIndex = 0
        visible = true
    }
    function close()  { visible = false }
    function toggle() { if (visible) close(); else open() }

    function apply(mode) {
        activeMode = mode
        stateWrite.mode = mode; stateWrite.running = true
        if (mode === "off") {
            killProc.command = ["pkill", "hyprsunset"]
            applyProc.tempArg = ""
            killProc.running = true
            notifyProc.icon = "󰈈"; notifyProc.body = "Filter off"; notifyProc.running = true
        } else {
            var cfg = {
                "warm":   { temp: "4500", icon: "󱩌", label: "Warm — 4500K"   },
                "warmer": { temp: "3500", icon: "󰛨", label: "Warmer — 3500K" },
                "hot":    { temp: "2700", icon: "󰈉", label: "Hot — 2700K"    },
            }
            applyProc.tempArg   = cfg[mode].temp
            notifyProc.icon     = cfg[mode].icon
            notifyProc.body     = cfg[mode].label
            killProc.running    = true   // → triggers applyProc on finish
            notifyProc.running  = true
        }
        close()
    }

    // ── animation ─────────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) { cardProgress = 0.0; dimProgress = 0.0; cardAnim.restart(); dimDelay.restart() }
        else { cardProgress = 0.0; dimProgress = 0.0 }
    }
    NumberAnimation { id: cardAnim; target: eyeCare; property: "cardProgress"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    Timer          { id: dimDelay; interval: 80; repeat: false; onTriggered: dimAnim.restart() }
    NumberAnimation { id: dimAnim;  target: eyeCare; property: "dimProgress";  from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }

    // ── keyboard ──────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        focus: true

        Keys.onShortcutOverride: event => {
            event.accepted = [Qt.Key_Escape, Qt.Key_Up, Qt.Key_Down,
                              Qt.Key_Return, Qt.Key_Enter, Qt.Key_Tab].indexOf(event.key) >= 0
        }
        Keys.onPressed: event => {
            if      (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
                eyeCare.selectedIndex = (eyeCare.selectedIndex + 1) % 4
            else if (event.key === Qt.Key_Up)
                eyeCare.selectedIndex = (eyeCare.selectedIndex - 1 + 4) % 4
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                eyeCare.apply(["off","warm","warmer","hot"][eyeCare.selectedIndex])
            else if (event.key === Qt.Key_Escape)
                eyeCare.close()
            event.accepted = true
        }

        // dim
        // Rectangle {
        //     anchors.fill: parent
        //     color: Qt.rgba(0, 0, 0, 0.6)
        //     opacity: eyeCare.dimProgress
        //     MouseArea { anchors.fill: parent; onClicked: eyeCare.close() }
        // }

        // card — same width/radius/border as PowerMenu card
        Rectangle {
            anchors.centerIn: parent
            width:  440
            height: ecContent.height + 40
            radius: 28
            color:  Colors.md3.surface
            border.color: Qt.rgba(1, 1, 1, 0.07); border.width: 1
            opacity:   eyeCare.cardProgress
            transform: Translate { y: (1.0 - eyeCare.cardProgress) * 30 }

            Column {
                id: ecContent
                anchors { top: parent.top; left: parent.left; right: parent.right
                          topMargin: 20; leftMargin: 20; rightMargin: 20 }
                spacing: 10

                // ── header pill — identical structure to PowerMenu ─
                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Colors.md3.surface_container

                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        Text {
                            text: "󱩌"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 18
                            color: Colors.md3.primary; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Eye Care"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                            color: Colors.md3.on_surface; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 28; height: 28; radius: 14
                        color: ecClose.containsMouse ? Colors.md3.surface_container_high : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "󰅖"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14; color: Colors.md3.on_surface_variant }
                        MouseArea { id: ecClose; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: eyeCare.close() }
                    }
                }

                // ── status pill ───────────────────────────────────
                // Rectangle {
                //     width: parent.width; height: 36; radius: 18
                //     color: Colors.md3.surface_container
                //
                //     Row {
                //         anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                //         spacing: 8
                //         Text {
                //             text: eyeCare.activeMode === "off" ? "󰈈" :
                //                   eyeCare.activeMode === "warm" ? "󱩌" :
                //                   eyeCare.activeMode === "warmer" ? "󰛨" : "󰈉"
                //             font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                //             color: eyeCare.activeMode === "off" ? Colors.md3.on_surface_variant : Colors.md3.primary
                //             anchors.verticalCenter: parent.verticalCenter
                //             Behavior on color { ColorAnimation { duration: 200 } }
                //         }
                //         Text {
                //             text: eyeCare.activeMode === "off"    ? "No filter active" :
                //                   eyeCare.activeMode === "warm"   ? "Warm — 4500K" :
                //                   eyeCare.activeMode === "warmer" ? "Warmer — 3500K" : "Hot — 2700K"
                //             font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11
                //             color: Colors.md3.on_surface_variant
                //             anchors.verticalCenter: parent.verticalCenter
                //         }
                //     }
                // }

                // ── option rows ───────────────────────────────────
                Repeater {
                    model: [
                        { icon: "󰈈", label: "Off",    sub: "No filter",  mode: "off"    },
                        { icon: "󱩌", label: "Warm",   sub: "4500K",      mode: "warm"   },
                        { icon: "󰛨", label: "Warmer", sub: "3500K",      mode: "warmer" },
                        { icon: "󰈉", label: "Hot",    sub: "2700K",      mode: "hot"    },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        property bool isActive:   eyeCare.activeMode   === modelData.mode
                        property bool isSelected: eyeCare.selectedIndex === index
                        property bool hov:        rowMA.containsMouse

                        width: parent.width; height: 52; radius: 26

                        color: (isSelected || hov) ? Colors.md3.primary_container
                             : isActive            ? Colors.md3.surface_container_high
                             :                       "transparent"

                        Behavior on color { ColorAnimation  { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                        scale: (isSelected || hov) ? 1.02 : 1.0

                        Row {
                            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: 14

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 22
                                color: (isSelected || hov) ? Colors.md3.on_primary_container
                                     : isActive            ? Colors.md3.primary
                                     :                       Colors.md3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Text {
                                    text: modelData.label; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12
                                    color: (isSelected || hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                                Text {
                                    text: modelData.sub; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10
                                    color: (isSelected || hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                    opacity: 0.75
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                            }
                        }

                        // active indicator dot
                        Rectangle {
                            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            width: 8; height: 8; radius: 4
                            color:   Colors.md3.primary
                            visible: isActive
                        }

                        MouseArea {
                            id: rowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: eyeCare.selectedIndex = index
                            onClicked: eyeCare.apply(modelData.mode)
                        }
                    }
                }
            }
        }
    }
}

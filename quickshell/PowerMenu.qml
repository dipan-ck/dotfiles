import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: powerMenu

    visible: false
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    property bool   confirmMode:   false
    property string pendingAction: ""
    property int    selectedIndex: 0
    property int    confirmSel:    1
    property real   cardProgress:  0.0
    property real   dimProgress:   0.0

    Process { id: shutdownProc;  command: ["systemctl", "poweroff"]       }
    Process { id: rebootProc;    command: ["systemctl", "reboot"]         }
    Process { id: hibernateProc; command: ["systemctl", "hibernate"]      }
    Process { id: suspendProc;   command: ["systemctl", "suspend"]        }
    Process { id: lockProc;      command: ["hyprlock"]                    }
    Process { id: logoutProc;    command: ["hyprctl", "dispatch", "exit"] }

    function open() {
        confirmMode = false; pendingAction = ""; selectedIndex = 0; confirmSel = 1
        visible = true
    }
    function close() {
        visible = false; confirmMode = false; pendingAction = ""; selectedIndex = 0
    }
    function toggle() { if (visible) close(); else open() }

    function requestAction(action) {
        if (action === "lock") { lockProc.running = true; close(); return }
        pendingAction = action; confirmSel = 1; confirmMode = true
    }
    function runPending() {
        switch (pendingAction) {
            case "shutdown":  shutdownProc.running  = true; break
            case "reboot":    rebootProc.running    = true; break
            case "hibernate": hibernateProc.running = true; break
            case "suspend":   suspendProc.running   = true; break
            case "logout":    logoutProc.running    = true; break
        }
        close()
    }

    onVisibleChanged: {
        if (visible) { cardProgress = 0.0; dimProgress = 0.0; cardAnim.restart(); dimDelay.restart() }
        else { cardProgress = 0.0; dimProgress = 0.0 }
    }
    NumberAnimation { id: cardAnim; target: powerMenu; property: "cardProgress"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    Timer          { id: dimDelay; interval: 80; repeat: false; onTriggered: dimAnim.restart() }
    NumberAnimation { id: dimAnim;  target: powerMenu; property: "dimProgress";  from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onShortcutOverride: event => {
            event.accepted = [Qt.Key_Escape, Qt.Key_Left, Qt.Key_Right,
                              Qt.Key_Up, Qt.Key_Down, Qt.Key_Return,
                              Qt.Key_Enter, Qt.Key_Tab].indexOf(event.key) >= 0
        }
        Keys.onPressed: event => {
            if (!powerMenu.confirmMode) {
                if      (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                    powerMenu.selectedIndex = (powerMenu.selectedIndex + 1) % 6
                else if (event.key === Qt.Key_Left)
                    powerMenu.selectedIndex = (powerMenu.selectedIndex - 1 + 6) % 6
                else if (event.key === Qt.Key_Down) { if (powerMenu.selectedIndex + 3 < 6) powerMenu.selectedIndex += 3 }
                else if (event.key === Qt.Key_Up)   { if (powerMenu.selectedIndex - 3 >= 0) powerMenu.selectedIndex -= 3 }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    powerMenu.requestAction(["shutdown","reboot","lock","suspend","hibernate","logout"][powerMenu.selectedIndex])
                else if (event.key === Qt.Key_Escape) powerMenu.close()
                event.accepted = true
            } else {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                    powerMenu.confirmSel = powerMenu.confirmSel === 0 ? 1 : 0
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (powerMenu.confirmSel === 0) powerMenu.runPending()
                    else powerMenu.confirmMode = false
                } else if (event.key === Qt.Key_Escape) powerMenu.confirmMode = false
                event.accepted = true
            }
        }

        // dim
        // Rectangle {
        //     anchors.fill: parent
        //     color: Qt.rgba(0, 0, 0, 0.6)
        //     opacity: powerMenu.dimProgress
        //     MouseArea { anchors.fill: parent; onClicked: powerMenu.close() }
        // }
        //
        // card
        Rectangle {
            anchors.centerIn: parent
            width:  440
            height: powerMenu.confirmMode ? 220 : 280
            radius: 28
            color:  Colors.md3.surface
            border.color: Qt.rgba(1, 1, 1, 0.07); border.width: 1
            opacity:   powerMenu.cardProgress
            transform: Translate { y: (1.0 - powerMenu.cardProgress) * 30 }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // ── header ────────────────────────────────────────────
            Rectangle {
                id: pmHeader
                anchors { top: parent.top; left: parent.left; right: parent.right
                          topMargin: 20; leftMargin: 20; rightMargin: 20 }
                height: 44; radius: 22
                color: Colors.md3.surface_container

                Row {
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    spacing: 10
                    Text {
                        text: "⏻"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 18
                        color: Colors.md3.primary; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: powerMenu.confirmMode
                            ? "Are you sure?"
                            : "Power Menu"
                        font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                        color: Colors.md3.on_surface; anchors.verticalCenter: parent.verticalCenter
                        Behavior on text {}
                    }
                }
                Rectangle {
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 28; height: 28; radius: 14
                    color: pmClose.containsMouse ? Colors.md3.surface_container_high : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "󰅖"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14; color: Colors.md3.on_surface_variant }
                    MouseArea { id: pmClose; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: powerMenu.close() }
                }
            }

            // ── MAIN GRID ─────────────────────────────────────────
            Grid {
                anchors {
                    top: pmHeader.bottom; topMargin: 16
                    horizontalCenter: parent.horizontalCenter
                }
                columns: 3; spacing: 10
                visible: !powerMenu.confirmMode
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }

                Repeater {
                    model: [
                        { icon: "󰀑", label: "Shutdown",  action: "shutdown"  },
                        { icon: "󰜉", label: "Reboot",    action: "reboot"    },
                        { icon: "󰌾", label: "Lock",      action: "lock"      },
                        { icon: "󰤄", label: "Suspend",   action: "suspend"   },
                        { icon: "󰒲", label: "Hibernate", action: "hibernate" },
                        { icon: "󰍃", label: "Logout",    action: "logout"    },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property bool sel: powerMenu.selectedIndex === index && !powerMenu.confirmMode
                        property bool hov: ma.containsMouse

                        width: 120; height: 76; radius: 20
                        color: (sel || hov) ? Colors.md3.primary_container : Colors.md3.surface_container
                        Behavior on color { ColorAnimation  { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                        scale: (sel || hov) ? 1.05 : 1.0

                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 24
                                color: (parent.parent.sel || parent.parent.hov) ? Colors.md3.on_primary_container : Colors.md3.primary
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11
                                color: (parent.parent.sel || parent.parent.hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: powerMenu.selectedIndex = index
                            onClicked: powerMenu.requestAction(modelData.action)
                        }
                    }
                }
            }

            // ── CONFIRM BUTTONS ───────────────────────────────────
            Row {
                anchors {
                    top: pmHeader.bottom; topMargin: 28
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: 12
                visible:  powerMenu.confirmMode
                opacity:  visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }

                // Yes
                Rectangle {
                    property bool sel: powerMenu.confirmSel === 0
                    property bool hov: yesMA.containsMouse
                    width: 130; height: 44; radius: 22
                    color: Colors.md3.error
                    border.color: (sel || hov) ? Qt.lighter(Colors.md3.error, 1.5) : "transparent"; border.width: 2
                    Behavior on border.color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                    scale: (sel || hov) ? 1.05 : 1.0
                    Row { anchors.centerIn: parent; spacing: 6
                        Text { text: "󰄬"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 16; color: Colors.md3.on_error; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Yes"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13; color: Colors.md3.on_error; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: yesMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: powerMenu.confirmSel = 0; onClicked: powerMenu.runPending() }
                }

                // No
                Rectangle {
                    property bool sel: powerMenu.confirmSel === 1
                    property bool hov: noMA.containsMouse
                    width: 130; height: 44; radius: 22
                    color: (sel || hov) ? Colors.md3.surface_container_high : Colors.md3.surface_container
                    border.color: sel ? Colors.md3.primary : "transparent"; border.width: 2
                    Behavior on color        { ColorAnimation  { duration: 130 } }
                    Behavior on border.color { ColorAnimation  { duration: 130 } }
                    Behavior on scale        { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                    scale: (sel || hov) ? 1.05 : 1.0
                    Row { anchors.centerIn: parent; spacing: 6
                        Text { text: "󰅖"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 16; color: Colors.md3.on_surface_variant; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "No";  font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13; color: Colors.md3.on_surface_variant; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: noMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: powerMenu.confirmSel = 1; onClicked: powerMenu.confirmMode = false }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: screenshot

    visible: false
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    property int  selectedIndex: 0
    property real cardProgress:  0.0
    property real dimProgress:   0.0
    property bool counting:      false
    property int  countValue:    0

    // ── processes ─────────────────────────────────────────────────
    Process {
        id: mkdirProc
        command: ["sh", "-c", "mkdir -p \"$(xdg-user-dir PICTURES)/Screenshots\""]
        Component.onCompleted: running = true
    }

    Process {
        id: shotProc
        property string args: ""
        command: ["sh", "-c", args]
    }

    Process {
        id: notifyProc
        property string file: ""
        command: ["dunstify", "-u", "low", "--replace=699",
                  "-i", notifyProc.file,
                  "Screenshot saved",
                  notifyProc.file.split("/").pop()]
    }

    Process {
        id: countdownNotify
        property string msg: ""
        command: ["dunstify", "-t", "1000", "--replace=699", "Taking shot in :", msg]
    }

    // ── helpers ───────────────────────────────────────────────────
    function open() {
        selectedIndex = 0
        visible = true
    }
    function close()  { visible = false }
    function toggle() { if (visible) close(); else open() }

    function buildCmd(mode) {
        var dir = "$(xdg-user-dir PICTURES)/Screenshots"
        var out  = dir + "/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
        var notify = "; f=$(ls -t " + dir + "/*.png 2>/dev/null | head -1); dunstify -u low --replace=699 -i \"$f\" 'Screenshot saved' \"$(basename $f)\""
        switch (mode) {
            case "desktop": return "sleep 0.5; hyprshot -m output --raw | satty --filename - --output-filename \"" + out + "\"" + notify
            case "area":    return "hyprshot -m region --raw | satty --filename - --output-filename \"" + out + "\"" + notify
            case "window":  return "hyprshot -m window --raw | satty --filename - --output-filename \"" + out + "\"" + notify
        }
        return ""
    }

    function shoot(mode) {
        shotProc.args = buildCmd(mode)
        shotProc.running = true
        close()
    }

    function shootDelayed(secs) {
        close()
        countValue = secs
        counting = true
        countTimer.remaining = secs
        countTimer.running = true
    }

    // countdown timer — ticks every second, then fires the shot
    property int _remaining: 0

    Timer {
        id: countTimer
        property int remaining: 0
        interval: 1000
        repeat: true
        onTriggered: {
            countdownNotify.msg = remaining.toString()
            countdownNotify.running = true
            remaining--
            if (remaining <= 0) {
                running = false
                screenshot.counting = false
                var dir = "$(xdg-user-dir PICTURES)/Screenshots"
                var out = dir + "/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
                var notify = "; f=$(ls -t " + dir + "/*.png 2>/dev/null | head -1); dunstify -u low --replace=699 -i \"$f\" 'Screenshot saved' \"$(basename $f)\""
                shotProc.args = "sleep 0.5; hyprshot -m output --raw | satty --filename - --output-filename \"" + out + "\"" + notify
                shotProc.running = true
            }
        }
    }

    // ── animation ─────────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) { cardProgress = 0.0; dimProgress = 0.0; cardAnim.restart(); dimDelay.restart() }
        else { cardProgress = 0.0; dimProgress = 0.0 }
    }
    NumberAnimation { id: cardAnim; target: screenshot; property: "cardProgress"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    Timer          { id: dimDelay; interval: 80; repeat: false; onTriggered: dimAnim.restart() }
    NumberAnimation { id: dimAnim;  target: screenshot; property: "dimProgress";  from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }

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
                screenshot.selectedIndex = (screenshot.selectedIndex + 1) % 5
            else if (event.key === Qt.Key_Up)
                screenshot.selectedIndex = (screenshot.selectedIndex - 1 + 5) % 5
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var modes = ["desktop","area","window","5","10"]
                var m = modes[screenshot.selectedIndex]
                if (m === "5" || m === "10") screenshot.shootDelayed(parseInt(m))
                else screenshot.shoot(m)
            } else if (event.key === Qt.Key_Escape)
                screenshot.close()
            event.accepted = true
        }

        // ── dim ───────────────────────────────────────────────────
        // Rectangle {
        //     anchors.fill: parent
        //     color: Qt.rgba(0, 0, 0, 0.6)
        //     opacity: screenshot.dimProgress
        //     MouseArea { anchors.fill: parent; onClicked: screenshot.close() }
        // }

        // ── card ──────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width:  440
            height: ssContent.height + 40
            radius: 28
            color:  Colors.md3.surface
            border.color: Qt.rgba(1, 1, 1, 0.07); border.width: 1
            opacity:   screenshot.cardProgress
            transform: Translate { y: (1.0 - screenshot.cardProgress) * 30 }

            Column {
                id: ssContent
                anchors { top: parent.top; left: parent.left; right: parent.right
                          topMargin: 20; leftMargin: 20; rightMargin: 20 }
                spacing: 10

                // ── header pill ───────────────────────────────────
                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Colors.md3.surface_container

                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        Text {
                            text: "󰹑"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 18
                            color: Colors.md3.primary; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Screenshot"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                            color: Colors.md3.on_surface; anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 28; height: 28; radius: 14
                        color: ssClose.containsMouse ? Colors.md3.surface_container_high : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent; text: "󰅖"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14
                            color: Colors.md3.on_surface_variant
                        }
                        MouseArea {
                            id: ssClose; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: screenshot.close()
                        }
                    }
                }

                // ── save dir pill ─────────────────────────────────
                Rectangle {
                    width: parent.width; height: 36; radius: 18
                    color: Colors.md3.surface_container

                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Text {
                            text: "󰉙"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                            color: Colors.md3.primary; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "~/Pictures/Screenshots"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11
                            color: Colors.md3.on_surface_variant; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── option rows ───────────────────────────────────
                Repeater {
                    model: [
                        { icon: "󰹑", label: "Capture Desktop", sub: "Full screen",        mode: "desktop" },
                        { icon: "󰩭", label: "Capture Area",    sub: "Select region",      mode: "area"    },
                        { icon: "󱂬", label: "Capture Window",  sub: "Active window",      mode: "window"  },
                        { icon: "󱎫", label: "Capture in 5s",   sub: "Countdown timer",    mode: "5"       },
                        { icon: "󱎫", label: "Capture in 10s",  sub: "Countdown timer",    mode: "10"      },
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        property bool isSelected: screenshot.selectedIndex === index
                        property bool hov:        rowMA.containsMouse

                        width: parent.width; height: 52; radius: 26

                        color: (isSelected || hov) ? Colors.md3.primary_container : "transparent"
                        Behavior on color { ColorAnimation  { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                        scale: (isSelected || hov) ? 1.02 : 1.0

                        Row {
                            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                            spacing: 14

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 22
                                color: (isSelected || hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                Text {
                                    text: modelData.label
                                    font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12
                                    color: (isSelected || hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                                Text {
                                    text: modelData.sub
                                    font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10
                                    color: (isSelected || hov) ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                    opacity: 0.75
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: screenshot.selectedIndex = index
                            onClicked: {
                                var m = modelData.mode
                                if (m === "5" || m === "10") screenshot.shootDelayed(parseInt(m))
                                else screenshot.shoot(m)
                            }
                        }
                    }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "."

PanelWindow {
    id: wallpaper

    visible: false
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    property int    selectedIndex: 0
    property real   cardProgress:  0.0
    property real   dimProgress:   0.0
    property bool   applying:      false
    property var    wallList:      []

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string wallDir: homeDir + "/.config/wall"

    // ── scan ──────────────────────────────────────────────────────
    Process {
        id: scanProc
        command: ["sh", "-c",
            "find '" + wallpaper.wallDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.webp' -o -iname '*.gif' \\) | sort"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim()
                if (p === "") return
                var arr = wallpaper.wallList.slice()
                arr.push(p)
                wallpaper.wallList = arr
            }
        }
    }

    // ── apply ─────────────────────────────────────────────────────
    Process {
        id: applyProc
        property string path: ""
        command: ["sh", "-c",
            "awww img '" + path + "' " +
            "--transition-type grow --transition-pos center " +
            "--transition-duration 1.5 --transition-fps 60 ; " +
            "cp '" + path + "' '" + wallpaper.homeDir + "/.config/rofi/current_wallpaper' ; " +
            "sat=$(convert '" + path + "' -colorspace HSL -channel Saturation " +
            "-separate -format '%[fx:mean*100]\\n' info: 2>/dev/null || echo 50) ; " +
            "if [ $(echo \"$sat < 5.0\" | bc -l) -eq 1 ]; then scheme=scheme-monochrome; " +
            "else scheme=scheme-tonal-spot; fi ; " +
            "matugen image --prefer lightness --type \"$scheme\" '" + path + "' ; " +
            "notify-send 'Wallpaper Applied' \"$(basename '" + path + "')\""]
        onRunningChanged: if (!running) wallpaper.applying = false
    }

    // ── helpers ───────────────────────────────────────────────────
    function open() {
        wallList      = []
        selectedIndex = 0
        applying      = false
        scanProc.running = false
        restartScan.restart()
        visible = true
    }
    function close()  { visible = false }
    function toggle() { if (visible) close(); else open() }

    function applyWall(path) {
        if (applying) return
        applying       = true
        applyProc.path = path
        applyProc.running = false
        applyTimer.restart()
    }

    Timer { id: restartScan; interval: 30; repeat: false; onTriggered: scanProc.running = true }
    Timer { id: applyTimer;  interval: 30; repeat: false; onTriggered: { applyProc.running = true; wallpaper.close() } }

    // ── animation ─────────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) { cardProgress = 0.0; dimProgress = 0.0; cardAnim.restart(); dimDelay.restart() }
        else { cardProgress = 0.0; dimProgress = 0.0 }
    }
    NumberAnimation { id: cardAnim; target: wallpaper; property: "cardProgress"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
    Timer          { id: dimDelay; interval: 80; repeat: false; onTriggered: dimAnim.restart() }
    NumberAnimation { id: dimAnim;  target: wallpaper; property: "dimProgress";  from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }

    // ── keyboard ──────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        focus: true

        Keys.onShortcutOverride: event => {
            event.accepted = [Qt.Key_Escape, Qt.Key_Up, Qt.Key_Down,
                              Qt.Key_Left, Qt.Key_Right,
                              Qt.Key_Return, Qt.Key_Enter, Qt.Key_Tab].indexOf(event.key) >= 0
        }
        Keys.onPressed: event => {
            var total = wallpaper.wallList.length
            if (total === 0) { event.accepted = true; return }
            if      (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                wallpaper.selectedIndex = (wallpaper.selectedIndex + 1) % total
            else if (event.key === Qt.Key_Left)
                wallpaper.selectedIndex = (wallpaper.selectedIndex - 1 + total) % total
            else if (event.key === Qt.Key_Down) { var n = wallpaper.selectedIndex + 3; if (n < total) wallpaper.selectedIndex = n }
            else if (event.key === Qt.Key_Up)   { var p = wallpaper.selectedIndex - 3; if (p >= 0)   wallpaper.selectedIndex = p }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                wallpaper.applyWall(wallpaper.wallList[wallpaper.selectedIndex])
            else if (event.key === Qt.Key_Escape)
                wallpaper.close()
            event.accepted = true
        }

        // ── dim ───────────────────────────────────────────────────
        // Rectangle {
        //     anchors.fill: parent
        //     color:   Qt.rgba(0, 0, 0, 0.65)
        //     opacity: wallpaper.dimProgress
        //     MouseArea { anchors.fill: parent; onClicked: wallpaper.close() }
        // }

        // ── card ──────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width:  820
            height: 540
            radius: 28
            color:  Colors.md3.surface
            border.color: Qt.rgba(1, 1, 1, 0.07); border.width: 1
            opacity:   wallpaper.cardProgress
            transform: Translate { y: (1.0 - wallpaper.cardProgress) * 30 }

            Column {
                anchors {
                    top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom
                    topMargin: 20; leftMargin: 20; rightMargin: 20; bottomMargin: 20
                }
                spacing: 12

                // ── header pill ───────────────────────────────────
                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Colors.md3.surface_container

                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        Text {
                            text: "󰸉"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 18
                            color: Colors.md3.primary; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Wallpaper"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                            color: Colors.md3.on_surface; anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: wallpaper.wallList.length > 0
                            width: badge.width + 16; height: 22; radius: 11
                            color: Colors.md3.primary_container
                            Text {
                                id: badge
                                anchors.centerIn: parent
                                text: wallpaper.wallList.length
                                font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10
                                color: Colors.md3.on_primary_container
                            }
                        }
                    }
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 28; height: 28; radius: 14
                        color: wpClose.containsMouse ? Colors.md3.surface_container_high : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "󰅖"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14; color: Colors.md3.on_surface_variant }
                        MouseArea { id: wpClose; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaper.close() }
                    }
                }

                // ── scanning state ────────────────────────────────
                Item {
                    width: parent.width
                    height: parent.height - 44 - 12 - 48 - 12
                    visible: wallpaper.wallList.length === 0
                    Column {
                        anchors.centerIn: parent; spacing: 10
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰔟"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 36
                            color: Colors.md3.on_surface_variant
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Scanning wallpapers…"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12
                            color: Colors.md3.on_surface_variant
                        }
                    }
                }

                // ── grid ──────────────────────────────────────────
                Flickable {
                    id: gridFlick
                    width:         parent.width
                    height:        parent.height - 44 - 12 - 48 - 12
                    visible:       wallpaper.wallList.length > 0
                    contentHeight: wallGrid.height
                    clip:          true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { radius: 3; color: Colors.md3.outline_variant; implicitWidth: 4 }
                    }

                    Connections {
                        target: wallpaper
                        function onSelectedIndexChanged() {
                            var row   = Math.floor(wallpaper.selectedIndex / 3)
                            var itemH = 152 + 8
                            var top   = row * itemH
                            var bot   = top + itemH
                            if (gridFlick.contentY > top) gridFlick.contentY = top
                            if (gridFlick.contentY + gridFlick.height < bot) gridFlick.contentY = bot - gridFlick.height
                        }
                    }

                    Grid {
                        id: wallGrid
                        width:   parent.width
                        columns: 3
                        spacing: 8

                        Repeater {
                            model: wallpaper.wallList
                            delegate: Rectangle {
                                required property string modelData
                                required property int    index

                                property bool isSelected: wallpaper.selectedIndex === index
                                property bool hov:        thumbMA.containsMouse

                                width:  (wallGrid.width - 16) / 3
                                height: 152
                                radius: 0
                                color:  "transparent"
                                border.color: isSelected ? Colors.md3.primary : Qt.rgba(1,1,1,0.06)
                                border.width: isSelected ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on scale        { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                scale: (isSelected || hov) ? 1.04 : 1.0

                                Image {
                                    anchors { fill: parent; margins: parent.isSelected ? 3 : 1 }
                                    source:       "file://" + wallpaper.wallDir + "/" + modelData.split("/").pop()
                                    fillMode:     Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth:       false   // no smoothing = faster thumbnail render
                                    clip:         true

                                    // placeholder while loading
                                    Rectangle {
                                        anchors.fill: parent
                                        color:   Colors.md3.surface_container
                                        visible: parent.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent; text: "󰸉"
                                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 24
                                            color: Colors.md3.on_surface_variant; opacity: 0.35
                                        }
                                    }
                                }

                                // selected glow ring — drawn as border already above
                                // hover dim overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius - 1
                                    color: Qt.rgba(1, 1, 1, hov && !isSelected ? 0.06 : 0.0)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    id: thumbMA
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: wallpaper.selectedIndex = index
                                    onClicked: wallpaper.applyWall(modelData)
                                }
                            }
                        }
                    }
                }

                // ── footer ────────────────────────────────────────
                Rectangle {
                    width: parent.width; height: 48; radius: 24
                    color: Colors.md3.surface_container

                    Row {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰸉"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 13
                            color: Colors.md3.on_surface_variant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (wallpaper.wallList.length > 0 && wallpaper.selectedIndex < wallpaper.wallList.length)
                                ? wallpaper.wallList[wallpaper.selectedIndex].split("/").pop()
                                : "No wallpaper selected"
                            font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11
                            color: Colors.md3.on_surface_variant
                            elide: Text.ElideMiddle; width: 430
                        }
                    }

                    Rectangle {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 90; height: 32; radius: 16
                        visible: wallpaper.wallList.length > 0
                        color: applyBtn.containsMouse ? Colors.md3.primary : Colors.md3.primary_container
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰄬"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 14; color: applyBtn.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container; Behavior on color { ColorAnimation { duration: 120 } } }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Apply"; font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12; color: applyBtn.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container; Behavior on color { ColorAnimation { duration: 120 } } }
                        }
                        MouseArea { id: applyBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wallpaper.applyWall(wallpaper.wallList[wallpaper.selectedIndex]) }
                    }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "."

Rectangle {
    id: playerPopup
    width: 380
    height: col.height + 80
    radius: 16
    color: Colors.md3.surface
    border.width: 1
    border.color: Colors.md3.outline_variant

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    // position polling — only ticks while playing
    Timer {
        interval: 1000
        repeat: true
        running: playerPopup.player ? playerPopup.player.isPlaying : false
        onTriggered: if (playerPopup.player) playerPopup.player.positionChanged()
    }

    function fmt(secs) {
        if (!secs || secs < 0) return "0:00"
        var m = Math.floor(secs / 60)
        var s = Math.floor(secs % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    Column {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 18

        // ── Album art + track info ────────────────────────────────
        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                width: 56
                height: 56
                radius: 10
                color: Colors.md3.surface_container_high
                clip: true

                Image {
                    anchors.fill: parent
                    source: playerPopup.player ? playerPopup.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: playerPopup.player && playerPopup.player.trackArtUrl !== ""
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: !playerPopup.player || playerPopup.player.trackArtUrl === ""
                    text: "󰎆"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 28
                    color: Colors.md3.on_surface_variant
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 56 - 12
                spacing: 3

                Text {
                    width: parent.width
                    text: playerPopup.player
                        ? (playerPopup.player.trackTitle || "Unknown title")
                        : "Nothing playing"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: playerPopup.player
                        ? (playerPopup.player.trackArtist || "Unknown artist")
                        : ""
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: playerPopup.player ? playerPopup.player.identity : ""
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 10
                    color: Colors.md3.primary
                    elide: Text.ElideRight
                }
            }
        }

        // ── Progress bar ──────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 4
            visible: playerPopup.player !== null

            Rectangle {
                id: progressTrack
                width: parent.width
                height: 4
                radius: 2
                color: Colors.md3.surface_container_high

                Rectangle {
                    id: progressFill
                    width: {
                        if (!playerPopup.player) return 0
                        var len = playerPopup.player.length
                        if (!len || len <= 0) return 0
                        return Math.min(1, playerPopup.player.position / len) * progressTrack.width
                    }
                    height: parent.height
                    radius: parent.radius
                    color: Colors.md3.primary
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (!playerPopup.player || !playerPopup.player.canSeek) return
                        var ratio = mouse.x / width
                        playerPopup.player.position = ratio * playerPopup.player.length
                    }
                }
            }

            Row {
                width: parent.width

                Text {
                    id: posLabel
                    text: playerPopup.player ? playerPopup.fmt(playerPopup.player.position) : "0:00"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                }

                Item { width: parent.width - posLabel.width - durLabel.width; height: 1 }

                Text {
                    id: durLabel
                    text: playerPopup.player ? playerPopup.fmt(playerPopup.player.length) : "0:00"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                }
            }
        }

 

        // ── Controls ─────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            // Previous
            Rectangle {
                width: 38; height: 38; radius: 19
                color: prevArea.pressed
                    ? Colors.md3.surface_container_high
                    : prevArea.containsMouse
                        ? Colors.md3.surface_container_high
                        : Colors.md3.surface_container
                opacity: playerPopup.player ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 18
                    color: Colors.md3.on_surface
                }

                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (!playerPopup.player) return
                        playerPopup.player.previous()
                    }
                }
            }

            // Play / Pause
            Rectangle {
                width: 48; height: 48; radius: 24
                color: Colors.md3.primary
                opacity: playerPopup.player ? 1.0 : 0.35

                Text {
                    anchors.centerIn: parent
                    text: playerPopup.player && playerPopup.player.isPlaying ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 22
                    color: Colors.md3.on_primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!playerPopup.player) return
                        playerPopup.player.togglePlaying()
                    }
                }
            }

            // Next
            Rectangle {
                width: 38; height: 38; radius: 19
                color: nextArea.pressed
                    ? Colors.md3.surface_container_high
                    : nextArea.containsMouse
                        ? Colors.md3.surface_container_high
                        : Colors.md3.surface_container
                opacity: playerPopup.player ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 18
                    color: Colors.md3.on_surface
                }

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (!playerPopup.player) return
                        playerPopup.player.next()
                    }
                }
            }
        }
    }
}

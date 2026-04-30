import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import ".."

PanelWindow {
    id: root

    anchors.top: true
    margins.top: 80

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "osd"

    width: 240
    height: 60
    color: "transparent"
    visible: false

    readonly property int pillHeight: 42
    readonly property int pillRadius: 1000

    property bool isActive: false
    property real animatedValue: 0

    // ── Bind the default sink so .audio.volume / .audio.muted work ──
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Convenience shorthands
    readonly property real  rawVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool  muted:     Pipewire.defaultAudioSink?.audio?.muted  ?? false
    readonly property int   volPct:    Math.round(rawVolume * 100)

    readonly property string icon: muted ? "󰝟" : volPct < 33 ? "󰕿" : volPct < 66 ? "󰖀" : "󰕾"

    // Watch volume/mute changes and show OSD
    onVolPctChanged: showOsd()
    onMutedChanged:  showOsd()

    function showOsd() {
        root.animatedValue = root.volPct
        if (!root.isActive) {
            root.isActive = true
            root.visible  = true
        }
        hideTimer.restart()
    }

    Behavior on animatedValue {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 0.3
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.isActive = false
            hideDelayTimer.start()
        }
    }

    Timer {
        id: hideDelayTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.isActive) root.visible = false
        }
    }

    // ── UI ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  parent.width
        height: root.pillHeight
        radius: root.pillRadius
        color:  Colors.md3.surface_container_low

        opacity: root.isActive ? 1 : 0
        scale:   root.isActive ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.2 }
        }

        layer.enabled: true
        layer.smooth:  true

        // Subtle border
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(
                Colors.md3.outline.r,
                Colors.md3.outline.g,
                Colors.md3.outline.b,
                0.1
            )
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: root.icon
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: root.muted ? Colors.md3.on_surface_variant : Colors.md3.primary
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                height: 6
                width:  120
                radius: 3
                color:  Colors.md3.surface_container_highest
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Rectangle {
                    height: parent.height
                    width:  parent.width * (Math.min(root.animatedValue, 100) / 100)
                    radius: 3
                    color:  root.muted ? Colors.md3.on_surface_variant : Colors.md3.primary
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Text {
                text: root.muted ? "muted" : Math.round(root.animatedValue) + "%"
                font.family:    "Google Sans Flex"
                font.pixelSize: 12
                font.weight:    Font.Medium
                color: Colors.md3.on_surface
                anchors.verticalCenter: parent.verticalCenter
                width: 35
                horizontalAlignment: Text.AlignRight
                renderType: Text.NativeRendering
            }
        }
    }
}

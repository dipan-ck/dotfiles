import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick.Controls
import QtQuick
import ".."

PanelWindow {
    id: osd

    visible: false

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "osd"
    exclusionMode: ExclusionMode.Ignore

anchors.bottom: true
margins.bottom: 100
    width:  260
    height: 56
    color:  "transparent"

    // ── Pipewire ──────────────────────────────────────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property real rawVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool muted:     Pipewire.defaultAudioSink?.audio?.muted  ?? false
    readonly property int  volPct:    Math.round(rawVolume * 100)

    readonly property string icon:
        muted        ? "󰝟" :
        volPct === 0 ? "󰝟" :
        volPct < 33  ? "󰕿" :
        volPct < 66  ? "󰖀" : "󰕾"

    // ── state ─────────────────────────────────────────────────────
    property bool isActive:      false
    property real displayValue:  0
    property bool initialized:   false

    // skip the first binding fire on startup
    onVolPctChanged: {
        if (!initialized) { initialized = true; displayValue = volPct; return }
        showOsd()
    }
    onMutedChanged: {
        if (!initialized) return
        showOsd()
    }

    function showOsd() {
        displayValue = volPct
        isActive     = true
        visible      = true
        hideTimer.restart()
    }

    Behavior on displayValue {
        NumberAnimation { duration: 10; easing.type: Easing.OutCubic }
    }

    Timer {
        id: hideTimer
        interval: 2200; repeat: false
        onTriggered: {
            isActive = false
            hideDelay.restart()
        }
    }

    Timer {
        id: hideDelay
        interval: 320; repeat: false
        onTriggered: { if (!osd.isActive) osd.visible = false }
    }

    // ── pill ──────────────────────────────────────────────────────
    Rectangle {
  anchors.bottom: parent.bottom
anchors.horizontalCenter: parent.horizontalCenter
        width:  parent.width
        height: 50
        radius: 1000
        color:  Colors.md3.surface

        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1

        opacity: osd.isActive ? 1.0 : 0.0
        scale:   osd.isActive ? 1.0 : 0.88

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.15 } }

        Row {
            anchors.centerIn: parent
            spacing: 12

            // icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:            osd.icon
                font.family:     "JetBrainsMono Nerd Font Mono"
                font.pixelSize:  17
                color:           osd.muted ? Colors.md3.on_surface_variant : Colors.md3.primary
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            // track
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:  130
                height: 5
                radius: 3
                color:  Colors.md3.surface_container_highest

                Rectangle {
                    width:  parent.width * Math.min(osd.displayValue, 100) / 100
                    height: parent.height
                    radius: 3
                    color:  osd.muted ? Colors.md3.on_surface_variant : Colors.md3.primary
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }

            // label
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:                  osd.muted ? "muted" : Math.round(osd.displayValue) + "%"
                font.family:           "JetBrainsMono Nerd Font Mono"
                font.pixelSize:        11
                color:                 Colors.md3.on_surface
                width:                 38
                horizontalAlignment:   Text.AlignRight
            }
        }
    }
}

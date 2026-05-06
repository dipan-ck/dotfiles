import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth

Rectangle {
    id: root
    border.width: 1
    border.color: "#363535"
    property int   pillHeight:   30
    property int   pillRadius:   1000
    property color colorSurface: "#000000"
    property color colorText:    "#000000"
    property color colorPrimary: "#ffffff"
    property color colorDull:    "#555555"

    signal clicked()

    // ── WiFi / BT state ──────────────────────────────────────────────────────
    readonly property bool wifiOn: Networking.wifiEnabled

    readonly property bool btOn: {
        const a = Bluetooth.defaultAdapter
        return (a !== null && a !== undefined && a.enabled)
    }

    // ── Geometry ──────────────────────────────────────────────────────────────
    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface
    implicitWidth: pillRow.implicitWidth + 24

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing:          8

        // ── WiFi icon ────────────────────────────────────────────────────────
        Text {
            text:           "\udb82\udd28"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            renderType:     Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter

            color: root.wifiOn ? root.colorPrimary : root.colorDull
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.clicked()
            }
        }

            // ── Bluetooth icon ────────────────────────────────────────────────────
        Text {
            text:           "\uf293"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            renderType:     Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter

            color: root.btOn ? root.colorPrimary : root.colorDull
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.clicked()
            }
        }


    }
}

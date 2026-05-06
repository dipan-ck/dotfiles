import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Services"
import ".."

Rectangle {
    id: root

    property int   pillHeight:        30
    property int   pillRadius:        1000
    property color colorSurface:      "#000000"
    property color colorText:         "#000000"
    property color colorAccent:       "#000000"
    property color colorOnAccent:     "#000000"
    property color colorInactive:     "#000000"
    property color colorWarning:      "#000000"
    property Item  windowContentItem: null

    border.width: 1
    border.color: "#363535"

    readonly property real batteryPercent:  UPower.displayDevice.percentage * 100
    // onBattery = true means discharging; false means on AC (charging or full)
    readonly property bool batteryCharging: !UPower.onBattery
    readonly property bool batteryLow:      batteryPercent <= 20 && UPower.onBattery

    signal batteryClicked(real centerX, real bottomY)

    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface
    implicitWidth: sysRow.implicitWidth + 24

    Row {
        id: sysRow
        anchors.centerIn: parent
        height:  root.pillHeight
        spacing: 10

        // Screenshot
        Item {
            width:  shotIcon.implicitWidth
            height: parent.height
            Text {
                id: shotIcon
                anchors.centerIn: parent
                text:             "\udb80\udd9f"
                font.family:      "JetBrainsMono Nerd Font"
                font.pixelSize:   15
                color:            root.colorText
                renderType:       Text.NativeRendering
            }
            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Quickshell.execDetached(
                    ["sh", "-c", "hyprshot -m region --raw | satty --filename -"])
            }
        }

        // Brightness
        Item {
            id: brightnessContainer
            height:        parent.height
            implicitWidth: brightnessRow.implicitWidth

            Row {
                id: brightnessRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "\ue30d"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color:          root.colorText
                    renderType:     Text.NativeRendering
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.SizeVerCursor
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0)
                        BrightnessService.increaseBrightness(5)
                    else
                        BrightnessService.decreaseBrightness(5)
                }
            }
        }

        // Battery badge
        Rectangle {
            id: batteryBadge
            height:  root.pillHeight - 13
            width:   batteryRow.implicitWidth + 14
            radius:  root.pillRadius
            anchors.verticalCenter: parent.verticalCenter

            color: root.batteryLow ? Colors.md3.error : root.colorAccent

            border.color: root.batteryLow
                ? Qt.darker(Colors.md3.error, 1.3)
                : Qt.darker(root.colorAccent, 1.2)
            border.width: 0

            Behavior on color        { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing:          2

                // empty string collapses to zero width when not charging
                Text {
                    text:           root.batteryCharging ? "󱐋" : ""
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color:          root.batteryLow ? Colors.md3.on_error : root.colorOnAccent
                    renderType:     Text.NativeRendering
                }

                Text {
                    text:           Math.round(root.batteryPercent) 
                    font.family:    "Google Sans Flex"
                    font.pixelSize: 12
                           font.weight: 500
    font.styleName: "Medium"
                    color:          root.batteryLow ? Colors.md3.on_error : root.colorOnAccent
                    renderType:     Text.NativeRendering
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked: {
                    if (!root.windowContentItem) return
                    let p = root.mapToItem(root.windowContentItem, 0, 0)
                    root.batteryClicked(p.x + root.width / 2, p.y + root.height)
                }
            }
        }
    }
}

import QtQuick
import "../Services"

Rectangle {
    id: root

    property int   pillHeight:   30
    property int   pillRadius:   1000
    property color colorSurface: "#000000"
    property color colorText:    "#000000"
    property color colorAccent:  "#000000"

    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface
    implicitWidth: resRow.implicitWidth + 24
    border.width: 1
    border.color: "#363535"
    Row {
        id: resRow
        anchors.centerIn: parent
        spacing: 10

        // CPU
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "\uf4bc"
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color:          root.colorAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           ResourceService.cpuPerc 
                font.family:    "Google Sans Flex"
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          root.colorText
                renderType:     Text.NativeRendering
            }
        }

        // RAM
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "\uee9c"
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color:          root.colorAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           ResourceService.memoryUsedPercent
                font.family:    "Google Sans Flex"
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          root.colorText
                renderType:     Text.NativeRendering
            }
        }

        // GPU
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "\udb81\udcc5"
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color:          root.colorAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           ResourceService.gpuPerc 
                font.family:    "Google Sans Flex"
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          root.colorText
                renderType:     Text.NativeRendering
            }
        }
    }
}

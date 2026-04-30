import QtQuick

Rectangle {
    id: root

    property int   pillHeight:   30
    property int   pillRadius:   1000
    property color colorSurface: "#000000"
    property color colorAccent:  "#000000"

    height: pillHeight
    width:  height
    radius: pillRadius
    color:  colorSurface

    Text {
        anchors.centerIn: parent
        text:             "󰣇"
        font.family:      "JetBrainsMono Nerd Font"
        font.pixelSize:   20
        font.weight:      Font.Bold
        color:            root.colorAccent
        renderType:       Text.NativeRendering
    }
}

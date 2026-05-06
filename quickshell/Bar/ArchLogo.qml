import QtQuick

Rectangle {
    id: root

    property int   pillHeight:   30
    property int   pillRadius:   1000
    property color colorSurface: "#000000"
    property color colorAccent:  "#000000"
    border.width: 1
    border.color: "#363535"

    height: pillHeight
    width:  height + 8
    radius: pillRadius
    color:  colorSurface

    Text {
        anchors.centerIn: parent
        text:             "󰣇"
        font.family:      "JetBrainsMono Nerd Font"
        font.pixelSize:   18
        font.weight:      Font.Bold
        color:            root.colorAccent
        renderType:       Text.NativeRendering
    }
}

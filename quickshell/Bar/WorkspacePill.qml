import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root

    property int   pillHeight:    30
    property int   pillRadius:    1000
    property color colorSurface:  "#000000"
    property color colorAccent:   "#000000"
    property color colorOnAccent: "#000000"
    property color colorText:     "#000000"
    property color colorInactive: "#000000"

    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface
    implicitWidth: workspaceRow.implicitWidth + 16

    Item {
        anchors.fill: parent

        Rectangle {
            id: highlighter
            readonly property real baseSize: parent.height - 6
            height:  baseSize
            width:   baseSize
            radius:  root.pillRadius
            color:   root.colorAccent
            anchors.verticalCenter: parent.verticalCenter
            x: 8 + Math.max(0,
                   (Hyprland.focusedWorkspace
                        ? Hyprland.focusedWorkspace.id - 1 : 0)
                   ) * (baseSize + 8)
            Behavior on x {
                NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
            }
        }

        Row {
            id: workspaceRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: 9
                Item {
                    width:  24
                    height: 24
                    property var  ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    property bool active: Hyprland.focusedWorkspace
                        && Hyprland.focusedWorkspace.id === (index + 1)

                    Text {
                        anchors.centerIn: parent
                        text:             index + 1
                        font.family:      "Google Sans Flex"
                        font.pixelSize:   13
                                               font.weight: 500
    font.styleName: "Medium"
                        color:            active ? root.colorOnAccent
                                         : (ws   ? root.colorText
                                                  : root.colorInactive)
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }
        }
    }
}

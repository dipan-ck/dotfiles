import QtQuick

Rectangle {
    id: root

    property int   pillHeight:        30
    property int   pillRadius:        1000
    property color colorSurface:      "#000000"
    property color colorText:         "#000000"
    property Item  windowContentItem: null

    signal clicked(real centerX, real bottomY)

    // Internal time/date state
    property string _time: ""
    property string _date: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            root._time = Qt.formatDateTime(now, "hh:mm AP")
            root._date = Qt.formatDateTime(now, "d MMM")
        }
    }

    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface
    implicitWidth: row.implicitWidth + 24

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: timeText
            text:           root._time
            font.family:    "Google Sans Flex"
            font.pixelSize: 13
            font.weight:    500
            font.styleName: "Medium"
            color:          root.colorText
            renderType:     Text.NativeRendering
        }

        Text {
            text:           "·"
            font.family:    "Google Sans Flex"
            font.pixelSize: 13
            font.weight:    500
            font.styleName: "Medium"
            color:          root.colorText
            renderType:     Text.NativeRendering
            opacity:        0.5
        }

        Text {
            id: dateText
            text:           root._date
            font.family:    "Google Sans Flex"
            font.pixelSize: 13
            font.weight:    500
            font.styleName: "Medium"
            color:          root.colorText
            renderType:     Text.NativeRendering
            opacity:        0.75
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            if (!root.windowContentItem) return
            let p = root.mapToItem(root.windowContentItem, 0, 0)
            root.clicked(p.x + root.width / 2, p.y + root.height)
        }
    }
}

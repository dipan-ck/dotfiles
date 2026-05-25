import QtQuick
import "."

Rectangle {
    id: calendar

    property var today: new Date()
    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth()

    // helper — days in a month
    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    // helper — what weekday does the 1st fall on (0=Sun)
    function firstDayOfMonth(y, m) {
        return new Date(y, m, 1).getDay()
    }

    function prevMonth() {
        if (displayMonth === 0) { displayMonth = 11; displayYear-- }
        else displayMonth--
    }

    function nextMonth() {
        if (displayMonth === 11) { displayMonth = 0; displayYear++ }
        else displayMonth++
    }

    color: Colors.md3.surface
    radius: 16
    border.width: 1
    border.color: Colors.md3.outline_variant
    width: 280
    height: calendarCol.height + 260

    Column {
        id: calendarCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 12
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 8

        // ── Month nav ─────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 0

            // prev
            Rectangle {
                width: 28; height: 28; radius: 8
                color: prevArea.containsMouse
                    ? Colors.md3.surface_container_high
                    : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰍞"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                    color: Colors.md3.on_surface
                }
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendar.prevMonth()
                }
            }

            // month + year label
            Text {
                width: parent.width - 56
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(displayYear, displayMonth, 1), "MMMM yyyy")
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Colors.md3.on_surface
            }

            // next
            Rectangle {
                width: 28; height: 28; radius: 8
                color: nextArea.containsMouse
                    ? Colors.md3.surface_container_high
                    : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰍟"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                    color: Colors.md3.on_surface
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendar.nextMonth()
                }
            }
        }

        // ── Day headers ───────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 0

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                Text {
                    width: (calendarCol.width) / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                }
            }
        }

        // ── Day grid ──────────────────────────────────────────────────
        Grid {
            id: dayGrid
            width: parent.width
            columns: 7
            spacing: 0

            Repeater {
                model: firstDayOfMonth(displayYear, displayMonth)
                Item { width: (dayGrid.width) / 7; height: 32 }
            }

            Repeater {
                model: daysInMonth(displayYear, displayMonth)

                Rectangle {
                    property int day: index + 1
                    property bool isToday:
                        day === today.getDate() &&
                        displayMonth === today.getMonth() &&
                        displayYear === today.getFullYear()

                    width: (dayGrid.width) / 7
                    height: 32
                    radius: 16
                    color: isToday
                        ? Colors.md3.primary
                        : dayHover.containsMouse
                            ? Colors.md3.surface_container_high
                            : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: day
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12
                        color: isToday
                            ? Colors.md3.on_primary
                            : Colors.md3.on_surface
                    }

                    MouseArea {
                        id: dayHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}

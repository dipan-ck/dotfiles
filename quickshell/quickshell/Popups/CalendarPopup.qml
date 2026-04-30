import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../Services"
import  ".."

PopupWindow {
    id: root

    width:  320
    height: contentCol.implicitHeight + 24
    color:  "transparent"

    // ── Design tokens (mirrors NotificationPanel) ─────────────────────────────
    readonly property color  colorSurface:    Colors.md3.surface_container_low
    readonly property color  colorSection:    Colors.md3.surface_container
    readonly property color  colorHigh:       Colors.md3.surface_container_highest
    readonly property color  colorPrimary:    Colors.md3.primary
    readonly property color  colorOnPrimary:  Colors.md3.on_primary
    readonly property color  colorOnSurface:  Colors.md3.on_surface
    readonly property color  colorMuted:      Colors.md3.on_surface_variant
    readonly property color  colorSubtle:     Colors.md3.outline_variant
    readonly property string fontSans:        "Google Sans Flex"
    readonly property string fontMono:        "JetBrainsMono Nerd Font"

    // ── State ─────────────────────────────────────────────────────────────────
    property var  _now:           new Date()
    property int  _viewYear:      _now.getFullYear()
    property int  _viewMonth:     _now.getMonth()
    property int  _todayDay:      _now.getDate()
    property int  _todayMonth:    _now.getMonth()
    property int  _todayYear:     _now.getFullYear()
    property int  _selectedDay:   _now.getDate()
    property int  _selectedMonth: _now.getMonth()
    property int  _selectedYear:  _now.getFullYear()

    onVisibleChanged: {
        if (!visible) return
        _now           = new Date()
        _todayDay      = _now.getDate()
        _todayMonth    = _now.getMonth()
        _todayYear     = _now.getFullYear()
        _viewYear      = _todayYear
        _viewMonth     = _todayMonth
        _selectedDay   = _todayDay
        _selectedMonth = _todayMonth
        _selectedYear  = _todayYear
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    readonly property var _monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var _dayNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    function _daysInMonth(y, m)  { return new Date(y, m + 1, 0).getDate() }
    function _firstWeekday(y, m) { return new Date(y, m, 1).getDay() }

    function _prevMonth() {
        if (_viewMonth === 0) { _viewMonth = 11; _viewYear-- }
        else _viewMonth--
    }
    function _nextMonth() {
        if (_viewMonth === 11) { _viewMonth = 0; _viewYear++ }
        else _viewMonth++
    }
    function _isToday(d)    { return d === _todayDay    && _viewMonth === _todayMonth    && _viewYear === _todayYear    }
    function _isSelected(d) { return d === _selectedDay && _viewMonth === _selectedMonth && _viewYear === _selectedYear }

    function _buildCells() {
        var cells  = []
        var offset = _firstWeekday(_viewYear, _viewMonth)
        for (var i = 0; i < offset; i++)                        cells.push(0)
        for (var d = 1; d <= _daysInMonth(_viewYear, _viewMonth); d++) cells.push(d)
        while (cells.length % 7 !== 0)                          cells.push(0)
        return cells
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       20
        color:        root.colorSurface
        border.width: 0
        border.color: root.colorSubtle
        layer.enabled: true

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top; topMargin: 14
                left: parent.left; leftMargin: 16
                right: parent.right; rightMargin: 16
                bottom: parent.bottom; bottomMargin: 14
            }
            spacing: 10

            // ── Month navigator ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                // Prev button
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: prevHov.containsMouse ? root.colorSection : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍞"
                        font.family:    root.fontMono
                        font.pixelSize: 16
                        color:          root.colorMuted
                        renderType:     Text.NativeRendering
                    }
                    MouseArea {
                        id: prevHov; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root._prevMonth()
                    }
                }

                // Month + year
                Text {
                    Layout.fillWidth:    true
                    horizontalAlignment: Text.AlignHCenter
                    text:           root._monthNames[root._viewMonth] + "   " + root._viewYear
                    color:          root.colorOnSurface
                    font.family:    root.fontSans
                    font.pixelSize: 14
                    font.weight:    Font.SemiBold
                    renderType:     Text.NativeRendering
                }

                // Next button
                Rectangle {
                    width: 30; height: 30; radius: 15
                    color: nextHov.containsMouse ? root.colorSection : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰍟"
                        font.family:    root.fontMono
                        font.pixelSize: 16
                        color:          root.colorMuted
                        renderType:     Text.NativeRendering
                    }
                    MouseArea {
                        id: nextHov; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root._nextMonth()
                    }
                }
            }

            // ── Day-of-week headers ───────────────────────────────────────
            Row {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: root._dayNames
                    Text {
                        width:               contentCol.width / 7
                        horizontalAlignment: Text.AlignHCenter
                        text:                modelData
                        color:               root.colorMuted
                        font.family:         root.fontSans
                        font.pixelSize:      11
                        font.weight:         Font.Medium
                        renderType:          Text.NativeRendering
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color:  root.colorSubtle
                opacity: 0.6
            }

            // ── Day grid ──────────────────────────────────────────────────
            Grid {
                Layout.fillWidth: true
                columns: 7
                spacing: 0

                Repeater {
                    model: { root._viewMonth; root._viewYear; return root._buildCells() }

                    delegate: Item {
                        readonly property int day: modelData
                        width:  contentCol.width / 7
                        height: 36

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30; height: 30; radius: 15
                            visible: day > 0

                            color: {
                                if (root._isSelected(day)) return root.colorPrimary
                                if (dayHov.containsMouse)  return root.colorSection
                                return "transparent"
                            }
                            border.width: root._isToday(day) && !root._isSelected(day) ? 1.5 : 0
                            border.color: root.colorPrimary
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:            day > 0 ? day : ""
                                font.family:     root.fontSans
                                font.pixelSize:  13
                                                                               font.weight: 500
    font.styleName: "Medium"
                                renderType:      Text.NativeRendering
                                color: {
                                    if (root._isSelected(day)) return root.colorOnPrimary
                                    if (root._isToday(day))    return root.colorPrimary
                                    return root.colorOnSurface
                                }
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }

                        MouseArea {
                            id:           dayHov
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled:      day > 0
                            cursorShape:  day > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root._selectedDay   = day
                                root._selectedMonth = root._viewMonth
                                root._selectedYear  = root._viewYear
                            }
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color:  root.colorSubtle
                opacity: 0.6
            }

            // ── Today pill ────────────────────────────────────────────────
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                height:  28
                width:   todayTxt.implicitWidth + 24
                radius:  14
                color:   todayHov.containsMouse ? root.colorPrimary : root.colorSection
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id:              todayTxt
                    anchors.centerIn: parent
                    text:            "Today"
                    font.family:     "Google Sans Flex"
                    font.pixelSize:  12
                    font.weight:     Font.Medium
                    renderType:      Text.NativeRendering
                    color: todayHov.containsMouse ? root.colorOnPrimary : root.colorMuted
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id:           todayHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root._viewYear     = root._todayYear
                        root._viewMonth    = root._todayMonth
                        root._selectedDay  = root._todayDay
                        root._selectedMonth = root._todayMonth
                        root._selectedYear  = root._todayYear
                    }
                }
            }
        }
    }
}

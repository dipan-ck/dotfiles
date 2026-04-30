import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    property int   pillHeight:    30
    property int   pillRadius:    12
    property color colorSurface:  "#1e1e2e"
    property color colorText:     "#cdd6f4"
    property color colorAccent:   "#89b4fa"
    property color colorWarning:  "#f38ba8"
    property color colorInactive: "#585b70"

    property var windowContentItem: null

    height:        pillHeight
    radius:        pillRadius
    color:         colorSurface

    // ── Deduplicate toplevels by appId ────────────────────────────────────
    // One icon per unique app; clicking focuses the most recently active window
    readonly property var uniqueApps: {
        const seen = {}
        const result = []
        for (const t of ToplevelManager.toplevels.values) {
            if (t.appId && !seen[t.appId]) {
                seen[t.appId] = true
                result.push(t)
            }
        }
        return result
    }

    // Helper: is any window of this appId currently activated?
    function isAppActive(appId) {
        for (const t of ToplevelManager.toplevels.values) {
            if (t.appId === appId && t.activated) return true
        }
        return false
    }

    // Helper: focus all windows of this appId (cycle / raise)
    function activateApp(appId) {
        for (const t of ToplevelManager.toplevels.values) {
            if (t.appId === appId) { t.activate(); return }
        }
    }

    readonly property int trayCount:     SystemTray.items.values.length
    readonly property int windowCount:   uniqueApps.length
    readonly property bool hasAnything:  trayCount > 0 || windowCount > 0

    visible:       hasAnything
    implicitWidth: hasAnything ? (mainRow.implicitWidth + 20) : 0

    Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 4

        // ── Section 1: Open windows (from ToplevelManager) ────────────────
        Repeater {
            model: root.uniqueApps

            delegate: Item {
                id: winWrapper

                required property var modelData  // a Toplevel

                readonly property string appId:    modelData.appId
                readonly property bool   isActive: root.isAppActive(appId)

                // Re-evaluate isActive whenever toplevels change
                Connections {
                    target: ToplevelManager
                    // ObjectModel doesn't have a simple changed signal,
                    // so we use a timer to poll activated state
                }

                width:  22
                height: root.pillHeight

                // ── App icon via DesktopEntries ──────────────────────────
                IconImage {
                    id: winIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter:   parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                    width:        16
                    height:       16
                    implicitSize: 16
                    // Look up icon from the desktop entry; fall back to appId as icon name
                    source: {
                        const entry = DesktopEntries.byId(winWrapper.appId)
                        if (entry && entry.icon) return "image://icon/" + entry.icon
                        return "image://icon/" + winWrapper.appId
                    }
                    mipmap:       true
                    asynchronous: true

                    opacity: winWrapper.isActive ? 1.0 : 0.65
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // ── Active indicator dot ─────────────────────────────────
                Rectangle {
                    width:  4
                    height: 4
                    radius: 2
                    color:  winWrapper.isActive ? root.colorAccent : root.colorInactive
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom:           parent.bottom
                    anchors.bottomMargin:     2
                    visible: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id:           winArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color:  winArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    onClicked: root.activateApp(winWrapper.appId)
                }
            }
        }

        // ── Divider (only shown when both sections have items) ────────────
        Rectangle {
            visible: root.windowCount > 0 && root.trayCount > 0
            width:   1
            height:  root.pillHeight * 0.5
            color:   root.colorInactive
            opacity: 0.4
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Section 2: System tray icons ──────────────────────────────────
        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayWrapper

                required property var modelData

                readonly property bool isAttention: modelData.status === SystemTray.Status.NeedsAttention
                readonly property bool isPassive:   modelData.status === SystemTray.Status.Passive

                width:  18
                height: root.pillHeight

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    width:        14
                    height:       14
                    implicitSize: 14
                    source:       trayWrapper.modelData.icon
                    mipmap:       true
                    asynchronous: true

                    opacity: trayWrapper.isPassive ? 0.4 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    SequentialAnimation on opacity {
                        running: trayWrapper.isAttention
                        loops:   Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                // Attention badge dot
                Rectangle {
                    visible: trayWrapper.isAttention
                    width:   4
                    height:  4
                    radius:  2
                    color:   root.colorWarning
                    anchors {
                        right:        trayIcon.right
                        bottom:       trayIcon.bottom
                        rightMargin:  -1
                        bottomMargin: -1
                    }
                }

                MouseArea {
                    id:              trayArea
                    anchors.fill:    parent
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape:     Qt.PointingHandCursor

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color:  trayArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (trayWrapper.modelData.onlyMenu) {
                                if (trayWrapper.modelData.hasMenu && root.windowContentItem) {
                                    const pos = trayWrapper.mapToItem(null, trayWrapper.width / 2, trayWrapper.height)
                                    trayWrapper.modelData.display(root.windowContentItem, pos.x, pos.y)
                                }
                            } else {
                                trayWrapper.modelData.activate()
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (trayWrapper.modelData.hasMenu && root.windowContentItem) {
                                const pos = trayWrapper.mapToItem(null, trayWrapper.width / 2, trayWrapper.height)
                                trayWrapper.modelData.display(root.windowContentItem, pos.x, pos.y)
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayWrapper.modelData.secondaryActivate()
                        }
                    }

                    onWheel: (wheel) => {
                        trayWrapper.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
}

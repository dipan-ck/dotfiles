import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    // ── Mode: "apps" or "files" ───────────────────────────────
    property string activeTab: "apps"

    // ── Visibility ────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
            searchField.text = ""
            query = ""
            if (activeTab === "apps") refreshFilter()
            else refreshFileFilter()
        }
    }

    Keys.onEscapePressed: {
        root.visible = false
        searchField.text = ""
    }

    // ── State ─────────────────────────────────────────────────
    property string query: ""
    property bool isSearching: query.trim().length > 0
    property bool isMathExpression: false
    property string mathResult: ""
    property var filteredApps: []

    // ── File search state ─────────────────────────────────────
    property var fileResults: []
    property int fileSelectedIndex: 0

    // ── App scoring & filter ──────────────────────────────────
    function scoreEntry(entry, q) {
        if (!q) return 0
        const name        = (entry.name        || "").toLowerCase()
        const id          = (entry.id           || "").toLowerCase()
        const genericName = (entry.genericName  || "").toLowerCase()
        const comment     = (entry.comment      || "").toLowerCase()
        const keywords    = (entry.keywords     || []).join(" ").toLowerCase()
        const categories  = (entry.categories   || []).join(" ").toLowerCase()

        let score = 0
        if (name === q)                                   score += 1000
        else if (name.startsWith(q))                      score += 500
        else if (new RegExp("\\b" + q).test(name))        score += 300
        else if (name.includes(q))                        score += 200

        if (id.replace(".desktop","").startsWith(q))      score += 150
        else if (id.includes(q))                          score += 80

        if (genericName.startsWith(q))                    score += 100
        else if (genericName.includes(q))                 score += 50

        if (keywords.includes(q))                         score += 120
        if (comment.includes(q))                          score += 30
        if (categories.includes(q))                       score += 20

        return score
    }

    Timer {
        id: filterTimer
        interval: 40
        onTriggered: root.refreshFilter()
    }

    function refreshFilter() {
        const q = query.toLowerCase().trim()
        const entries = DesktopEntries.applications.values
        const results = []

        for (const entry of entries) {
            if (entry.noDisplay) continue
            if (!q) {
                results.push({ entry, score: 0 })
            } else {
                const score = scoreEntry(entry, q)
                if (score > 0) results.push({ entry, score })
            }
        }

        results.sort((a, b) => b.score - a.score)
        filteredApps = results.slice(0, 9).map(x => x.entry)
        appList.currentIndex = 0
    }

    // ── Math ──────────────────────────────────────────────────
    function isMathQuery(text) {
        const trimmed = text.trim()
        return /^[\d\s+\-*/%.()\^πe]+$/.test(trimmed) &&
               /[+\-*/%^]/.test(trimmed) &&
               /\d/.test(trimmed)
    }

    function calculateExpression(expr) {
        try {
            const sanitized = expr
                .replace(/×/g, '*')
                .replace(/÷/g, '/')
                .replace(/\^/g, '**')
                .replace(/√(\d+\.?\d*)/g, 'Math.sqrt($1)')
                .replace(/√/g, 'Math.sqrt')
                .replace(/π/g, 'Math.PI')
                .replace(/\be\b/g, 'Math.E')
            const result = new Function('return (' + sanitized + ')')()
            if (typeof result !== 'number' || !isFinite(result)) return ""
            if (Number.isInteger(result)) return result.toString()
            return parseFloat(result.toFixed(10)).toString()
        } catch (e) { return "" }
    }

    function launchApp(index) {
        if (index < 0 || index >= filteredApps.length) return
        const app = filteredApps[index]
        if (!app) return

        try {
            app.execute()
        } catch (e) {
            console.log("Failed to launch app:", e)
        }

        root.visible = false
        searchField.text = ""
    }

    // ── File search via Process ───────────────────────────────
    property string fileQuery: ""

    Process {
        id: findProcess
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: {
                findProcess.output = this.text
                root._parseFileResults(findProcess.output)
            }
        }

        onExited: { /* done */ }
    }

    Timer {
        id: fileSearchTimer
        interval: 120
        onTriggered: root._runFileSearch()
    }

    function refreshFileFilter() {
        fileQuery = query.trim()
        fileSearchTimer.restart()
    }

    function _runFileSearch() {
        const q = fileQuery.toLowerCase()
        if (!q) {
            fileResults = []
            fileSelectedIndex = 0
            return
        }
        const home = Quickshell.env("HOME") || "/root"
        const dirs = [
            home,
            home + "/Documents",
            home + "/Downloads",
            home + "/Desktop",
            home + "/Pictures",
            home + "/Videos",
            home + "/Music",
            home + "/.config",
        ].join(" ")

        findProcess.command = [
            "bash", "-c",
            `find ${dirs} -maxdepth 4 -not -path '*/.*' -iname "*${q}*" 2>/dev/null | head -40`
        ]
        findProcess.running = true
    }

    function _parseFileResults(output) {
        if (!output || !output.trim()) {
            fileResults = []
            fileSelectedIndex = 0
            return
        }
        const lines = output.trim().split("\n").filter(l => l.length > 0)
        const parsed = lines.map(path => {
            const parts = path.split("/")
            const name = parts[parts.length - 1]
            const dir  = parts.slice(0, -1).join("/")
            const ext  = name.includes(".") ? name.split(".").pop().toLowerCase() : ""
            return { path, name, dir, ext }
        })
        fileResults = parsed.slice(0, 12)
        fileSelectedIndex = 0
    }

    function fileIcon(ext) {
        const map = {
            "pdf": "󰈦", "doc": "󰈬", "docx": "󰈬",
            "xls": "󰈛", "xlsx": "󰈛", "ppt": "󰈧", "pptx": "󰈧",
            "jpg": "󰈟", "jpeg": "󰈟", "png": "󰈟", "gif": "󰈟",
            "webp": "󰈟", "svg": "󰈟", "mp3": "󰈣", "flac": "󰈣",
            "ogg": "󰈣", "wav": "󰈣", "mp4": "󰈫", "mkv": "󰈫",
            "avi": "󰈫", "mov": "󰈫", "zip": "󰈳", "tar": "󰈳",
            "gz": "󰈳", "rar": "󰈳", "txt": "󰈮", "md": "󰈮",
            "py": "󰌠", "js": "󰌞", "ts": "󰌞", "sh": "󰆍", "qml": "󰗊",
        }
        return map[ext] || "󰈙"
    }

    function openFile(index) {
        if (index < 0 || index >= fileResults.length) return
        const f = fileResults[index]
        Quickshell.execDetached(["xdg-open", f.path])
        root.visible = false
        searchField.text = ""
    }

    onQueryChanged: {
        if (activeTab === "apps") {
            if (isMathQuery(query)) {
                isMathExpression = true
                mathResult = calculateExpression(query)
            } else {
                isMathExpression = false
                mathResult = ""
            }
            filterTimer.restart()
        } else {
            isMathExpression = false
            mathResult = ""
            refreshFileFilter()
        }
    }

    // ── Dimmed backdrop ───────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#aa000000"
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: { root.visible = false; searchField.text = "" }
        }
    }

    // ── Main layout ───────────────────────────────────────────
    Item {
        id: launcher
        anchors.top: parent.top
        anchors.topMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter
        width: 680

        opacity: root.visible ? 1 : 0
        transform: Translate { y: root.visible ? 0 : -16 }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Column {
            width: parent.width
            spacing: 10

            // ── Tab switcher ──────────────────────────────────
            Rectangle {
                width: parent.width
                height: 40
                radius: 20
                color: Colors.md3.surface_container

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "apps", icon: "󰮄", label: "Apps" },
                            { id: "files", icon: "󰉋", label: "Files" },
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: parent.height
                            radius: 16

                            color: root.activeTab === modelData.id
                                ? Colors.md3.primary
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: 180 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: root.activeTab === modelData.id
                                        ? Colors.md3.on_primary
                                        : Colors.md3.on_surface_variant
                                    renderType: Text.NativeRendering
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Text {
                                    text: modelData.label
                                    font.family: "Google Sans Flex"
                                    font.pixelSize: 13
                                    color: root.activeTab === modelData.id
                                        ? Colors.md3.on_primary
                                        : Colors.md3.on_surface_variant
                                    renderType: Text.NativeRendering
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = modelData.id
                                    searchField.text = ""
                                    root.query = ""
                                    if (root.activeTab === "apps") root.refreshFilter()
                                    else { root.fileResults = []; root.fileSelectedIndex = 0 }
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            // ── Search bar ────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 52
                radius: 26
                color: Colors.md3.surface_container_high

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: parent.radius + 2
                    color: "transparent"
                    border.width: 0
                    border.color: searchField.activeFocus
                        ? Qt.rgba(Colors.md3.primary.r, Colors.md3.primary.g, Colors.md3.primary.b, 0.5)
                        : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        text: root.isMathExpression ? "󰇃"
                            : (root.activeTab === "files" ? "󰉋" : "󰍉")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: root.isMathExpression
                            ? Colors.md3.primary
                            : (searchField.text.length > 0 ? Colors.md3.on_surface : Colors.md3.on_surface_variant)
                        renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text.length === 0
                            text: root.activeTab === "files"
                                ? "Search files in home, Documents, Downloads..."
                                : "Search apps, calculate..."
                            font.family: "Google Sans Flex"
                            font.pixelSize: 15
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                        }

                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Google Sans Flex"
                            font.pixelSize: 15
                            color: Colors.md3.on_surface
                            selectionColor: Qt.rgba(Colors.md3.primary.r, Colors.md3.primary.g, Colors.md3.primary.b, 0.3)
                            onTextChanged: root.query = text

                            Keys.onEscapePressed: function(event) {
                                if (text.length > 0) { text = "" }
                                else { root.visible = false }
                                event.accepted = true
                            }

                            Keys.onReturnPressed: function(event) {
                                if (root.isMathExpression && root.mathResult !== "") {
                                    Quickshell.clipboardText = root.mathResult
                                    root.visible = false
                                    text = ""
                                } else if (root.activeTab === "apps") {
                                    if (root.filteredApps.length > 0) {
                                        root.launchApp(appList.currentIndex)
                                    }
                                } else {
                                    if (root.fileResults.length > 0) {
                                        root.openFile(root.fileSelectedIndex)
                                    }
                                }
                                event.accepted = true
                            }

                            Keys.onDownPressed: function(event) {
                                if (root.activeTab === "apps" && !root.isMathExpression && root.filteredApps.length > 0) {
                                    appList.incrementCurrentIndex()
                                } else if (root.activeTab === "files" && root.fileResults.length > 0) {
                                    root.fileSelectedIndex = Math.min(root.fileSelectedIndex + 1, root.fileResults.length - 1)
                                }
                                event.accepted = true
                            }

                            Keys.onUpPressed: function(event) {
                                if (root.activeTab === "apps" && !root.isMathExpression && root.filteredApps.length > 0) {
                                    appList.decrementCurrentIndex()
                                } else if (root.activeTab === "files" && root.fileResults.length > 0) {
                                    root.fileSelectedIndex = Math.max(root.fileSelectedIndex - 1, 0)
                                }
                                event.accepted = true
                            }

                            Keys.onTabPressed: function(event) {
                                root.activeTab = root.activeTab === "apps" ? "files" : "apps"
                                searchField.text = ""
                                root.query = ""
                                if (root.activeTab === "apps") root.refreshFilter()
                                else { root.fileResults = []; root.fileSelectedIndex = 0 }
                                event.accepted = true
                            }
                        }
                    }

                    Rectangle {
                        visible: searchField.text.length > 0
                        width: 22; height: 22; radius: 11
                        color: Qt.rgba(Colors.md3.on_surface.r, Colors.md3.on_surface.g, Colors.md3.on_surface.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchField.text = ""
                        }
                    }
                }
            }

            // ── Math result ───────────────────────────────────
            Rectangle {
                width: parent.width
                visible: root.isMathExpression && root.mathResult !== ""
                height: visible ? 52 : 0
                radius: 16
                color: Colors.md3.surface_container_low
                clip: true

                opacity: visible ? 1 : 0
                Behavior on height  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18; anchors.rightMargin: 18
                    spacing: 14

                    Text {
                        text: "󰇃"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Colors.md3.primary
                        renderType: Text.NativeRendering
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "= " + root.mathResult
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                        color: Colors.md3.on_surface
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.clipboardText = root.mathResult
                            root.visible = false; searchField.text = ""
                        }
                    }
                }
            }

            // ── App results ───────────────────────────────────
            Rectangle {
                id: resultsContainer
                width: parent.width
                visible: root.activeTab === "apps" && !root.isMathExpression && root.filteredApps.length > 0
                height: visible ? appList.contentHeight + 12 : 0
                radius: 20
                color: Colors.md3.surface_container_low
                clip: true

                Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                ListView {
                    id: appList
                    anchors { fill: parent; margins: 6 }
                    model: root.filteredApps
                    spacing: 2
                    interactive: false
                    currentIndex: 0
                    cacheBuffer: 600
                    focus: true

                    Keys.onReturnPressed: {
                        if (currentIndex >= 0 && currentIndex < root.filteredApps.length) {
                            root.launchApp(currentIndex)
                        }
                    }

                    onCountChanged: {
                        if (count === 0) currentIndex = 0
                        else if (currentIndex >= count) currentIndex = count - 1
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: appList.width
                        height: 52
                        radius: 14
                        clip: true

                        color: appList.currentIndex === index
                            ? Colors.md3.primary
                            : (rowMouse.containsMouse
                                ? Qt.rgba(Colors.md3.on_surface.r, Colors.md3.on_surface.g, Colors.md3.on_surface.b, 0.07)
                                : "transparent")

                        Behavior on color { ColorAnimation { duration: 130 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12

                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: appList.currentIndex === index
                                    ? Qt.rgba(Colors.md3.on_primary.r, Colors.md3.on_primary.g, Colors.md3.on_primary.b, 0.15)
                                    : Qt.rgba(Colors.md3.on_surface.r, Colors.md3.on_surface.g, Colors.md3.on_surface.b, 0.06)
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    anchors.centerIn: parent
                                    width: 28; height: 28
                                    source: modelData && modelData.icon
                                        ? Quickshell.iconPath(modelData.icon, true) : ""
                                    sourceSize.width: 28; sourceSize.height: 28
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true; cache: true; smooth: true
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData ? modelData.name : ""
                                    font.family: "Google Sans Flex"; font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: appList.currentIndex === index
                                        ? Colors.md3.on_primary : Colors.md3.on_surface
                                    elide: Text.ElideRight; renderType: Text.NativeRendering
                                }

                                Text {
                                    width: parent.width
                                    visible: text.length > 0
                                    text: modelData ? (modelData.genericName || modelData.comment || "") : ""
                                    font.family: "Google Sans Flex"; font.pixelSize: 11
                                    color: appList.currentIndex === index
                                        ? Qt.rgba(Colors.md3.on_primary.r, Colors.md3.on_primary.g, Colors.md3.on_primary.b, 0.7)
                                        : Colors.md3.on_surface_variant
                                    elide: Text.ElideRight; renderType: Text.NativeRendering
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appList.currentIndex = index
                                appList.forceActiveFocus()
                            }
                            onDoubleClicked: {
                                if (modelData) {
                                    root.launchApp(index)
                                }
                            }
                        }
                    }
                }
            }

            // ── File results ──────────────────────────────────
            Rectangle {
                width: parent.width
                visible: root.activeTab === "files" && root.fileResults.length > 0
                height: visible ? fileList.contentHeight + 12 : 0
                radius: 20
                color: Colors.md3.surface_container_low
                clip: true

                Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                ListView {
                    id: fileList
                    anchors { fill: parent; margins: 6 }
                    model: root.fileResults
                    spacing: 2
                    interactive: false
                    cacheBuffer: 600

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: fileList.width
                        height: 52
                        radius: 14
                        clip: true

                        color: root.fileSelectedIndex === index
                            ? Colors.md3.primary
                            : (fileMouse.containsMouse
                                ? Qt.rgba(Colors.md3.on_surface.r, Colors.md3.on_surface.g, Colors.md3.on_surface.b, 0.07)
                                : "transparent")

                        Behavior on color { ColorAnimation { duration: 130 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12

                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: root.fileSelectedIndex === index
                                    ? Qt.rgba(Colors.md3.on_primary.r, Colors.md3.on_primary.g, Colors.md3.on_primary.b, 0.15)
                                    : Qt.rgba(Colors.md3.secondary.r, Colors.md3.secondary.g, Colors.md3.secondary.b, 0.12)
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.fileIcon(modelData ? modelData.ext : "")
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: root.fileSelectedIndex === index
                                        ? Colors.md3.on_primary : Colors.md3.secondary
                                    renderType: Text.NativeRendering
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData ? modelData.name : ""
                                    font.family: "Google Sans Flex"; font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: root.fileSelectedIndex === index
                                        ? Colors.md3.on_primary : Colors.md3.on_surface
                                    elide: Text.ElideRight; renderType: Text.NativeRendering
                                }

                                Text {
                                    width: parent.width
                                    text: modelData ? modelData.dir : ""
                                    font.family: "Google Sans Flex"; font.pixelSize: 11
                                    color: root.fileSelectedIndex === index
                                        ? Qt.rgba(Colors.md3.on_primary.r, Colors.md3.on_primary.g, Colors.md3.on_primary.b, 0.65)
                                        : Colors.md3.on_surface_variant
                                    elide: Text.ElideRight; renderType: Text.NativeRendering
                                }
                            }
                        }

                        MouseArea {
                            id: fileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.fileSelectedIndex = index
                                searchField.forceActiveFocus()
                            }
                            onDoubleClicked: root.openFile(index)
                        }
                    }
                }
            }

            // ── Empty state ───────────────────────────────────
            Rectangle {
                width: parent.width
                height: 64
                radius: 16
                color: Colors.md3.surface_container_low
                visible: root.isSearching && !root.isMathExpression &&
                         ((root.activeTab === "apps" && root.filteredApps.length === 0) ||
                          (root.activeTab === "files" && root.fileResults.length === 0))

                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "No " + (root.activeTab === "files" ? "files" : "apps") + " found"
                    font.family: "Google Sans Flex"; font.pixelSize: 14
                    color: Colors.md3.on_surface_variant
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}

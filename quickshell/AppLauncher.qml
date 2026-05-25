import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."


PanelWindow {
    id: root

    // ── Window setup ──────────────────────────────────────────────────────────
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay

    // ── Config ────────────────────────────────────────────────────────────────
    property string terminalEmulator: "kitty"
    property var    terminalArgs: ["-e"]

    // ── Public API ────────────────────────────────────────────────────────────
    function show() { visible = true }

    function hide() {
        visible = false
        searchField.text = ""
    }

    // ── Core state ────────────────────────────────────────────────────────────
    property string rawText:   ""
    property string mode:      "apps"
    property string bareQuery: ""

    property var    appResults:  []
    property var    fileResults: []
    property string calcResult:  ""
    property int    selectedIndex: 0

    // ── Mode derivation ───────────────────────────────────────────────────────
    // FIX: replaced String(t).trimStart() with t.replace(/^\s+/, "")
    // trimStart() is ES2019 and silently throws in QML's V4 JS engine,
    // which aborts the whole function before mode is ever updated.
    function applyText(t) {
        rawText = t

        // Safe cross-version trim — no trimStart() / trimEnd()
        var safeStr = (t !== null && t !== undefined) ? ("" + t).replace(/^\s+/, "") : ""
        var newMode
        var bare

        if (safeStr.charAt(0) === "=") {
            newMode = "calc"
            bare    = safeStr.slice(1).replace(/^\s+/, "")
        } else if (safeStr.charAt(0) === "/") {
            newMode = "files"
            bare    = safeStr.slice(1).replace(/^\s+/, "")
        } else {
            newMode = "apps"
            bare    = safeStr
        }

        if (newMode !== mode) selectedIndex = 0
        mode      = newMode
        bareQuery = bare

        if (newMode === "apps") {
            calcResult  = ""
            fileResults = []
            appFilterTimer.restart()
        } else if (newMode === "calc") {
            appResults    = []
            fileResults   = []
            selectedIndex = 0
            calcResult    = bare.length > 0 ? evalMath(bare) : ""
        } else if (newMode === "files") {
            appResults    = []
            calcResult    = ""
            selectedIndex = 0
            fileSearchTimer.restart()
        }
    }

    // ── Tab cycling: Apps → Files → Calc → Apps ───────────────────────────────
    function cycleMode() {
        var q = bareQuery
        if (mode === "apps")       searchField.text = "/" + q
        else if (mode === "files") searchField.text = "=" + q
        else                       searchField.text = q
        // applyText fires automatically via onTextChanged
    }

    // ── Visibility lifecycle ──────────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) {
            searchField.forceActiveFocus()
            searchField.text = ""
        }
    }

    Keys.onEscapePressed: root.hide()

    // ─────────────────────────────────────────────────────────────────────────
    // PROVIDER: Apps
    // ─────────────────────────────────────────────────────────────────────────

    Timer {
        id: appFilterTimer
        interval: 30
        onTriggered: root.refreshApps(root.bareQuery)
    }

    function fuzzyMatch(pattern, str) {
        var pi = 0
        for (var si = 0; si < str.length && pi < pattern.length; si++) {
            if (str[si] === pattern[pi]) pi++
        }
        return pi === pattern.length
    }

    function scoreApp(entry, q) {
        if (!q) return 1

        var name        = (entry.name        || "").toLowerCase()
        var genericName = (entry.genericName  || "").toLowerCase()
        var comment     = (entry.comment      || "").toLowerCase()
        var keywords    = (entry.keywords     || []).join(" ").toLowerCase()
        var categories  = (entry.categories   || []).join(" ").toLowerCase()
        var id          = (entry.id           || "").replace(".desktop", "").toLowerCase()

        var score = 0

        if (name === q)                score += 1000
        else if (name.indexOf(q) === 0) score +=  500
        else if (name.indexOf(q) >= 0)  score +=  200

        if (score === 0 && fuzzyMatch(q, name)) score += 100

        if (id.indexOf(q) === 0)          score += 80
        else if (id.indexOf(q) >= 0)      score += 40

        if (genericName.indexOf(q) === 0) score += 70
        else if (genericName.indexOf(q) >= 0) score += 30

        if (keywords.indexOf(q) >= 0)   score += 90
        if (comment.indexOf(q) >= 0)    score += 20
        if (categories.indexOf(q) >= 0) score += 15

        return score
    }

    function refreshApps(q) {
        var lq      = q.toLowerCase().replace(/^\s+|\s+$/g, "")
        var entries = DesktopEntries.applications.values
        var out     = []

        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i]
            if (entry.noDisplay) continue
            var s = scoreApp(entry, lq)
            if (s > 0) out.push({ entry: entry, score: s })
        }

        out.sort(function(a, b) { return b.score - a.score })
        appResults    = out.slice(0, 8).map(function(x) { return x.entry })
        selectedIndex = 0
    }

    function launchApp(idx) {
        if (idx < 0 || idx >= appResults.length) return
        var entry = appResults[idx]

        if (entry.runInTerminal) {
            var cmd = entry.command
            if (cmd && cmd.length > 0) {
                var args = [root.terminalEmulator]
                    .concat(root.terminalArgs)
                    .concat(cmd)
                Quickshell.execDetached({
                    command: args,
                    workingDirectory: entry.workingDirectory || ""
                })
            }
        } else {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory || ""
            })
        }

        root.hide()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROVIDER: Calculator
    // ─────────────────────────────────────────────────────────────────────────

    function evalMath(expr) {
        try {
            var s = expr
                .replace(/×/g, "*")
                .replace(/÷/g, "/")
                .replace(/\^/g, "**")
                .replace(/π/g, "Math.PI")
                .replace(/\bpi\b/gi, "Math.PI")
                .replace(/\be\b/g, "Math.E")
                .replace(/\bsqrt\b/g, "Math.sqrt")
                .replace(/√(\d+(?:\.\d*)?)/g, "Math.sqrt($1)")
                .replace(/√/g, "Math.sqrt")
                .replace(/\bsin\b/g, "Math.sin")
                .replace(/\bcos\b/g, "Math.cos")
                .replace(/\btan\b/g, "Math.tan")
                .replace(/\basin\b/g, "Math.asin")
                .replace(/\bacos\b/g, "Math.acos")
                .replace(/\batan\b/g, "Math.atan")
                .replace(/\blog\b/g, "Math.log10")
                .replace(/\bln\b/g, "Math.log")
                .replace(/\babs\b/g, "Math.abs")
                .replace(/\bfloor\b/g, "Math.floor")
                .replace(/\bceil\b/g, "Math.ceil")
                .replace(/\bround\b/g, "Math.round")
                .replace(/\bpow\b/g, "Math.pow")
                .replace(/\bmax\b/g, "Math.max")
                .replace(/\bmin\b/g, "Math.min")

            var stripped = s.replace(/Math\.[a-zA-Z0-9_]+/g, "0")
            if (!/^[\d\s\+\-\*\/%\.\(\),e]+$/i.test(stripped)) return ""

            var result = eval(s)

            if (typeof result !== "number" || !isFinite(result)) return ""
            if (Number.isInteger(result)) return String(result)
            return String(parseFloat(result.toFixed(10)))
        } catch(e) {
            return ""
        }
    }

    function copyCalcResult() {
        if (calcResult === "") return
        Quickshell.clipboardText = calcResult
        root.hide()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROVIDER: File search
    // ─────────────────────────────────────────────────────────────────────────

    property string _pendingSearch: ""

    Process {
        id: findProcess

        stdout: StdioCollector {
            onStreamFinished: root._parseFileResults(text)
        }

        onRunningChanged: {
            if (!running && root._pendingSearch !== "") {
                var q = root._pendingSearch
                root._pendingSearch = ""
                root._startFind(q)
            }
        }
    }

    Timer {
        id: fileSearchTimer
        interval: 120
        onTriggered: root._runFileSearch()
    }

    function _runFileSearch() {
        var q = bareQuery.toLowerCase().replace(/^\s+|\s+$/g, "")
        if (!q) { fileResults = []; return }

        if (findProcess.running) {
            _pendingSearch = q
            findProcess.running = false
        } else {
            _pendingSearch = ""
            _startFind(q)
        }
    }

    function _startFind(q) {
        var home = Quickshell.env("HOME") || "/root"
        var dirs = [
            home,
            home + "/Documents",
            home + "/Downloads",
            home + "/Desktop",
            home + "/Pictures",
            home + "/Videos",
            home + "/Music",
            home + "/Projects",
        ]
        var dirArgs = dirs.map(function(d) { return '"' + d + '"' }).join(" ")

        findProcess.command = [
            "bash", "-c",
            'find ' + dirArgs + ' -maxdepth 5 -not -path \'*/.*\' -iname "*' + q + '*" 2>/dev/null | head -12'
        ]
        findProcess.running = true
    }

    function _parseFileResults(output) {
        if (!output || !output.replace(/^\s+|\s+$/g, "")) { fileResults = []; return }
        var lines = output.replace(/^\s+|\s+$/g, "").split("\n").filter(function(l) { return l.length > 0 })
        fileResults = lines.map(function(path) {
            var parts = path.split("/")
            var name  = parts[parts.length - 1]
            var dir   = parts.slice(0, -1).join("/")
            var ext   = name.indexOf(".") >= 0 ? name.split(".").pop().toLowerCase() : ""
            return { path: path, name: name, dir: dir, ext: ext }
        })
        selectedIndex = 0
    }

    function fileIcon(ext) {
        var icons = {
            "pdf":  "󰈦",
            "doc":  "󰈬", "docx": "󰈬",
            "xls":  "󰈛", "xlsx": "󰈛",
            "ppt":  "󰈧", "pptx": "󰈧",
            "jpg":  "󰈟", "jpeg": "󰈟", "png": "󰈟", "gif": "󰈟",
            "webp": "󰈟", "svg":  "󰜡",
            "mp3":  "󰈣", "flac": "󰈣", "ogg": "󰈣", "wav": "󰈣",
            "mp4":  "󰈫", "mkv":  "󰈫", "avi": "󰈫", "mov": "󰈫",
            "zip":  "󰈳", "tar":  "󰈳", "gz":  "󰈳", "rar": "󰈳", "7z": "󰈳",
            "txt":  "󰈮", "md":   "󰍔",
            "py":   "󰌠", "js":   "󰌞", "ts":  "󰌞", "rs": "󱘗",
            "sh":   "󰆍", "bash": "󰆍", "zsh": "󰆍",
            "qml":  "󰗊", "cpp":  "󰙲", "c":   "󰙱", "h":  "󰙱",
            "json": "󰘦", "toml": "󰬳", "yaml":"󰬳", "yml":"󰬳",
            "html": "󰌝", "css":  "󰌜", "xml": "󰈮",
        }
        return icons[ext] || "󰈙"
    }

    function openFile(idx) {
        if (idx < 0 || idx >= fileResults.length) return
        Quickshell.execDetached(["xdg-open", fileResults[idx].path])
        root.hide()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mode metadata
    // ─────────────────────────────────────────────────────────────────────────

    function modeIcon() {
        if (mode === "calc")  return "󰇃"
        if (mode === "files") return "󰉋"
        return "󰍉"
    }

    function modePlaceholder() {
        if (mode === "calc")  return "Type an expression  ( 2^10  sin(π/2)  √16  log(100) )"
        if (mode === "files") return "Search files in home directory..."
        return "Search apps...  ( = calculator    / files    Tab to cycle )"
    }

    function modeLabel() {
        if (mode === "calc")  return "Calculator"
        if (mode === "files") return "Files"
        return "Apps"
    }

    function modeColor() {
        if (mode === "calc")  return Colors.md3.tertiary
        if (mode === "files") return Colors.md3.secondary
        return Colors.md3.primary
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Navigation / confirm
    // ─────────────────────────────────────────────────────────────────────────

    property int activeListCount: {
        if (mode === "apps")  return appResults.length
        if (mode === "files") return fileResults.length
        return 0
    }

    function confirmSelection() {
        if (mode === "apps")  { launchApp(selectedIndex);  return }
        if (mode === "calc")  { copyCalcResult();          return }
        if (mode === "files") { openFile(selectedIndex);   return }
    }

    function navigateUp() {
        if (activeListCount === 0) return
        selectedIndex = Math.max(0, selectedIndex - 1)
    }

    function navigateDown() {
        if (activeListCount === 0) return
        selectedIndex = Math.min(activeListCount - 1, selectedIndex + 1)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UI
    // ─────────────────────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }
    }

    Item {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 72
        width: 660
        height: panelColumn.implicitHeight

        opacity: root.visible ? 1 : 0
        scale:   root.visible ? 1.0 : 0.97

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Column {
            id: panelColumn
            width: parent.width
            spacing: 8

            // ── Search bar ────────────────────────────────────────────────────
            Rectangle {
                id: searchBar
                width: parent.width
                height: 44
                radius: 300
                color: Colors.md3.surface_container_low

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1.5
                    radius: parent.radius + 1.5
                    color: "transparent"
                    border.width: 0

                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: root.modeIcon()
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: searchField.text.length > 0
                            ? root.modeColor()
                            : Colors.md3.on_surface_variant
                        renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text.length === 0
                            text: root.modePlaceholder()
                            font.family: "Google Sans Flex"
                            font.pixelSize: 14
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Google Sans Flex"
                            font.pixelSize: 15
                            color: Colors.md3.on_surface
                            selectionColor: Qt.rgba(
                                Qt.color(Colors.md3.primary).r,
                                Qt.color(Colors.md3.primary).g,
                                Qt.color(Colors.md3.primary).b, 0.28)
                            clip: true

                            onTextChanged: root.applyText(text)

                            Keys.onEscapePressed: function(ev) {
                                if (text.length > 0) { text = ""; ev.accepted = true }
                                else { root.hide(); ev.accepted = true }
                            }
                            Keys.onReturnPressed:  function(ev) { root.confirmSelection(); ev.accepted = true }
                            Keys.onUpPressed:      function(ev) { root.navigateUp();       ev.accepted = true }
                            Keys.onDownPressed:    function(ev) { root.navigateDown();     ev.accepted = true }

                            // Tab cycles: Apps → Files → Calc → Apps
                            // Preserves whatever you've typed as the bare query
                            Keys.onTabPressed: function(ev) { root.cycleMode(); ev.accepted = true }
                        }
                    }


                    // Clear button
                    Rectangle {
                        visible: searchField.text.length > 0
                        width: 24; height: 24; radius: 12
                        color: Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                                       Qt.color(Colors.md3.on_surface).g,
                                       Qt.color(Colors.md3.on_surface).b, 0.10)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

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

            // ── Results container ─────────────────────────────────────────────
            Rectangle {
                id: resultsBox
                width: parent.width
                color: Colors.md3.surface_container_low
                radius: 20
                clip: true

                property bool hasContent: {
                    if (mode === "apps"  && appResults.length > 0)  return true
                    if (mode === "calc"  && calcResult !== "")       return true
                    if (mode === "files" && fileResults.length > 0) return true
                    return false
                }

                property bool showEmpty: {
                    if (rawText.length === 0) return false
                    if (mode === "apps"  && appResults.length === 0)              return true
                    if (mode === "files" && !findProcess.running
                            && fileResults.length === 0
                            && bareQuery.length > 0)                              return true
                    return false
                }

                visible: hasContent || showEmpty
                height:  visible ? contentColumn.implicitHeight + 12 : 0

                Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140 } }
                opacity: visible ? 1 : 0

                Column {
                    id: contentColumn
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.margins: 6
                    spacing: 0

                    // App results
                    Repeater {
                        id: appRepeater
                        model: (root.mode === "apps") ? root.appResults : []

                        delegate: AppResultItem {
                            required property var modelData
                            required property int index

                            width: contentColumn.width
                            entry: modelData
                            isSelected: root.selectedIndex === index
                            isFirst: index === 0
                            isLast: index === appRepeater.count - 1

                            onClicked: { root.selectedIndex = index; searchField.forceActiveFocus() }
                            onDoubleClicked: root.launchApp(index)
                        }
                    }

                    // File results
                    Repeater {
                        id: fileRepeater
                        model: (root.mode === "files") ? root.fileResults : []

                        delegate: FileResultItem {
                            required property var modelData
                            required property int index

                            width: contentColumn.width
                            fileData: modelData
                            fileExt: modelData ? root.fileIcon(modelData.ext) : "󰈙"
                            isSelected: root.selectedIndex === index

                            onClicked: { root.selectedIndex = index; searchField.forceActiveFocus() }
                            onDoubleClicked: root.openFile(index)
                        }
                    }

                    // Calc result
                    SingleResultItem {
                        visible: root.mode === "calc" && root.calcResult !== ""
                        width: contentColumn.width

                        leadIcon: "󰇃"
                        iconColor: Colors.md3.tertiary
                        primaryText: root.calcResult
                        secondaryText: "Enter to copy"
                        useMono: true
                        verb: "Copy"
                        verbColor: Colors.md3.tertiary

                        onActivated: root.copyCalcResult()
                    }

                    // Searching indicator
                    Item {
                        visible: root.mode === "files"
                                 && findProcess.running
                                 && root.fileResults.length === 0
                                 && root.bareQuery.length > 0
                        width: contentColumn.width
                        height: visible ? 48 : 0

                        Text {
                            anchors.centerIn: parent
                            text: "Searching..."
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                        }
                    }

                    // Empty state
                    Item {
                        visible: resultsBox.showEmpty
                        width: contentColumn.width
                        height: visible ? 56 : 0

                        Text {
                            anchors.centerIn: parent
                            text: mode === "files"
                                ? "No files found for \"" + bareQuery + "\""
                                : "No apps found for \"" + bareQuery + "\""
                            font.family: "Google Sans Flex"
                            font.pixelSize: 13
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }

            // ── Hint bar ──────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 28
                visible: rawText.length === 0
                opacity: visible ? 0.72 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    Repeater {
                        model: [
                            { prefix: "=", label: "calculator" },
                            { prefix: "/", label: "files" },
                            { prefix: "⇥", label: "cycle mode" },
                        ]

                        RowLayout {
                            spacing: 5

                            Rectangle {
                                width: prefixLabel.implicitWidth + 10
                                height: 18
                                radius: 4
                                color: Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                                               Qt.color(Colors.md3.on_surface).g,
                                               Qt.color(Colors.md3.on_surface).b, 0.12)

                                Text {
                                    id: prefixLabel
                                    anchors.centerIn: parent
                                    text: modelData.prefix
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: Colors.md3.on_surface_variant
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                text: modelData.label
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                color: Colors.md3.on_surface_variant
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Component: App result item
    // ─────────────────────────────────────────────────────────────────────────
    component AppResultItem: Rectangle {
        id: appItem

        property var  entry:      null
        property bool isSelected: false
        property bool isFirst:    false
        property bool isLast:     false

        signal clicked()
        signal doubleClicked()

        height: 52
        radius: 14
        clip: true

        color: isSelected
            ? Colors.md3.secondary
            : (hov.containsMouse
                ? Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                          Qt.color(Colors.md3.on_surface).g,
                          Qt.color(Colors.md3.on_surface).b, 0.07)
                : "transparent")
        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: 10
                Layout.alignment: Qt.AlignVCenter
                color: isSelected
                    ? Qt.rgba(Qt.color(Colors.md3.on_primary).r,
                              Qt.color(Colors.md3.on_primary).g,
                              Qt.color(Colors.md3.on_primary).b, 0.15)
                    : Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                              Qt.color(Colors.md3.on_surface).g,
                              Qt.color(Colors.md3.on_surface).b, 0.07)
                Behavior on color { ColorAnimation { duration: 110 } }

                Image {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    source: (entry && entry.icon) ? Quickshell.iconPath(entry.icon, true) : ""
                    sourceSize.width: 26; sourceSize.height: 26
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    smooth: true
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: entry ? entry.name : ""
                    font.family: "Google Sans Flex"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: isSelected ? Colors.md3.on_primary : Colors.md3.on_surface
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: 110 } }
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: (entry && entry.runInTerminal)
                        ? "⌨  opens in " + root.terminalEmulator
                        : (entry ? (entry.genericName || entry.comment || "") : "")
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    color: isSelected
                        ? Qt.rgba(Qt.color(Colors.md3.on_primary).r,
                                  Qt.color(Colors.md3.on_primary).g,
                                  Qt.color(Colors.md3.on_primary).b, 0.70)
                        : Colors.md3.on_surface_variant
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: 110 } }
                }
            }

            Rectangle {
                visible: isSelected
                height: 20
                width: openVerb.implicitWidth + 14
                radius: 10
                color: Qt.rgba(Qt.color(Colors.md3.on_primary).r,
                               Qt.color(Colors.md3.on_primary).g,
                               Qt.color(Colors.md3.on_primary).b, 0.20)
                opacity: isSelected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 110 } }

                Text {
                    id: openVerb
                    anchors.centerIn: parent
                    text: "Open"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Colors.md3.on_primary
                    renderType: Text.NativeRendering
                }
            }
        }

        MouseArea {
            id: hov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appItem.clicked()
            onDoubleClicked: appItem.doubleClicked()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Component: File result item
    // ─────────────────────────────────────────────────────────────────────────
    component FileResultItem: Rectangle {
        id: fileItem

        property var    fileData:   null
        property string fileExt:    "󰈙"
        property bool   isSelected: false

        signal clicked()
        signal doubleClicked()

        height: 52
        radius: 14
        clip: true

        color: isSelected
            ? Colors.md3.secondary
            : (fileHov.containsMouse
                ? Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                          Qt.color(Colors.md3.on_surface).g,
                          Qt.color(Colors.md3.on_surface).b, 0.07)
                : "transparent")
        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: 10
                Layout.alignment: Qt.AlignVCenter
                color: isSelected
                    ? Qt.rgba(Qt.color(Colors.md3.on_secondary).r,
                              Qt.color(Colors.md3.on_secondary).g,
                              Qt.color(Colors.md3.on_secondary).b, 0.18)
                    : Qt.rgba(Qt.color(Colors.md3.secondary).r,
                              Qt.color(Colors.md3.secondary).g,
                              Qt.color(Colors.md3.secondary).b, 0.12)
                Behavior on color { ColorAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: fileItem.fileExt
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: isSelected ? Colors.md3.on_secondary : Colors.md3.secondary
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: 110 } }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: fileData ? fileData.name : ""
                    font.family: "Google Sans Flex"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: isSelected ? Colors.md3.on_secondary : Colors.md3.on_surface
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: 110 } }
                }

                Text {
                    width: parent.width
                    text: fileData ? fileData.dir : ""
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    color: isSelected
                        ? Qt.rgba(Qt.color(Colors.md3.on_secondary).r,
                                  Qt.color(Colors.md3.on_secondary).g,
                                  Qt.color(Colors.md3.on_secondary).b, 0.65)
                        : Colors.md3.on_surface_variant
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: 110 } }
                }
            }

            Rectangle {
                visible: isSelected
                height: 20
                width: fileVerb.implicitWidth + 14
                radius: 10
                color: Qt.rgba(Qt.color(Colors.md3.on_secondary).r,
                               Qt.color(Colors.md3.on_secondary).g,
                               Qt.color(Colors.md3.on_secondary).b, 0.20)
                opacity: isSelected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 110 } }

                Text {
                    id: fileVerb
                    anchors.centerIn: parent
                    text: "Open"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Colors.md3.on_secondary
                    renderType: Text.NativeRendering
                }
            }
        }

        MouseArea {
            id: fileHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fileItem.clicked()
            onDoubleClicked: fileItem.doubleClicked()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Component: Single-result row (calc)
    // ─────────────────────────────────────────────────────────────────────────
    component SingleResultItem: Rectangle {
        id: singleItem

        property string leadIcon:      "󰇃"
        property string iconColor:     Colors.md3.primary
        property string primaryText:   ""
        property string secondaryText: ""
        property bool   useMono:       false
        property string verb:          "Run"
        property string verbColor:     Colors.md3.primary

        signal activated()

        height: 52
        radius: 14
        clip: true
        color: singleHov.containsMouse
            ? Qt.rgba(Qt.color(Colors.md3.on_surface).r,
                      Qt.color(Colors.md3.on_surface).g,
                      Qt.color(Colors.md3.on_surface).b, 0.07)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: 10
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(Qt.color(singleItem.iconColor).r,
                               Qt.color(singleItem.iconColor).g,
                               Qt.color(singleItem.iconColor).b, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: singleItem.leadIcon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                    color: singleItem.iconColor
                    renderType: Text.NativeRendering
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: singleItem.primaryText
                    font.family: useMono ? "JetBrainsMono Nerd Font" : "Google Sans Flex"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    visible: singleItem.secondaryText.length > 0
                    text: singleItem.secondaryText
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                height: 20
                width: verbTxt.implicitWidth + 14
                radius: 10
                color: Qt.rgba(Qt.color(singleItem.verbColor).r,
                               Qt.color(singleItem.verbColor).g,
                               Qt.color(singleItem.verbColor).b, 0.15)

                Text {
                    id: verbTxt
                    anchors.centerIn: parent
                    text: singleItem.verb
                    font.family: "Google Sans Flex"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: singleItem.verbColor
                    renderType: Text.NativeRendering
                }
            }
        }

        MouseArea {
            id: singleHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: singleItem.activated()
        }
    }
}

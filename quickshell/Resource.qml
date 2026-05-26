import Quickshell
import Quickshell.Io
import QtQuick
import "."

Rectangle {
    id: resourcePopup
    width: 400
    height: col.height + 440
    radius: 18
    color: Colors.md3.surface
    border.width: 1
    border.color: Colors.md3.outline_variant

    // ── Per-core CPU state ────────────────────────────────────────
    property var  coreUsages:    []
    property int  coreCount:     0
    property var  lastCoreTotal: []
    property var  lastCoreIdle:  []

    // ── RAM details ───────────────────────────────────────────────
    property int ramTotal:     1
    property int ramUsed:      0
    property int ramCached:    0
    property int ramAvailable: 0

    // ── GPU details ───────────────────────────────────────────────
    property int    gpuUsage:        0
    property int    gpuMemUsed:      0
    property int    gpuMemTotal:     1
    property string gpuName:         "GPU"
    property bool   gpuMemAvailable: false

    // ── SINGLE process — dumps everything at once ─────────────────
    // Format: SECTION:data lines separated by |
    // Sections: CPU_STAT, MEM, GPU_BUSY, GPU_MEM
    Process {
        id: statsProc
        command: ["sh", "-c", [
            // CPU: all cpu* lines from /proc/stat
            "awk '/^cpu[0-9]/{printf \"CPU_STAT:%s\\n\",$0}' /proc/stat;",
            // RAM: MemTotal, MemAvailable, Cached, Buffers
            "awk '/^(MemTotal|MemAvailable|Cached|Buffers):/{printf \"MEM:%s\\n\",$0}' /proc/meminfo;",
            // GPU busy
            "printf 'GPU_BUSY:%s\\n' \"$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0)\";",
            // GPU VRAM
            "if command -v nvidia-smi >/dev/null 2>&1; then",
            "  nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{printf \"GPU_MEM:NVIDIA %s\\n\",$0}';",
            "elif [ -f /sys/class/drm/card1/device/mem_info_vram_used ]; then",
            "  printf 'GPU_MEM:AMD %s %s\\n'",
            "    \"$(cat /sys/class/drm/card1/device/mem_info_vram_used)\"",
            "    \"$(cat /sys/class/drm/card1/device/mem_info_vram_total)\";",
            "fi"
        ].join(" ")]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")

                // Accumulators
                var cpuLines    = []
                var memVals     = {}
                var gpuBusy     = 0
                var gpuMemRaw   = ""

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (!line) continue
                    var colon = line.indexOf(":")
                    if (colon < 0) continue
                    var section = line.substring(0, colon)
                    var data    = line.substring(colon + 1).trim()

                    if (section === "CPU_STAT") {
                        cpuLines.push(data)
                    } else if (section === "MEM") {
                        // e.g. "MemTotal:   16386048 kB"
                        var parts = data.split(/\s+/)
                        var key   = parts[0].replace(":", "")
                        memVals[key] = parseInt(parts[1])
                    } else if (section === "GPU_BUSY") {
                        gpuBusy = parseInt(data) || 0
                    } else if (section === "GPU_MEM") {
                        gpuMemRaw = data
                    }
                }

                // ── Parse CPU per-core deltas ─────────────────────
                var cores        = []
                var newCoreTotal = []
                var newCoreIdle  = []

                for (var j = 0; j < cpuLines.length; j++) {
                    var p    = cpuLines[j].split(/\s+/)
                    var idle = parseInt(p[4]) + parseInt(p[5])
                    var tot  = 0
                    for (var k = 1; k <= 7; k++) tot += parseInt(p[k])

                    var pct = 0
                    if (resourcePopup.lastCoreTotal.length > j) {
                        var dt = tot - resourcePopup.lastCoreTotal[j]
                        var di = idle - resourcePopup.lastCoreIdle[j]
                        pct = (dt > 0) ? Math.max(0, Math.min(100, Math.round(100 * (1 - di / dt)))) : 0
                    }
                    cores.push(pct)
                    newCoreTotal.push(tot)
                    newCoreIdle.push(idle)
                }

                resourcePopup.lastCoreTotal = newCoreTotal
                resourcePopup.lastCoreIdle  = newCoreIdle
                resourcePopup.coreUsages    = cores.slice()
                resourcePopup.coreCount     = cores.length

                // ── Parse RAM ─────────────────────────────────────
                var total     = memVals["MemTotal"]     || 1
                var available = memVals["MemAvailable"] || 0
                var cached    = (memVals["Cached"] || 0) + (memVals["Buffers"] || 0)
                resourcePopup.ramTotal     = total
                resourcePopup.ramUsed      = total - available
                resourcePopup.ramCached    = cached
                resourcePopup.ramAvailable = available

                // ── GPU busy ──────────────────────────────────────
                resourcePopup.gpuUsage = gpuBusy

                // ── GPU VRAM ──────────────────────────────────────
                if (gpuMemRaw) {
                    var gp = gpuMemRaw.split(/[\s,]+/)
                    if (gp[0] === "AMD") {
                        resourcePopup.gpuMemUsed      = Math.round(parseInt(gp[1]) / 1048576)
                        resourcePopup.gpuMemTotal     = Math.round(parseInt(gp[2]) / 1048576)
                        resourcePopup.gpuMemAvailable = true
                        resourcePopup.gpuName         = "AMD GPU"
                    } else if (gp[0] === "NVIDIA" && gp.length >= 3) {
                        var used  = parseInt(gp[gp.length - 2])
                        var gtot  = parseInt(gp[gp.length - 1])
                        if (!isNaN(used) && !isNaN(gtot)) {
                            resourcePopup.gpuMemUsed      = used
                            resourcePopup.gpuMemTotal     = gtot
                            resourcePopup.gpuMemAvailable = true
                            resourcePopup.gpuName         = "NVIDIA GPU"
                        }
                    }
                }
            }
        }
    }

    // Only poll when popup is visible — saves CPU + memory when closed
    Timer {
        interval: 5000
        running: resourcePopup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    // ── Helpers ───────────────────────────────────────────────────
    function fmtRam(kb) {
        var gb = kb / 1048576
        return gb >= 1 ? gb.toFixed(1) + " GB" : Math.round(kb / 1024) + " MB"
    }

    function usageColor(pct) {
        if (pct >= 85) return Colors.md3.error
        if (pct >= 60) return Colors.md3.tertiary
        return Colors.md3.primary
    }

    // ── Layout ────────────────────────────────────────────────────
    Column {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 14

        // ─── CPU Section ──────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 20
                    color: Colors.md3.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CPU"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: resourcePopup.coreCount + " cores"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 10
                    color: Colors.md3.on_surface_variant
                }
            }

            Grid {
                id: coreGrid
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                Repeater {
                    model: resourcePopup.coreUsages.length

                    Rectangle {
                        required property int index
                        property int pct: resourcePopup.coreUsages[index] || 0
                        width:  (coreGrid.width - coreGrid.columnSpacing) / 2
                        height: 34
                        radius: 10
                        color:  Colors.md3.surface_container_high

                        Column {
                            anchors { fill: parent; margins: 8 }
                            spacing: 4

                            Row {
                                width: parent.width

                                Text {
                                    text: "Core " + index
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 9
                                    color: Colors.md3.on_surface_variant
                                }
                                Item { width: parent.width - corePctText.width - 60; height: 1 }
                                Text {
                                    id: corePctText
                                    text: pct + "%"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    color: resourcePopup.usageColor(pct)
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Colors.md3.surface_container

                                Rectangle {
                                    width: Math.max(parent.radius * 2,
                                                    parent.width * (pct / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: resourcePopup.usageColor(pct)
                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation  { duration: 200 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Colors.md3.outline_variant; opacity: 0.5 }

        // ─── RAM Section ──────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 8

            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 20
                    color: Colors.md3.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Memory"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Colors.md3.surface_container_high
                property real usedPct: resourcePopup.ramTotal > 0
                    ? resourcePopup.ramUsed / resourcePopup.ramTotal : 0

                Rectangle {
                    width: Math.max(parent.radius * 2, parent.width * parent.usedPct)
                    height: parent.height
                    radius: parent.radius
                    color: resourcePopup.usageColor(Math.round(parent.usedPct * 100))
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 200 } }
                }
            }

            Row {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { label: "Used",      val: resourcePopup.fmtRam(resourcePopup.ramUsed) },
                        { label: "Cached",    val: resourcePopup.fmtRam(resourcePopup.ramCached) },
                        { label: "Available", val: resourcePopup.fmtRam(resourcePopup.ramAvailable) },
                        { label: "Total",     val: resourcePopup.fmtRam(resourcePopup.ramTotal) }
                    ]

                    Rectangle {
                        required property var modelData
                        width: (parent.width - 18) / 4
                        height: 44
                        radius: 10
                        color: Colors.md3.surface_container_high

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.val
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Colors.md3.on_surface
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 9
                                color: Colors.md3.on_surface_variant
                            }
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Colors.md3.outline_variant; opacity: 0.5 }

        // ─── GPU Section ──────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 8

            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰓅"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 18
                    color: Colors.md3.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: resourcePopup.gpuName
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                }
            }

            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        text: "GPU Load"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        color: Colors.md3.on_surface_variant
                    }
                    Item { width: parent.width - gpuPctLabel.width - 60; height: 1 }
                    Text {
                        id: gpuPctLabel
                        text: resourcePopup.gpuUsage + "%"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        color: resourcePopup.usageColor(resourcePopup.gpuUsage)
                    }
                }
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Colors.md3.surface_container_high
                    Rectangle {
                        width: Math.max(parent.radius * 2,
                                        parent.width * (resourcePopup.gpuUsage / 100))
                        height: parent.height; radius: parent.radius
                        color: resourcePopup.usageColor(resourcePopup.gpuUsage)
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation  { duration: 200 } }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4
                visible: resourcePopup.gpuMemAvailable

                Row {
                    width: parent.width
                    Text {
                        text: "VRAM"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        color: Colors.md3.on_surface_variant
                    }
                    Item { width: parent.width - vramLabel.width - 60; height: 1 }
                    Text {
                        id: vramLabel
                        text: resourcePopup.gpuMemUsed + " / " + resourcePopup.gpuMemTotal + " MiB"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        color: resourcePopup.usageColor(
                            resourcePopup.gpuMemTotal > 0
                                ? Math.round(resourcePopup.gpuMemUsed * 100 / resourcePopup.gpuMemTotal)
                                : 0)
                    }
                }
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Colors.md3.surface_container_high
                    property real vramPct: resourcePopup.gpuMemTotal > 0
                        ? resourcePopup.gpuMemUsed / resourcePopup.gpuMemTotal : 0
                    Rectangle {
                        width: Math.max(parent.radius * 2,
                                        parent.width * parent.parent.vramPct)
                        height: parent.height; radius: parent.radius
                        color: resourcePopup.usageColor(
                            Math.round(parent.parent.vramPct * 100))
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation  { duration: 200 } }
                    }
                }
            }
        }
    }
}

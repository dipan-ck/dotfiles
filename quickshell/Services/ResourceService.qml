pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPerc:           0
    property real memoryUsedPercent: 0
    property real gpuPerc:           0

    property real _prevIdle:  0
    property real _prevTotal: 0

    Process {
        id: gpuReader
        command: ["cat", "/sys/class/drm/card1/device/gpu_busy_percent"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(this.text.trim())
                if (!isNaN(v)) root.gpuPerc = v
            }
        }
    }

    Process {
        id: cpuReader
        command: ["sh", "-c", "head -1 /proc/stat"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (!line) return
                const p      = line.split(/\s+/)
                const idle   = parseInt(p[4]) + parseInt(p[5])
                const total  = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                const dIdle  = idle  - root._prevIdle
                const dTotal = total - root._prevTotal
                if (root._prevTotal > 0 && dTotal > 0)
                    root.cpuPerc = Math.round(100 * (1 - dIdle / dTotal))
                root._prevIdle  = idle
                root._prevTotal = total
            }
        }
    }

    Process {
        id: memReader
        command: ["sh", "-c",
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} " +
            "END{u=t-a; printf \"%d\\n\", int(100*u/t+0.5)}' " +
            "/proc/meminfo"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text.trim())
                if (!isNaN(v)) root.memoryUsedPercent = v
            }
        }
    }

    Timer {
        interval: 2000
        running:  true
        repeat:   true
        onTriggered: {
            gpuReader.running = true
            cpuReader.running = true
            memReader.running = true
        }
    }
}

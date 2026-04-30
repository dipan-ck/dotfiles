pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightnessPercent: 50
    property bool available: true

    Component.onCompleted: {
        updateBrightness()
    }

    // Read current brightness via -m (machine-readable CSV output)
    Process {
        id: getProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Output format: name,device,current,percent,max
                const parts = this.text.trim().split(",")
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3].replace("%", ""))
                    if (!isNaN(pct)) root.brightnessPercent = pct
                }
            }
        }
        onRunningChanged: {
            if (!running) root.available = true
        }
    }

    function updateBrightness() {
        getProc.running = true
    }

    function setBrightness(percent) {
        percent = Math.max(1, Math.min(100, percent))
        root.brightnessPercent = percent   // optimistic update so UI feels instant
        Quickshell.execDetached(["brightnessctl", "set", percent + "%"])
    }

    function increaseBrightness(step) {
        if (step === undefined) step = 5
        setBrightness(Math.min(100, root.brightnessPercent + step))
    }

    function decreaseBrightness(step) {
        if (step === undefined) step = 5
        setBrightness(Math.max(1, root.brightnessPercent - step))
    }

    // Sync actual hardware value every 3 s in case something else changes it
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.updateBrightness()
    }
}

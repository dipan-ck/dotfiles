pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── State ─────────────────────────────
    property bool enabled: false
    property bool autoMode: false
    property int intensity: 50
    property int temperature: 3500

    readonly property int tempMax: 5000
    readonly property int tempMin: 2000

    property bool isActive: enabled || autoMode

    // ── Helpers ───────────────────────────
    function recomputeTemperature() {
        temperature = Math.round(
            tempMax - (intensity / 100) *
            (tempMax - tempMin)
        )
    }

    function applyTemperature() {
        Quickshell.execDetached([
            "hyprctl", "hyprsunset", "temperature",
            temperature.toString()
        ])
    }

    function resetTemperature() {
        Quickshell.execDetached([
            "hyprctl", "hyprsunset", "identity"
        ])
    }

    // ── Apply ─────────────────────────────
    function apply() {
        if (enabled || autoMode) {
            recomputeTemperature()
            applyTemperature()
        } else {
            // 🔴 this is what you wanted:
            // reset back to normal (no tint)
            resetTemperature()
        }
    }

    // ── Public API ────────────────────────
    function setEnabled(val) {
        root.enabled = val
        if (val) root.autoMode = false
        apply()
    }

    function setAuto(val) {
        root.autoMode = val
        if (val) root.enabled = false
        apply()
    }

    function setIntensity(val) {
        val = Math.min(Math.max(val, 0), 100)

        if (val === root.intensity) return

        root.intensity = val
        recomputeTemperature()

        if (enabled || autoMode) {
            applyTemperature()
        }
    }

    // ── Auto mode ─────────────────────────
    Timer {
        interval: 60000
        running: root.autoMode
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            const h = new Date().getHours()
            const shouldBeOn = (h >= 20 || h < 7)

            if (shouldBeOn !== root.enabled) {
                root.enabled = shouldBeOn
                apply()
            }
        }
    }
}

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import "."

Scope {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            TopBar { property var modelData; screen: modelData }
        }
    }

    PowerMenu  { id: powerMenu  }
    EyeCare    { id: eyeCare    }
    Screenshot { id: screenshot }
    Wallpaper  { id: wallpaper  }
    VolumeOsd  {}
    GlobalShortcut {
        name: "powermenu"
        description: "Toggle power menu"
        onPressed: powerMenu.toggle()
    }
    GlobalShortcut {
        name: "eyecare"
        description: "Toggle eye care"
        onPressed: eyeCare.toggle()
    }
    GlobalShortcut {
        name: "screenshot"
        description: "Toggle screenshot menu"
        onPressed: screenshot.toggle()
    }
    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle wallpaper picker"
        onPressed: wallpaper.toggle()
    }
}

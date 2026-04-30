import Quickshell
import Quickshell.Hyprland
import QtQuick
import "./Popups"
import "./Services" as Services
import "./Launcher"
import "."
import "./Bar"

Scope {
    id: root

    Bar {}
    Osd {}
    NotificationPopup {}

    PowerMenu {
        id: powerMenu
    }

    WallpaperPopup {
        id: wallpaperPopup
    }

    AppLauncher {
        id: launcher
    }

    GlobalShortcut {
        name:        "launcherToggle"
        description: "Toggle app launcher"
        onPressed:   launcher.visible = !launcher.visible
    }

    GlobalShortcut {
        name:        "powerMenuToggle"
        description: "Toggle power menu"
        onPressed:   powerMenu.toggle()
    }


  GlobalShortcut {
        name:        "wallpaperToggle"
        description: "Toggle wallpaper picker"
        onPressed:   wallpaperPopup.visible = !wallpaperPopup.visible
    }
}

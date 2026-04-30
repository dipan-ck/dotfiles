pragma Singleton
import QtQuick

QtObject {
    property bool wallpaperVisible: false

    function toggleWallpaper() {
        wallpaperVisible = !wallpaperVisible;
    }
}

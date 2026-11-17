import Quickshell
import Quickshell.Io
import QtQuick

// Read-only: do not import the main shell's Config singleton (it writes defaults).
Scope {
    id: root
    property var saved: ({})
    readonly property string fontFamily: String(saved.fontUI || "Liberation Sans")
    readonly property real clockSize: bounded(saved.clockSize, 17, 10, 48)
    readonly property real bandHeight: bounded(saved.bandH, 32, 24, 100)
    readonly property real idleWidth: bounded(saved.idleW, 140, 80, 600)
    readonly property real flare: bounded(saved.flare, 13, 0, 40)
    readonly property real roundness: bounded(saved.roundMax, 30, 0, 60)
    readonly property bool island: saved.notchStyle === "island"
    readonly property real topGap: island ? bounded(saved.islandGap, 4, 0, 60) : 0
    readonly property color notchColor: "#1d2021"
    readonly property color foreground: "#d4be98"
    readonly property color accent: "#7daea3"
    readonly property color muted: "#a89984"
    readonly property color errorColor: "#ea6962"
    readonly property real dimAmount: 0.55
    readonly property int animationDuration: 650
    readonly property url wallpaper: "file://" + (Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state") + "/quickshell/current-wallpaper"

    function bounded(value, fallback, minimum, maximum) {
        const n = Number(value);
        return value === undefined || !isFinite(n) ? fallback : Math.max(minimum, Math.min(maximum, n));
    }
    FileView {
        id: settingsFile
        path: (Quickshell.env("XDG_CONFIG_HOME")
            || Quickshell.env("HOME") + "/.config")
            + "/quickshell-settings.json"

        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: settingsFile.reload()

        onLoaded: {
            try {
                root.saved = JSON.parse(text());
            } catch (_) {}
        }
    }
}

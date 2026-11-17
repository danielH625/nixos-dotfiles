import Quickshell
import Quickshell.Io
import QtQuick

// Width of the shell's resting notch, including its media expansion.
// Only visual data is accepted; authentication never depends on this file.
Scope {
    id: root
    property real width: 0
    FileView {
        id: geometryFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-notch-geometry.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = Number(JSON.parse(text()).width);
                if (isFinite(value) && value >= 80 && value <= 4096)
                    root.width = value;
            } catch (_) {}
        }
    }
}

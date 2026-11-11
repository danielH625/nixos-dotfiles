import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: root

    property string note: "Shortcut reference. Edit your bindings in your Hyprland Lua configuration."
    readonly property int matchCount: shortcuts.visibleRows
    property string actionText: ""
    signal actionRun()

    contentHeight: column.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    onVisibleChanged: {
        if (visible) contentY = 0;
    }

    readonly property var bindings: [
        { label: "Control Centre", keys: "Super + ." },
        { label: "Launcher", keys: "Super + Space" },
        { label: "Settings", keys: "Super + ," },
        { label: "Your computer", keys: "Super + Shift + ." },
        { label: "Workspace overview", keys: "Super + Tab" },
        { label: "Power menu", keys: "Super + Shift + P" },
        { label: "Calendar", keys: "Super + Alt + C" },
        { label: "Floating media player", keys: "Super + Shift + M" },
        { label: "Launcher actions", keys: "Super + Alt + Space" },
        { label: "Network", keys: "Super + Alt + N" },
        { label: "Bluetooth", keys: "Super + Alt + B" },
        { label: "Do not disturb", keys: "Super + Alt + D" },
        { label: "Keep awake", keys: "Super + Alt + I" },
        { label: "Notch / floating island", keys: "Super + N" },
        { label: "Hide / show shell", keys: "Super + W" },
        { label: "Close notch panel", keys: "Super + Escape" },
        { label: "Wallpaper selector", keys: "Super + Alt + W" },
        { label: "Monitor configuration", keys: "Super + Alt + M" },
        { label: "Shortcut reference", keys: "Super + F1" },
        { label: "Play / pause", keys: "Media Play / Pause" },
        { label: "Next track", keys: "Media Next" },
        { label: "Previous track", keys: "Media Previous" },
        { label: "Volume", keys: "Volume keys" },
        { label: "Brightness", keys: "Brightness keys" },
        { label: "Dismiss focused panel", keys: "Escape" },
        { label: "Close Settings", keys: "Ctrl + W" },
        { label: "Launcher: actions", keys: ">" },
        { label: "Launcher: windows", keys: "@" },
        { label: "Launcher: timer example", keys: "10m" },
        { label: "Launcher: calculation example", keys: "2 + 2" }
    ]

    ColumnLayout {
        id: column
        x: 24
        y: 16
        width: root.width - 48
        spacing: 10

        SettingsControls.Note_ {
            text: "Your keyboard shortcuts. Search by action or key combination using the Settings search box."
        }

        SettingsControls.Card_ {
            id: shortcuts
            title: "Keyboard shortcuts"

            Repeater {
                model: root.bindings

                delegate: SettingsControls.Row_ {
                    required property var modelData

                    label: modelData.label
                    hint: modelData.label + " — " + modelData.keys

                    SettingsControls.Val_ {
                        text: modelData.keys
                        color: Colors.accent
                    }
                }
            }
        }
    }
}

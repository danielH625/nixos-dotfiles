import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: root

    property string note: "Monitor layouts are managed by hyprmoncfg."
    readonly property int matchCount: displays.visibleRows
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

    function openMonitorManager() {
        Quickshell.execDetached([
            "uwsm", "app", "--",
            "kitty",
            "--class", "pocket-monitors",
            "--title", "Monitor configuration",
            "hyprmoncfg"
        ]);
    }

    ColumnLayout {
        id: column
        x: 24
        y: 16
        width: root.width - 48
        spacing: 10

        SettingsControls.Note_ {
            text: "Open hyprmoncfg to arrange your displays and manage monitor profiles."
        }

        SettingsControls.Card_ {
            id: displays
            title: "Monitor configuration"

            SettingsControls.Row_ {
                label: "hyprmoncfg"
                hint: "Launch the monitor manager in Kitty to configure display layout, resolution and scale."

                SettingsControls.Btn_ {
                    text: "Open monitor manager"
                    onClicked: root.openMonitorManager()
                }
            }

            SettingsControls.Row_ {
                label: "Keyboard shortcut"
                hint: "Open monitor configuration with Super + Alt + M."

                SettingsControls.Val_ {
                    text: "Super + Alt + M"
                    color: Colors.accent
                }
            }
        }

        SettingsControls.Note_ {
            text: "Open your existing monitor manager. Apply and save display changes inside hyprmoncfg."
        }
    }
}

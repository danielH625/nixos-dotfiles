import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

ColumnLayout {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string savedLink:
        home + "/.local/state/quickshell/current-wallpaper"

    readonly property int visibleRows:
        ShellState.settingsMatch("Wallpapers", "background image hyprpaper") ? 1 : 0

    property string selected: ""
    property string pending: ""
    property string message: ""

    spacing: 10

    onVisibleChanged: {
        if (visible && !readSelection.running)
            readSelection.running = true;
    }

    FolderListModel {
        id: files
        folder: "file://" + root.home + "/.config/wallpaper"
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        caseSensitive: false
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortCaseSensitive: false
    }

    Process {
        id: readSelection
        command: ["readlink", "--", root.savedLink]

        stdout: StdioCollector {
            onStreamFinished: root.selected = text.trim()
        }
    }

    function selectedIndex() {
        for (let i = 0; i < files.count; i++) {
            if (files.get(i, "filePath") === selected)
                return i;
        }
        return -1;
    }

    function choose(path) {
        if (apply.running || !path)
            return;

        // Hyprpaper uses commas to separate IPC arguments.
        if (path.indexOf(",") !== -1 ||
            path.indexOf("\n") !== -1 ||
            path.indexOf("\r") !== -1) {
            message = "Rename this image: commas and line breaks are unsupported.";
            return;
        }

        pending = path;
        message = "Applying wallpaper…";

        // Paths are passed as arguments, never inserted into shell code.
        apply.command = [
            "bash", "-c",
            'set -e\n'
            + 'test -r "$1"\n'
            + 'mkdir -p -- "$(dirname -- "$2")"\n'
            + 'hyprctl hyprpaper wallpaper ",$1,cover"\n'
            + 'ln -sfnT -- "$1" "$2"\n',
            "wallpaper-switch",
            path,
            savedLink
        ];
        apply.running = true;
    }

    function step(direction) {
        if (files.count === 0)
            return;

        const current = selectedIndex();
        const next = current < 0
            ? (direction > 0 ? 0 : files.count - 1)
            : (current + direction + files.count) % files.count;

        choose(files.get(next, "filePath"));
    }

    function randomWallpaper() {
        if (files.count === 0)
            return;

        const current = selectedIndex();
        let next;

        if (files.count > 1 && current >= 0) {
            next = Math.floor(Math.random() * (files.count - 1));
            if (next >= current)
                next++;
        } else {
            next = Math.floor(Math.random() * files.count);
        }

        choose(files.get(next, "filePath"));
    }

    Process {
        id: apply

        stdout: StdioCollector {}
        stderr: StdioCollector { id: errors }

        onExited: function(code, status) {
            if (code === 0) {
                root.selected = root.pending;
                root.message = "Wallpaper applied and saved.";
            } else {
                root.message = "Could not apply or save wallpaper. "
                    + errors.text.trim();
            }
        }
    }

    SettingsControls.Note_ {
        text: "Choose an image from ~/.config/wallpaper/. "
            + "The selection is remembered for your next login."
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        enabled: !apply.running && files.count > 0
        opacity: enabled ? 1 : 0.5

        SettingsControls.Btn_ {
            text: "Previous"
            onClicked: root.step(-1)
        }

        SettingsControls.Btn_ {
            text: "Next"
            onClicked: root.step(1)
        }

        SettingsControls.Btn_ {
            text: "Random"
            onClicked: root.randomWallpaper()
        }

        Item { Layout.fillWidth: true }

        Text {
            text: files.count + " images"
            color: Colors.label2
            font.family: Appearance.fontUI
            font.pixelSize: Appearance.fsXS
        }
    }

    GridView {
        id: grid

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(
            390,
            Math.max(130, Math.ceil(files.count / columns) * cellHeight)
        )

        readonly property int columns: Math.max(1, Math.floor(width / 180))
        cellWidth: width / columns
        cellHeight: 130

        // Release thumbnail delegates while this page is hidden.
        model: root.visible ? files : null

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: Item {
            id: tile
            required property string fileName
            required property string filePath
            required property url fileUrl

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 8
                color: Colors.surface1
                border.width: root.selected === tile.filePath ? 2 : 1
                border.color: root.selected === tile.filePath
                    ? Colors.accent : Colors.hairline

                Image {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 6
                    }
                    height: 86
                    source: tile.fileUrl
                    sourceSize.width: 320
                    sourceSize.height: 180
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 8
                    }
                    text: tile.fileName
                    elide: Text.ElideMiddle
                    color: root.selected === tile.filePath
                        ? Colors.accent : Colors.label
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXS
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !apply.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.choose(tile.filePath)
                }
            }
        }
    }

    SettingsControls.Note_ {
        visible: files.count === 0
        text: "No images found. Add PNG, JPEG or WebP files to ~/.config/wallpaper/."
    }

    SettingsControls.Note_ {
        visible: root.message.length > 0
        text: root.message
    }
}

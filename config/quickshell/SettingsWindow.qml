// Customized for Daniel: Gruvbox / NixOS. Upstream attribution: NOTICE.md.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
    id: root

    readonly property var sections: [
        { id: "look",   icon: "󰸌", label: I18n.tr("Apariencia"), desc: I18n.tr("Forma, barra, tipografía y fondo") },
        { id: "profiles", icon: "󰆓", label: I18n.tr("Perfiles"), desc: I18n.tr("Guarda y recupera distintas apariencias") },
        { id: "launcher", icon: "󰍉", label: I18n.tr("Lanzador"), desc: I18n.tr("Orden de las aplicaciones y aprendizaje") },
        { id: "system", icon: "󰒓", label: I18n.tr("Sistema"), desc: I18n.tr("Brillo, energía, red y notificaciones") },
        { id: "displays", icon: Icons.monitor, label: I18n.tr("Pantallas"), desc: I18n.tr("Colocación, resolución y escala") },
        { id: "audio",  icon: "󰕾", label: I18n.tr("Sonido"), desc: I18n.tr("Volumen y dispositivos PipeWire") },
        { id: "bt",     icon: "󰂯", label: I18n.tr("Bluetooth"), desc: I18n.tr("Radio, equipos guardados y descubrimiento") },
        { id: "keys",   icon: "󰌌", label: I18n.tr("Atajos"), desc: I18n.tr("Mapa vivo de teclas de Hyprland") },
        { id: "about",  icon: "󰋼", label: I18n.tr("Acerca de"), desc: "Hardware, software and shell paths" }
    ]
    property string section: "look"
    property bool actionArmed: false
    readonly property bool searching: ShellState.settingsQuery.trim().length > 0
    readonly property int totalHits: look.matchCount + system.matchCount + audio.matchCount
        + bt.matchCount + keys.matchCount + about.matchCount + profiles.matchCount + launcher.matchCount
        + displays.matchCount
    readonly property string actionConfirmHint: I18n.tr("Vuelve a pulsar «Confirmar» para restablecer todos los ajustes de Apariencia.")

    function sectionInfo(id) {
        for (let i = 0; i < root.sections.length; i++)
            if (root.sections[i].id === id) return root.sections[i];
        return ({ id: "", icon: "", label: "", desc: "" });
    }
    function sectionHits(id) {
        if (id === "look") return look.matchCount;
        if (id === "profiles") return profiles.matchCount;
        if (id === "launcher") return launcher.matchCount;
        if (id === "system") return system.matchCount;
        if (id === "displays") return displays.matchCount;
        if (id === "audio") return audio.matchCount;
        if (id === "bt") return bt.matchCount;
        if (id === "keys") return keys.matchCount;
        return about.matchCount;
    }
    function selectFirstMatchingSection() {
        if (!root.searching || root.totalHits === 0 || root.sectionHits(root.section) > 0) return;
        for (let i = 0; i < root.sections.length; i++) {
            if (root.sectionHits(root.sections[i].id) > 0) {
                root.section = root.sections[i].id;
                return;
            }
        }
    }
    function cancelActionConfirm() {
        root.actionArmed = false;
        confirmTimer.stop();
        if (ShellState.settingsHint === root.actionConfirmHint) ShellState.settingsHint = "";
    }
    function runSectionAction(sec) {
        if (!sec) return;
        if (sec.actionConfirm === true && !root.actionArmed) {
            root.actionArmed = true;
            ShellState.settingsHint = root.actionConfirmHint;
            confirmTimer.restart();
            return;
        }
        root.cancelActionConfirm();
        sec.actionRun();
    }
    function step(d) {
        const available = [];
        for (let i = 0; i < root.sections.length; i++) {
            if (!root.searching || root.sectionHits(root.sections[i].id) > 0)
                available.push(root.sections[i].id);
        }
        if (available.length === 0) return;
        let at = available.indexOf(root.section);
        if (at < 0) at = 0;
        root.section = available[(at + d + available.length) % available.length];
    }
    onSectionChanged: root.cancelActionConfirm()

    function openAt(id) {
        if (id === "wallpapers") {
            ShellState.closePanel();
            search.text = "";
            ShellState.settingsQuery = "";
            root.section = "look";
            lookTabs.current = "wallpapers";
            look.contentY = 0;
            ShellState.settingsOpen = true;
            return;
        }
        if (ShellState.settingsOpen && root.section === id) {
            ShellState.settingsOpen = false;
            return;
        }
        root.section = id;
        ShellState.settingsOpen = true;
    }

    GlobalShortcut { name: "settings"; description: "System settings"; onPressed: ShellState.toggleSettings() }
    GlobalShortcut { name: "keybinds"; description: "Keyboard shortcut map"; onPressed: root.openAt("keys") }
    GlobalShortcut {
        name: "wallpapers"
        description: "Wallpaper selector"
        onPressed: root.openAt("wallpapers")
    }

    Connections {
        target: ShellState
        function onSettingsSection(id) { root.openAt(id); }
    }

    Timer {
        id: grabFocus
        interval: 90
        onTriggered: Hyprland.dispatch('hl.dsp.focus({ window = "title:Ajustes" })')
    }

    property bool grabArmed: false
    Timer { id: grabArm; interval: 400; onTriggered: root.grabArmed = true }

    Timer {
        id: confirmTimer
        interval: 2500
        onTriggered: root.cancelActionConfirm()
    }

    FloatingWindow {
        id: win
        visible: ShellState.settingsOpen
        title: "Ajustes"
        implicitWidth: 900
        implicitHeight: 620
        minimumSize.width: 780
        minimumSize.height: 500
        color: "#0b0b0b"

        onVisibleChanged: {
            if (!win.visible) {
                root.cancelActionConfirm();
                ShellState.settingsQuery = "";
                ShellState.settingsHint = "";
                grabFocus.stop();
                root.grabArmed = false;
                grabArm.stop();
                return;
            }
            search.text = "";
            ShellState.settingsHint = "";
            search.forceActiveFocus();
            grabFocus.restart();
            root.grabArmed = false;
            grabArm.restart();
        }

        HyprlandFocusGrab {
            windows: [win]
            active: ShellState.settingsOpen && root.grabArmed
            onCleared: ShellState.settingsOpen = false
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.settingsOpen = false

            Shortcut {
                sequence: "Ctrl+F"
                context: Qt.ApplicationShortcut
                onActivated: {
                    search.forceActiveFocus();
                    search.selectAll();
                }
            }
            Shortcut {
                sequence: "Ctrl+W"
                context: Qt.ApplicationShortcut
                onActivated: ShellState.settingsOpen = false
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 224
                    Layout.fillHeight: true
                    color: "#000000"

                    ColumnLayout {
                        anchors { fill: parent; topMargin: 22; leftMargin: 14; rightMargin: 14 }
                        spacing: 5

                        Text {
                            Layout.leftMargin: 8
                            text: I18n.tr("Ajustes")
                            color: Colors.label
                            font.family: Appearance.fontUI
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            Layout.bottomMargin: root.searching ? 2 : 9
                            implicitHeight: 38
                            radius: 12
                            color: search.activeFocus ? Colors.fill1 : Colors.fill3
                            border.width: 1
                            border.color: search.activeFocus
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.42)
                                : Colors.hairline
                            Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                            Behavior on border.color { ColorAnimation { duration: Appearance.mQuick } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                spacing: 7

                                Text {
                                    text: "󰍉"
                                    color: search.activeFocus ? Colors.accent : Colors.label3
                                    font.family: Appearance.font
                                    font.pixelSize: Appearance.fsS
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: search
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        color: Colors.label
                                        selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                                        selectByMouse: true
                                        clip: true
                                        font.family: Appearance.fontUI
                                        font.pixelSize: Appearance.fsS
                                        onTextChanged: {
                                            ShellState.settingsQuery = text;
                                            root.cancelActionConfirm();
                                            Qt.callLater(root.selectFirstMatchingSection);
                                        }

                                        Keys.onDownPressed: root.step(1)
                                        Keys.onUpPressed: root.step(-1)
                                        Keys.onEscapePressed: {
                                            if (search.text.length > 0) search.text = "";
                                            else ShellState.settingsOpen = false;
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 2
                                        visible: search.text.length === 0
                                        text: I18n.tr("Buscar en Ajustes")
                                        color: Colors.label3
                                        font.family: Appearance.fontUI
                                        font.pixelSize: Appearance.fsS
                                    }
                                }

                                Text {
                                    visible: search.text.length > 0
                                    text: "󰅖"
                                    color: clearMa.containsMouse ? Colors.label : Colors.label3
                                    font.family: Appearance.font
                                    font.pixelSize: Appearance.fsXS
                                    MouseArea {
                                        id: clearMa
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { search.text = ""; search.forceActiveFocus(); }
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.leftMargin: 9
                            Layout.bottomMargin: 4
                            visible: root.searching
                            text: root.totalHits === 0 ? I18n.tr("Sin coincidencias")
                                : (root.totalHits === 1 ? I18n.tr("{0} resultado", root.totalHits)
                                                        : I18n.tr("{0} resultados", root.totalHits))
                            color: root.totalHits === 0 ? Colors.warn : Colors.label3
                            font.family: Appearance.fontUI
                            font.pixelSize: Appearance.fsXS
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: navigation.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }
                            ColumnLayout {
                                id: navigation
                                width: parent.width
                                spacing: 5
                                Repeater {
                                    model: root.sections
                                    Rectangle {
                                        id: navItem
                                        required property var modelData
                                        readonly property bool sel: root.section === modelData.id
                                        readonly property int hits: root.sectionHits(modelData.id)

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        visible: !root.searching || navItem.hits > 0
                                        radius: 12
                                        color: navItem.sel ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24)
                                             : navMa.containsMouse ? Colors.fill2 : "transparent"
                                        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                            spacing: 11
                                            Text {
                                                text: navItem.modelData.icon
                                                color: navItem.sel ? Colors.accent : Colors.label2
                                                font.family: Appearance.font
                                                font.pixelSize: 14
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: navItem.modelData.label
                                                color: navItem.sel ? Colors.label : Colors.label2
                                                font.family: Appearance.fontUI
                                                font.pixelSize: Appearance.fsS
                                                font.weight: navItem.sel ? Font.Medium : Font.Normal
                                            }
                                            Rectangle {
                                                visible: root.searching
                                                implicitWidth: Math.max(22, hitText.implicitWidth + 12)
                                                implicitHeight: 20
                                                radius: 7
                                                color: navItem.sel
                                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
                                                    : Colors.fill3
                                                Text {
                                                    id: hitText
                                                    anchors.centerIn: parent
                                                    text: navItem.hits
                                                    color: navItem.sel ? Colors.label : Colors.label3
                                                    font.family: Appearance.fontUI
                                                    font.pixelSize: Appearance.fsXXS
                                                    font.weight: Font.Medium
                                                    font.features: ({ "tnum": 1 })
                                                }
                                            }
                                        }
                                        MouseArea {
                                            id: navMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.section = navItem.modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.bottomMargin: 16
                            spacing: 3
                            Text {
                                text: I18n.tr("Ctrl+F  buscar  ·  Esc  cerrar")
                                color: Colors.label3
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsXXS
                            }
                            Text {
                                text: "Quickshell · Gruvbox"
                                color: Colors.label4
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsXXS
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72

                        RowLayout {
                            anchors { fill: parent; leftMargin: 24; rightMargin: 18 }
                            spacing: 13

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 12
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                                Text {
                                    anchors.centerIn: parent
                                    text: root.sectionInfo(root.section).icon
                                    color: Colors.accent
                                    font.family: Appearance.font
                                    font.pixelSize: 17
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: root.sectionInfo(root.section).label
                                    color: Colors.label
                                    elide: Text.ElideRight
                                    font.family: Appearance.fontUI
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    readonly property int hits: root.sectionHits(root.section)
                                    text: root.searching
                                        ? (root.totalHits === 0 ? I18n.tr("Sin coincidencias en todos los ajustes")
                                            : (hits === 1 ? I18n.tr("{0} resultado en esta sección", hits)
                                                          : I18n.tr("{0} resultados en esta sección", hits)))
                                        : root.sectionInfo(root.section).desc
                                    color: root.totalHits === 0 && root.searching ? Colors.warn : Colors.label2
                                    elide: Text.ElideRight
                                    font.family: Appearance.fontUI
                                    font.pixelSize: Appearance.fsXS
                                }
                            }

                            SettingsControls.Btn_ {
                                readonly property var sec: content.current
                                visible: !root.searching && sec
                                    && sec.actionText !== undefined && sec.actionText.length > 0
                                text: visible ? (root.actionArmed ? I18n.tr("Confirmar") : sec.actionText) : ""
                                danger: visible && sec.actionDanger === true
                                onClicked: root.runSectionAction(sec)
                            }

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 10
                                color: closeMa.containsMouse ? Colors.fill2 : Colors.fill3
                                Behavior on color { ColorAnimation { duration: Appearance.mQuick } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: closeMa.containsMouse ? Colors.label : Colors.label3
                                    font.family: Appearance.font
                                    font.pixelSize: Appearance.fsS
                                }
                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: ShellState.settingsHint = I18n.tr("Cerrar Ajustes · Ctrl+W")
                                    onExited: if (ShellState.settingsHint === I18n.tr("Cerrar Ajustes · Ctrl+W")) ShellState.settingsHint = ""
                                    onClicked: ShellState.settingsOpen = false
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colors.hairline
                    }

                    SettingsTabs {
                        id: lookTabs
                        Layout.leftMargin: 24
                        Layout.rightMargin: 24
                        Layout.topMargin: visible ? 10 : 0
                        Layout.bottomMargin: visible ? 4 : 0
                        visible: root.section === "look" && !root.searching
                        current: "notch"
                        tabs: [
                            { id: "notch", label: "Notch" },
                            { id: "bar", label: I18n.tr("Barra") },
                            { id: "type", label: I18n.tr("Tipografía") },
                            { id: "wallpapers", label: "Wallpapers" },
                        ]
                        onPicked: function (id) { current = id; look.contentY = 0; }
                    }

                    Item {
                        id: content
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readonly property bool noResults: root.searching && root.totalHits === 0

                        readonly property var current: root.section === "look" ? look
                                                     : root.section === "profiles" ? profiles
                                                     : root.section === "launcher" ? launcher
                                                     : root.section === "system" ? system
                                                     : root.section === "displays" ? displays
                                                     : root.section === "audio" ? audio
                                                     : root.section === "bt" ? bt
                                                     : root.section === "keys" ? keys
                                                     : about

                        SettingsAppearance { id: look; tab: lookTabs.current;   anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "look" }
                        SettingsProfiles { id: profiles; anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "profiles" }
                        SettingsLauncher { id: launcher; anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "launcher" }
                        SettingsSystem     { id: system; anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "system" }
                        SettingsDisplays   { id: displays; anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "displays" }
                        SettingsAudio      { id: audio;  anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "audio" }
                        SettingsBluetooth  { id: bt;     anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "bt" }
                        SettingsShortcuts  { id: keys;   anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "keys" }
                        SettingsAbout      { id: about;  anchors.fill: parent; visible: ShellState.settingsOpen && !content.noResults && root.section === "about" }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(360, parent.width - 56)
                            spacing: 8
                            visible: content.noResults
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰍉"
                                color: Colors.label4
                                font.family: Appearance.font
                                font.pixelSize: 26
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("No hay ajustes para «{0}»", ShellState.settingsQuery.trim())
                                color: Colors.label
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsS
                                font.weight: Font.Medium
                                lineHeight: Appearance.leading(Appearance.fsS)
                                lineHeightMode: Text.FixedHeight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("Prueba otra palabra o pulsa Esc para limpiar la búsqueda.")
                                color: Colors.label2
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsXS
                                lineHeight: Appearance.leading(Appearance.fsXS)
                                lineHeightMode: Text.FixedHeight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colors.hairline
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48

                        RowLayout {
                            anchors { fill: parent; leftMargin: 24; rightMargin: 18 }
                            spacing: 10
                            Text {
                                text: "󰋼"
                                color: ShellState.settingsHint.length > 0 ? Colors.accent : Colors.label4
                                font.family: Appearance.font
                                font.pixelSize: Appearance.fsS
                                Behavior on color { ColorAnimation { duration: Appearance.mQuick } }
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: ShellState.settingsHint.length > 0 ? ShellState.settingsHint
                                    : (content.current && content.current.note !== undefined ? content.current.note : "")
                                color: ShellState.settingsHint.length > 0 ? Colors.label2 : Colors.label3
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsXS
                                lineHeight: Appearance.leading(Appearance.fsXS)
                                lineHeightMode: Text.FixedHeight
                                Behavior on color { ColorAnimation { duration: Appearance.mQuick } }
                            }
                        }
                    }
                }
            }
        }
    }
}

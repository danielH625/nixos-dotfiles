// Gruvbox shell component. Upstream attribution: NOTICE.md.
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    MouseArea { anchors.fill: parent }

    RowLayout {
        anchors { fill: parent; leftMargin: 24; rightMargin: 22; topMargin: 20; bottomMargin: 20 }
        spacing: 20

        MediaPanel {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
        }

        Rectangle { Layout.fillHeight: true; width: 1; color: Colors.hairline }

        ColumnLayout {
            Layout.preferredWidth: 410
            Layout.maximumWidth: 410
            Layout.fillHeight: true
            spacing: 14

            NotchSlider {
                Layout.fillWidth: true
                icon: ShellState.muted ? Icons.volMute : Icons.volHigh
                value: ShellState.muted ? 0 : ShellState.vol
                accent: Colors.volumeAccent
                onMoved: function (v) { ShellState.setVolume(v); }
                onIconClicked: ShellState.toggleMute()
            }
            NotchSlider {
                visible: ShellState.bright >= 0
                Layout.fillWidth: true
                icon: Icons.brightness
                accent: Colors.brightnessAccent
                value: Math.max(0, ShellState.bright)
                onMoved: function (v) { ShellState.setBrightness(v); }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                columns: 5
                columnSpacing: 10

                component Toggle: Rectangle {
                    id: tg
                    property string icon: ""
                    property string label: ""
                    property bool on: false
                    property string panel: ""      // "" = no dedicated panel
                    property int idx: 0            // its turn in the cascade
                    signal activated()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 58

                    property real ent: ShellState.mode === "control" ? 1 : 0
                    Behavior on ent {
                        SequentialAnimation {
                            PauseAnimation { duration: ShellState.mode === "control" ? tg.idx * 32 : 0 }
                            SpringAnimation {
                                spring: Appearance.sprPanel
                                damping: Appearance.dmpPanel
                                epsilon: Appearance.eppScale
                            }
                        }
                    }
                    scale: 0.82 + 0.18 * tg.ent
                    transform: Translate { y: (1 - tg.ent) * 12 }
                    radius: Appearance.radM
                    color: tg.on ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.42)
                         : tgMa.containsMouse ? Colors.fill2 : Colors.fill3
                    Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tg.icon
                            color: Colors.label
                            font.family: Appearance.font; font.pixelSize: Appearance.fsL
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tg.label
                            color: tg.on ? Colors.label : Colors.label3
                            font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                            font.weight: tg.on ? Appearance.wMedium : Appearance.wRegular
                        }
                    }
                    MouseArea {
                        id: tgMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tg.panel.length > 0) ShellState.togglePanel(tg.panel);
                            else tg.activated();
                        }
                    }
                }

                Toggle {
                    icon: ShellState.netIcon; label: I18n.tr("Red"); idx: 0
                    on: ShellState.online
                    panel: "network"
                }
                Toggle {
                    visible: ShellState.btAdapter !== null
                    icon: ShellState.btIcon; label: I18n.tr("Bluetooth"); idx: 1
                    on: ShellState.btOn
                    panel: "bluetooth"
                }
                Toggle {
                    icon: ShellState.dnd ? "󰂛" : "󰂚"; label: I18n.tr("No molestar"); idx: 2
                    on: ShellState.dnd
                    onActivated: ShellState.dnd = !ShellState.dnd
                }
                Toggle {
                    icon: Icons.coffee; label: I18n.tr("Cafeína"); idx: 3
                    on: ShellState.caffeine
                    onActivated: ShellState.caffeine = !ShellState.caffeine
                }

                Toggle {
                    icon: Icons.calendar; label: I18n.tr("Calendario"); idx: 7
                    on: false
                    panel: "calendar"
                }
            }

            Item { Layout.fillHeight: true }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 12

                Rectangle {
                    id: performanceLink
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 13
                    color: performanceMa.containsMouse
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                        : Colors.fill3
                    border.width: 1
                    border.color: performanceMa.containsMouse
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.26)
                        : Colors.hairline
                    Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: I18n.tr("Tu máquina")
                                color: performanceMa.containsMouse ? Colors.accentInk : Colors.label
                                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.tr("CPU {0}%  ·  RAM {1}%  ·  SSD {2}%",
                                              ShellState.cpu, ShellState.mem, ShellState.disk)
                                color: Colors.label3
                                font.family: Appearance.fontUI; font.pixelSize: 8
                                font.features: ({ "tnum": 1 })
                            }
                        }
                        Text {
                            text: "›"
                            color: performanceMa.containsMouse ? Colors.accentInk : Colors.label3
                            font.family: Appearance.fontUI; font.pixelSize: 20
                        }
                    }

                    MouseArea {
                        id: performanceMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.togglePanel("system")
                    }
                }

            }
        }

        Rectangle { Layout.fillHeight: true; width: 1; color: Colors.hairline }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: I18n.tr("Notificaciones")
                    color: Colors.label
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsS; font.weight: Font.DemiBold
                }
                Rectangle {
                    visible: ShellState.notifCount > 0
                    implicitWidth: cnt.implicitWidth + 12
                    implicitHeight: 17
                    radius: 9
                    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
                    Text {
                        id: cnt
                        anchors.centerIn: parent
                        text: ShellState.notifCount
                        color: Colors.accentInk
                        font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS; font.weight: Font.Medium
                        font.features: ({ "tnum": 1 })
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "󰒓"
                    color: gearMa.containsMouse ? Colors.accentInk : Colors.label3
                    font.family: Appearance.font; font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                    MouseArea {
                        id: gearMa
                        anchors.fill: parent; anchors.margins: -5
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { ShellState.closePanel(); ShellState.settingsOpen = true; }
                    }
                }
                Text {
                    visible: ShellState.notifCount > 0
                    text: I18n.tr("Limpiar")
                    color: clearMa.containsMouse ? Colors.accentInk : Colors.label3
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                    Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                    MouseArea {
                        id: clearMa
                        anchors.fill: parent; anchors.margins: -5
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.clearNotifs()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: notifList
                    anchors.fill: parent
                    clip: true
                    spacing: 7
                    model: ScriptModel {
                        values: ShellState.notifications
                        comparisonMode: ObjectComparison.Identity
                    }
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    property int hoverIdx: -1        // row under the pointer; -1 = none
                    property bool overClose: false   // ...and over its cross

                    function track(mx, my) {
                        const y = my + notifList.contentY;
                        const i = notifList.indexAt(notifList.width / 2, y);
                        notifList.hoverIdx = i;
                        const fila = i >= 0 ? notifList.itemAtIndex(i) : null;
                        const equis = fila ? fila.closeItem : null;
                        if (!equis) {
                            notifList.overClose = false;
                            return;
                        }
                        const p = equis.mapToItem(fila, 0, 0);
                        notifList.overClose = mx >= p.x - 6 && mx <= p.x + equis.width + 6
                            && (y - fila.y) >= p.y - 6 && (y - fila.y) <= p.y + equis.height + 6;
                    }

                    function retrack() {
                        if (!listMa.containsMouse) {
                            notifList.hoverIdx = -1;
                            notifList.overClose = false;
                            return;
                        }
                        notifList.forceLayout();
                        notifList.track(listMa.mouseX, listMa.mouseY);
                    }

                    onCountChanged: Qt.callLater(notifList.retrack)
                    onContentYChanged: if (listMa.containsMouse) notifList.track(listMa.mouseX, listMa.mouseY)

                    delegate: Rectangle {
                        id: nrow
                        required property var modelData
                        required property int index
                        readonly property bool hovered: notifList.hoverIdx === nrow.index
                        readonly property Item closeItem: equis

                        width: notifList.width
                        height: ncol.implicitHeight + 20
                        radius: 12
                        color: nrow.hovered ? Colors.fill2 : Colors.fill3
                        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 10; topMargin: 10; bottomMargin: 10 }
                            spacing: 11

                            Image {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignTop
                                source: nrow.modelData.image && nrow.modelData.image.length > 0
                                    ? nrow.modelData.image
                                    : Quickshell.iconPath(nrow.modelData.appIcon, "dialog-information")
                                sourceSize.width: 22; sourceSize.height: 22
                                fillMode: Image.PreserveAspectFit
                            }

                            ColumnLayout {
                                id: ncol
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: nrow.modelData.appName || ""
                                    color: nrow.modelData.urgency === NotificationUrgency.Critical ? Colors.crit : Colors.label3
                                    elide: Text.ElideRight
                                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: nrow.modelData.summary || ""
                                    color: Colors.label
                                    elide: Text.ElideRight
                                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsS; font.weight: Font.Medium
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: nrow.modelData.body || ""
                                    color: Colors.label2
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.StyledText
                                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                                    lineHeight: Appearance.leading(Appearance.fsXS)
                                    lineHeightMode: Text.FixedHeight
                                }
                            }

                            Text {
                                id: equis
                                Layout.alignment: Qt.AlignTop
                                opacity: nrow.hovered ? 1 : 0
                                text: "󰅖"
                                color: nrow.hovered && notifList.overClose ? Colors.crit : Colors.label3
                                font.family: Appearance.font; font.pixelSize: Appearance.fsS
                                Behavior on opacity { NumberAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                            }
                        }
                    }
                }

                MouseArea {
                    id: listMa
                    anchors.fill: parent
                    z: 1                     // above the rows: the hover is its own
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: notifList.overClose ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPositionChanged: function (mouse) { notifList.track(mouse.x, mouse.y); }
                    onEntered: notifList.track(listMa.mouseX, listMa.mouseY)
                    onExited: { notifList.hoverIdx = -1; notifList.overClose = false; }
                    onClicked: {
                        const ns = ShellState.notifications;
                        const n = (notifList.hoverIdx >= 0 && notifList.hoverIdx < ns.length)
                            ? ns[notifList.hoverIdx] : null;
                        if (!n) return;
                        if (notifList.overClose) { ShellState.dismissNotif(n); return; }
                        const acts = n.actions;
                        if (acts && acts.length > 0) { acts[0].invoke(); ShellState.closePanel(); }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: ShellState.notifCount === 0
                text: I18n.tr("Sin notificaciones")
                color: Colors.label3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsS
            }
        }
    }
}

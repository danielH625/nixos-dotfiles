// Customized for Daniel: Gruvbox / NixOS. Upstream attribution: NOTICE.md.
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int barH: 32

    property string mode: ShellState.mode

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "media" || root.mode === "idle"

        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: ShellState.mediaLive ? -52 : 0
                verticalCenter: parent.verticalCenter
            }
            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation { duration: Appearance.mInScale; easing.type: Easing.OutBack; easing.overshoot: Appearance.mInOvershoot }
            }
            spacing: 11

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0



                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Appearance.clockNudge(Config.clockSize)
                    text: Qt.formatDateTime(ShellState.now, "HH:mm")
                    color: Colors.label
                    font.family: Appearance.fontClock
                    font.pixelSize: Appearance.clockPixelSize(Config.clockSize)
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })   // fixed-width digits: no jitter when the minute changes
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                opacity: (Config.showDate && !ShellState.mediaLive) ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                spacing: 0
                Text {
                    height: 12
                    verticalAlignment: Text.AlignVCenter
                    text: ShellState.capitalize(ShellState.now.toLocaleDateString(ShellState.loc, "dddd"))
                    color: Colors.label
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXXS
                    font.weight: Font.Medium
                }
                Text {
                    height: 12
                    verticalAlignment: Text.AlignVCenter
                    text: ShellState.now.toLocaleDateString(ShellState.loc, I18n.tr("d 'de' MMMM"))
                    color: Colors.label2
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXXS
                }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 15; verticalCenter: parent.verticalCenter }
            spacing: 6
            opacity: (Config.showBattery && !ShellState.mediaLive && ShellState.batt >= 0) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.battIcon
                color: ShellState.ac ? Colors.ok
                    : ShellState.batt < 15 ? Colors.crit
                    : ShellState.batt < 30 ? Colors.warn : Colors.label
                font.family: Appearance.font; font.pixelSize: Appearance.fsM
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.batt + "%"
                color: ShellState.ac ? Colors.ok
                    : ShellState.batt < 15 ? Colors.crit
                    : ShellState.batt < 30 ? Colors.warn : Colors.label
                font.family: Appearance.fontUI
                font.pixelSize: Appearance.fsXS
                font.weight: Font.Medium
                font.features: ({ "tnum": 1 })   // the % must not change width as the charge drops
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 9
            opacity: ShellState.mediaLive ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 22; height: 22; radius: 7
                color: Colors.fill3
                clip: true
                Image {
                    anchors.fill: parent
                    source: (ShellState.player && ShellState.player.trackArtUrl) ? ShellState.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 64
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(ShellState.player && ShellState.player.trackArtUrl)
                    text: Icons.play; color: ShellState.mediaAccent
                    font.family: Appearance.font; font.pixelSize: Appearance.fsXS
                    Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: ShellState.bands * 8 - 4
                height: 18

                Repeater {
                    model: ShellState.bands
                    Rectangle {
                        required property int index
                        x: index * 8
                        width: 4; radius: 2
                        color: ShellState.mediaAccent
                        Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }

                        antialiasing: true
                        height: Math.max(4, 18 * (ShellState.levels[index] || 0))
                        y: (18 - height) / 2
                    }
                }
            }
        }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "peek"

        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: -26
                verticalCenter: parent.verticalCenter
            }
            spacing: 13

            readonly property int pxPeek: Config.clockSize + 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Appearance.clockNudge(parent.pxPeek)
                text: Qt.formatDateTime(ShellState.now, "HH:mm")
                color: Colors.label
                font.family: Appearance.fontClock
                font.pixelSize: Appearance.clockPixelSize(parent.pxPeek)
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text {
                    height: 14
                    verticalAlignment: Text.AlignVCenter
                    text: ShellState.capitalize(ShellState.now.toLocaleDateString(ShellState.loc, "dddd"))
                    color: Colors.label
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXS
                    font.weight: Font.Medium
                }
                Text {
                    height: 14
                    verticalAlignment: Text.AlignVCenter
                    text: ShellState.now.toLocaleDateString(ShellState.loc, I18n.tr("d 'de' MMMM 'de' yyyy"))
                    color: Colors.label2
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXS
                }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 15; verticalCenter: parent.verticalCenter }
            spacing: 6
            visible: ShellState.batt >= 0
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.battIcon
                color: ShellState.ac ? Colors.ok
                    : ShellState.batt < 15 ? Colors.crit
                    : ShellState.batt < 30 ? Colors.warn : Colors.label
                font.family: Appearance.font; font.pixelSize: Appearance.fsL
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.batt + "%"
                color: ShellState.ac ? Colors.ok
                    : ShellState.batt < 15 ? Colors.crit
                    : ShellState.batt < 30 ? Colors.warn : Colors.label
                font.family: Appearance.fontUI
                font.pixelSize: Appearance.fsS
                font.weight: Font.Medium
                font.features: ({ "tnum": 1 })
            }
        }
    }

    NotchLayer {
        id: osd
        anchors.fill: parent
        active: root.mode === "activity"

        readonly property bool isVol: ShellState.activity === "volume"
        readonly property int value: isVol ? ShellState.vol : Math.max(0, ShellState.bright)
        readonly property bool callado: isVol && ShellState.muted
        property real shown: osd.value
        Behavior on shown { NumberAnimation { duration: Appearance.mQuick; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
            spacing: 12

            Text {
                text: osd.isVol
                    ? (ShellState.muted ? Icons.volMute
                        : ShellState.vol > 55 ? Icons.volHigh
                        : ShellState.vol > 20 ? Icons.volMed : Icons.volLow)
                    : Icons.brightness
                color: Colors.label
                font.family: Appearance.font; font.pixelSize: Appearance.fsL
            }
            Rectangle {
                id: osdTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 3
                color: Colors.fill3
                Rectangle {
                    width: osdTrack.width * Math.max(0, Math.min(1, osd.shown / 100))
                    height: parent.height; radius: parent.radius
                    color: osd.isVol ? Colors.volumeAccent : Colors.brightnessAccent
                    opacity: osd.callado ? 0.35 : 1
                    Behavior on opacity { NumberAnimation { duration: Appearance.mQuick } }
                }
            }
            Text {
                text: Math.round(osd.shown) + "%"
                color: osd.callado ? Colors.label4 : Colors.label
                Behavior on color { ColorAnimation { duration: Appearance.mQuick } }
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                font.family: Appearance.font; font.pixelSize: Appearance.fsXS
            }
        }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "ws"

        Row {
            anchors.centerIn: parent
            spacing: 11

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Escritorio")
                color: Colors.label3
                font.family: Appearance.fontUI
                font.pixelSize: Appearance.fsS
                font.weight: Font.Medium
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String(ShellState.activeWs)
                color: Colors.accentInk
                font.family: Appearance.fontUI
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })   // from 9 to 10 the group must not shift
            }
        }
    }

    NotchLayer {
        id: chargeLayer
        anchors.fill: parent
        active: root.mode === "charge"

        readonly property color tone: ShellState.ac ? Colors.ok
            : ShellState.batt < 15 ? Colors.crit
            : ShellState.batt < 30 ? Colors.warn : Colors.label

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.battIcon
                color: chargeLayer.tone
                font.family: Appearance.font
                font.pixelSize: 21
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.ac ? I18n.tr("Cargando") : I18n.tr("Con batería")
                color: Colors.label
                font.family: Appearance.fontUI
                font.pixelSize: Appearance.fsM
                font.weight: Font.Medium
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: ShellState.batt >= 0
                text: I18n.tr("{0} %", ShellState.batt)
                color: chargeLayer.tone
                font.family: Appearance.fontUI
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }
        }
    }

    NotchLayer {
        id: btLayer
        anchors.fill: parent
        active: root.mode === "btpair"

        readonly property bool ask: ShellState.btKind !== "display"

        ColumnLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 8; bottomMargin: 10 }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: ShellState.btKind === "display" ? Icons.keyboard : Icons.btPair
                    color: Colors.accentInk
                    font.family: Appearance.font
                    font.pixelSize: Appearance.fsXL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: ShellState.btName.length > 0 ? ShellState.btName : I18n.tr("Aparato desconocido")
                        color: Colors.label
                        elide: Text.ElideRight
                        font.family: Appearance.fontUI
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: ShellState.btKind === "display"
                                ? I18n.tr("Teclea este código y pulsa Enter")
                                : ShellState.btKind === "authorize"
                                    ? I18n.tr("Quiere emparejarse con este equipo")
                                    : I18n.tr("¿Sale este mismo código en el aparato?")
                        color: Colors.label2
                        elide: Text.ElideRight
                        font.family: Appearance.fontUI
                        font.pixelSize: Appearance.fsXS
                    }
                }

                Text {
                    visible: ShellState.btCode.length > 0
                    text: ShellState.btCode
                    color: Colors.label
                    font.family: Appearance.fontUI
                    font.pixelSize: Appearance.fsXL
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                    font.features: ({ "tnum": 1 })
                }
            }

            Rectangle {
                visible: ShellState.btKind === "display" && ShellState.btEntered >= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 2
                color: Colors.fill3
                Rectangle {
                    property real p: Math.min(1, ShellState.btEntered
                            / Math.max(1, ShellState.btCode.length))
                    Behavior on p { NumberAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                    height: parent.height
                    radius: parent.radius
                    color: Colors.accent
                    width: parent.width * p
                }
            }

            RowLayout {
                visible: btLayer.ask
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8

                Item { Layout.fillWidth: true }

                Repeater {
                    model: [
                        { txt: I18n.tr("No"), ico: Icons.no, ok: false },
                        { txt: I18n.tr("Sí"), ico: Icons.yes, ok: true }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: btBtnRow.implicitWidth + 26
                        implicitHeight: 30
                        radius: 15
                        color: modelData.ok
                            ? (btBtnMa.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.34)
                                                     : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.20))
                            : (btBtnMa.containsMouse ? Colors.fill2 : Colors.fill3)
                        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                        RowLayout {
                            id: btBtnRow
                            anchors.centerIn: parent
                            spacing: 7
                            Text {
                                text: modelData.ico
                                color: modelData.ok ? Colors.accentInk : Colors.label2
                                font.family: Appearance.font
                                font.pixelSize: Appearance.fsM
                            }
                            Text {
                                text: modelData.txt
                                color: modelData.ok ? Colors.label : Colors.label2
                                font.family: Appearance.fontUI
                                font.pixelSize: Appearance.fsS
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: btBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.btReply(modelData.ok)
                        }
                    }
                }
            }
        }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "track"

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 9
                color: Colors.fill3
                clip: true
                Image {
                    anchors.fill: parent
                    source: (ShellState.player && ShellState.player.trackArtUrl) ? ShellState.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 64
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(ShellState.player && ShellState.player.trackArtUrl)
                    text: "󰎈"; color: ShellState.mediaAccent
                    font.family: Appearance.font; font.pixelSize: Appearance.fsL
                    Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: ShellState.player ? (ShellState.player.trackTitle || "") : ""
                    color: Colors.label; elide: Text.ElideRight
                    font.family: Appearance.font; font.pixelSize: Appearance.fsXS; font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: ShellState.player ? (ShellState.player.trackArtist || "") : ""
                    color: Colors.label2; elide: Text.ElideRight
                    font.family: Appearance.font; font.pixelSize: Appearance.fsXXS
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: ShellState.bands * 8 - 4
                implicitHeight: 22

                Repeater {
                    model: ShellState.bands
                    Rectangle {
                        required property int index
                        x: index * 8
                        width: 4; radius: 2
                        color: ShellState.mediaAccent
                        Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                        antialiasing: true
                        height: Math.max(4, 22 * (ShellState.levels[index] || 0))
                        y: (22 - height) / 2
                    }
                }
            }
        }
    }

    NotchLayer {
        id: notifLayer
        anchors.fill: parent
        active: root.mode === "notif"

        readonly property var n: ShellState.lastNotif

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const n = notifLayer.n;
                const acts = n ? n.actions : null;
                ShellState.activity = "";
                if (acts && acts.length > 0) acts[0].invoke();
                else ShellState.togglePanel("control");
            }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 13; rightMargin: 15 }
            spacing: 11

            Image {
                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                source: {
                    const n = notifLayer.n;
                    if (!n) return "";
                    return (n.image && n.image.length > 0) ? n.image
                        : Quickshell.iconPath(n.appIcon, "dialog-information");
                }
                sourceSize.width: 34; sourceSize.height: 34
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: notifLayer.n ? (notifLayer.n.summary || "") : ""
                    color: Colors.label; elide: Text.ElideRight
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsS; font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: notifLayer.n ? (notifLayer.n.body || "") : ""
                    color: Colors.label2; elide: Text.ElideRight
                    textFormat: Text.StyledText
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: notifLayer.n ? (notifLayer.n.appName || "") : ""
                color: Colors.accentInk
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS; font.weight: Font.Medium
            }
        }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "toast"

        Row {
            anchors.centerIn: parent
            spacing: 11
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.toastIcon
                color: Colors.accentInk
                font.family: Appearance.font; font.pixelSize: 17
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ShellState.toastText
                color: Colors.label
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsM; font.weight: Font.Medium
            }
        }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "launcher"
        origin: -1   // the Arch button is on the left
        LauncherPanel { anchors.fill: parent; enPantalla: root.mode === "launcher" }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "overview"
        OverviewPanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "control"
        origin: 1   // the notification bell is on the right
        ControlPanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "system"
        origin: 1   // born from the Control Centre's "Tu máquina" (Your machine) button
        PerformancePanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "network"
        origin: 1   // opens from the control panel, on the right
        NetworkPanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "bluetooth"
        origin: 1   // opens from the control panel, on the right
        BluetoothPanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "power"
        origin: 1   // its icon is on the right
        PowerPanel { anchors.fill: parent }
    }

    NotchLayer {
        anchors.fill: parent
        active: root.mode === "calendar"
        origin: 1   // opens from the Control Centre, on the right
        CalendarPanel { anchors.fill: parent }
    }

}

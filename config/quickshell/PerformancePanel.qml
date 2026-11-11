// Gruvbox shell component. Upstream attribution: NOTICE.md.
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property bool active: ShellState.panel === "system"

    readonly property bool battLow: ShellState.batt >= 0 && ShellState.batt < 18 && !ShellState.ac
    readonly property bool hot: ShellState.cpuTemp >= 78
    readonly property color headTone: root.battLow ? Colors.crit
        : root.hot ? Colors.warn : Colors.accent

    function decimal(v, digits) { return Number(v).toFixed(digits); }
    function gibFromKib(v) { return root.decimal(v / 1048576, 1); }
    function gibFromBytes(v) { return root.decimal(v / 1073741824, 1); }
    function uptime(seconds) {
        const mins = Math.max(0, Math.floor(seconds / 60));
        const days = Math.floor(mins / 1440);
        const hours = Math.floor((mins % 1440) / 60);
        const rest = mins % 60;
        if (days > 0) return days + " d " + hours + " h";
        if (hours > 0) return hours + " h " + rest + " min";
        return rest + " min";
    }

    readonly property var ceilSteps: [5, 10, 15, 20, 30, 40, 50, 75, 100]
    function ceilFor(series) {
        let m = 0;
        if (series) for (let i = 0; i < series.length; i++) if (series[i] > m) m = series[i];
        m *= 1.25;
        for (let i = 0; i < root.ceilSteps.length; i++)
            if (m <= root.ceilSteps[i]) return root.ceilSteps[i];
        return 100;
    }

    readonly property var tempRange: {
        const h = ShellState.tempHistory;
        if (!h || h.length === 0) return { lo: 35, hi: 55 };
        let lo = h[0], hi = h[0];
        for (let i = 1; i < h.length; i++) {
            if (h[i] < lo) lo = h[i];
            if (h[i] > hi) hi = h[i];
        }
        const mid = (lo + hi) / 2;
        const span = Math.max(10, (hi - lo) * 1.6);
        return { lo: Math.max(0, mid - span / 2), hi: mid + span / 2 };
    }

    readonly property real samplePeriod: 1.5

    function sampleAt(x, w, series) {
        const n = series ? series.length : 0;
        if (n < 2 || w <= 0) return -1;
        return Math.max(0, Math.min(n - 1, Math.round(x / w * (n - 1))));
    }
    function agoText(stepsBack) {
        const secs = Math.round(stepsBack * root.samplePeriod);
        if (secs <= 0) return I18n.tr("ahora mismo");
        if (secs < 60) return I18n.tr("hace {0} s", secs);
        const mins = Math.floor(secs / 60), rest = secs % 60;
        if (rest > 0) return I18n.tr("hace {0} min {1} s", mins, rest);
        return I18n.tr("hace {0} min", mins);
    }

    readonly property color plotSurface: Colors.surface1   // the card's surface
    function readable(c) {
        const h = c.hslHue < 0 ? 0 : c.hslHue;
        const s = c.hslSaturation;
        let l = c.hslLightness;
        let out = Qt.hsla(h, s, l, 1);
        for (let i = 0; i < 60 && Colors.contrast(out, root.plotSurface) < 3.0; i++) {
            l = Math.min(l + 0.02, 1);
            out = Qt.hsla(h, s, l, 1);
        }
        return out;
    }
    readonly property color plotTone: root.readable(Colors.aqua)
    readonly property color tempTone: root.readable(ShellState.cpuTemp >= 80 ? Colors.crit
        : ShellState.cpuTemp >= 68 ? Colors.warn : Colors.accent)
    readonly property color diskTone: root.readable(ShellState.disk >= 92 ? Colors.crit
        : ShellState.disk >= 82 ? Colors.warn : Colors.accent)

    MouseArea { anchors.fill: parent }   // the gap belongs to the panel

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: function (e) {
            ShellState.closePanel();
            e.accepted = true;
        }
    }
    onActiveChanged: if (root.active) keys.forceActiveFocus()

    component Card: Rectangle {
        id: card
        property int idx: 0
        radius: Appearance.radM
        color: Colors.surface1
        border.width: 1
        border.color: Colors.hairline

        property real ent: ShellState.mode === "system" ? 1 : 0
        Behavior on ent {
            SequentialAnimation {
                PauseAnimation { duration: ShellState.mode === "system" ? card.idx * 32 : 0 }
                SpringAnimation {
                    spring: Appearance.sprPanel
                    damping: Appearance.dmpPanel
                    epsilon: Appearance.eppScale
                }
            }
        }
        scale: 0.92 + 0.08 * card.ent
        transform: Translate { y: (1 - card.ent) * 10 }
    }

    component Lane: ColumnLayout {
        id: lane
        property string label: ""
        property string value: ""
        property string note: ""
        property string aside: ""          // only the first band carries the «últimos 90 s» (last 90 s)
        property string unit: " %"
        property color tone: Colors.accent
        property var series: []
        readonly property int ceil: root.ceilFor(lane.series)

        property int hover: -1             // the sample pointed at, or -1
        readonly property bool reading: lane.hover >= 0 && lane.hover < (lane.series ? lane.series.length : 0)

        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 6; height: 6; radius: 3
                color: lane.tone
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                text: lane.label
                color: Colors.label2
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                Layout.leftMargin: 3
                text: lane.reading
                    ? Math.round(lane.series[lane.hover]) + lane.unit
                    : lane.value
                color: Colors.label
                font.family: Appearance.fontUI; font.pixelSize: 18
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                Layout.fillWidth: true
                text: lane.reading ? root.agoText(lane.series.length - 1 - lane.hover) : lane.note
                color: Colors.label3; elide: Text.ElideRight
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                font.features: ({ "tnum": 1 })
            }
            Text {
                Layout.alignment: Qt.AlignBaseline
                visible: lane.aside.length > 0
                text: lane.aside
                color: Colors.label3
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 4

            HistoryGraph {
                id: laneGraph
                anchors.fill: parent
                values: lane.series
                ceiling: lane.ceil
                lineColor: lane.tone
                fillTop: Qt.rgba(lane.tone.r, lane.tone.g, lane.tone.b, 0.10)
                fillBottom: Qt.rgba(lane.tone.r, lane.tone.g, lane.tone.b, 0.004)
                showGrid: false
                showBaseline: true
                showPoint: true
                fadeIn: 0.12
                markIndex: lane.hover
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onPositionChanged: function (m) { lane.hover = root.sampleAt(m.x, width, lane.series); }
                onExited: lane.hover = -1
            }

            Text {
                anchors { left: parent.left; top: parent.top }
                text: lane.ceil + " %"
                color: Colors.label3
                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                font.features: ({ "tnum": 1 })
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; leftMargin: 22; rightMargin: 20; topMargin: 20; bottomMargin: 18 }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: Icons.cpu
                color: root.headTone
                font.family: Appearance.font; font.pixelSize: 18
                Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: I18n.tr("Tu máquina")
                    color: Colors.label
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsM; font.weight: Font.DemiBold
                }
                Text {
                    text: root.battLow ? I18n.tr("Batería baja · {0}", ShellState.battEstimateText)
                        : root.hot ? I18n.tr("El procesador está caliente · {0} °C", Math.round(ShellState.cpuTemp))
                        : ShellState.batt >= 0
                            ? I18n.tr("Encendido desde hace {0}  ·  Batería {1} %{2}",
                                      root.uptime(ShellState.uptimeSeconds), ShellState.batt,
                                      ShellState.ac ? I18n.tr(", cargando") : "")
                            : I18n.tr("Encendido desde hace {0}", root.uptime(ShellState.uptimeSeconds))
                    color: root.battLow ? Colors.crit : root.hot ? Colors.warn : Colors.label2
                    elide: Text.ElideRight
                    font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                    font.features: ({ "tnum": 1 })
                    Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                }
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: backRow.implicitWidth + 24
                implicitHeight: 29
                radius: Appearance.radS
                color: backMa.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
                                            : Colors.fill3
                Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }

                Row {
                    id: backRow
                    anchors.centerIn: parent
                    spacing: 7
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "‹"
                        color: backMa.containsMouse ? Colors.accentInk : Colors.label3
                        font.family: Appearance.fontUI; font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Centro de control")
                        color: backMa.containsMouse ? Colors.accentInk : Colors.label
                        font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                    }
                }
                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.togglePanel("control")
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Colors.hairline }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Card {
                idx: 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 14; bottomMargin: 14 }
                    spacing: 14

                    Lane {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        label: I18n.tr("Procesador")
                        value: ShellState.cpu + " %"
                        note: I18n.tr("carga {0} · {1} hilos",
                                      root.decimal(ShellState.cpuLoad, 2), ShellState.cpuThreads)
                        aside: I18n.tr("últimos 90 s")
                        tone: root.plotTone
                        series: ShellState.cpuHistory
                    }
                    Lane {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.minimumHeight: 96
                        Layout.preferredHeight: 96
                        Layout.maximumHeight: 96
                        label: I18n.tr("Memoria")
                        value: ShellState.mem + " %"
                        note: ShellState.memTotalKib > 0
                            ? I18n.tr("{0} de {1} GiB", root.gibFromKib(ShellState.memUsedKib),
                                      root.gibFromKib(ShellState.memTotalKib))
                            : ""
                        tone: root.readable(Colors.purple)
                        series: ShellState.memHistory
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 272
                Layout.preferredWidth: 272
                Layout.maximumWidth: 272
                Layout.fillHeight: true
                spacing: 12

                Card {
                    id: tempCard
                    idx: 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property int hover: -1
                    readonly property bool reading: tempCard.hover >= 0
                        && tempCard.hover < ShellState.tempHistory.length

                    ColumnLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 13; bottomMargin: 13 }
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9
                            Text {
                                text: "󰔏"
                                color: root.tempTone
                                font.family: Appearance.font; font.pixelSize: 15
                                Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("Temperatura")
                                color: Colors.label2
                                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                            }
                            Text {
                                text: tempCard.reading
                                    ? Math.round(ShellState.tempHistory[tempCard.hover]) + " °C"
                                    : ShellState.cpuTemp >= 0 ? Math.round(ShellState.cpuTemp) + " °C" : "—"
                                color: Colors.label
                                font.family: Appearance.fontUI; font.pixelSize: 18
                                font.weight: Font.DemiBold
                                font.features: ({ "tnum": 1 })
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 24
                            text: tempCard.reading
                                ? root.agoText(ShellState.tempHistory.length - 1 - tempCard.hover)
                                : ShellState.cpuTemp < 0 ? I18n.tr("Sin lectura")
                                : ShellState.cpuTemp < 52 ? I18n.tr("Fresco")
                                : ShellState.cpuTemp < 68 ? I18n.tr("Templado")
                                : ShellState.cpuTemp < 80 ? I18n.tr("Caliente") : I18n.tr("Muy caliente")
                            color: Colors.label3
                            font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                            font.features: ({ "tnum": 1 })
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 6
                            Layout.rightMargin: 4

                            HistoryGraph {
                                anchors.fill: parent
                                values: ShellState.tempHistory
                                floor: root.tempRange.lo
                                ceiling: root.tempRange.hi
                                lineColor: root.tempTone
                                fillTop: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.10)
                                fillBottom: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.004)
                                showGrid: false
                                showBaseline: true
                                showPoint: true
                                fadeIn: 0.12
                                markIndex: tempCard.hover
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                onPositionChanged: function (m) {
                                    tempCard.hover = root.sampleAt(m.x, width, ShellState.tempHistory);
                                }
                                onExited: tempCard.hover = -1
                            }
                        }
                    }
                }

                Card {
                    idx: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92

                    ColumnLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 13; bottomMargin: 13 }
                        spacing: 9

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9
                            Text {
                                text: "󰋊"
                                color: ShellState.disk >= 92 ? Colors.crit
                                    : ShellState.disk >= 82 ? Colors.warn : Colors.accent
                                font.family: Appearance.font; font.pixelSize: 15
                                Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("Almacenamiento")
                                color: Colors.label2
                                font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                            }
                            Text {
                                text: ShellState.disk + " %"
                                color: Colors.label
                                font.family: Appearance.fontUI; font.pixelSize: 15
                                font.weight: Font.DemiBold
                                font.features: ({ "tnum": 1 })
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 2
                            color: Qt.rgba(root.diskTone.r, root.diskTone.g, root.diskTone.b, 0.18)
                            Rectangle {
                                property real p: Math.max(0, Math.min(1, ShellState.disk / 100))
                                Behavior on p { NumberAnimation { duration: Appearance.mTick; easing.type: Easing.Linear } }

                                height: parent.height
                                radius: parent.radius
                                width: parent.width * p
                                color: root.diskTone
                                Behavior on color { ColorAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: ShellState.diskTotalBytes > 0
                                ? I18n.tr("{0} GiB libres de {1}",
                                          root.gibFromBytes(Math.max(0, ShellState.diskTotalBytes - ShellState.diskUsedBytes)),
                                          root.gibFromBytes(ShellState.diskTotalBytes))
                                : ""
                            color: Colors.label3; elide: Text.ElideRight
                            font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
                            font.features: ({ "tnum": 1 })
                        }
                    }
                }
            }
        }
    }
}

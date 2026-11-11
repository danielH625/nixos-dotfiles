// Customized for Daniel: Gruvbox / NixOS. Upstream attribution: NOTICE.md.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Layouts

Scope {
    id: root

    readonly property int barH: ShellState.bandH       // reserved band = notch height at rest
    readonly property color notchColor: Colors.notchTint(Config.notchColor)
    readonly property int sideMargin: Config.sideMargin
    readonly property int flare: Config.flare           // radius of the inverted top corner
    readonly property int roundMax: Config.roundMax     // the notch's bottom radius
    readonly property bool island: Config.island
    readonly property real topGap: ShellState.notchTopGap
    readonly property real kArc: 0.5523

    readonly property real scrimAlpha: Config.scrimAlpha

    readonly property int maxH: 546                    // Super+D is now the tallest face (526 px)

    property bool shown: true

    readonly property var panelesConTeclado: ["launcher", "power", "network", "bluetooth",
                                              "overview", "system", "calendar"]
    readonly property bool pideTeclado: root.panelesConTeclado.indexOf(ShellState.panel) >= 0

    property bool grabArmed: false
    property int _tecladoPrevio: -1
    Timer { id: grabArm; interval: 400; onTriggered: root.grabArmed = true }
    Connections {
        target: ShellState
        function onPanelChanged() {
            if (ShellState.panel === "") {
                root.grabArmed = false;
                grabArm.stop();
                root._tecladoPrevio = -1;
                return;
            }
            const teclado = root.pideTeclado ? 1 : 0;
            if (teclado !== root._tecladoPrevio) {
                root.grabArmed = false;
                grabArm.restart();
            }
            root._tecladoPrevio = teclado;
        }
    }

    GlobalShortcut { name: "playpause"; description: "Play/pause media"; onPressed: {
        const p = ShellState.player;
        if (p) { if (p.isPlaying) p.pause(); else p.play(); }
    } }
    GlobalShortcut { name: "next"; description: "Next track"; onPressed: { if (ShellState.player) ShellState.player.next(); } }
    GlobalShortcut { name: "previous"; description: "Previous track"; onPressed: { if (ShellState.player) ShellState.player.previous(); } }
    GlobalShortcut { name: "dnd"; description: "Toggle do not disturb"; onPressed: ShellState.dnd = !ShellState.dnd }
    GlobalShortcut { name: "caffeine"; description: "Toggle keep awake"; onPressed: ShellState.caffeine = !ShellState.caffeine }
    GlobalShortcut { name: "close"; description: "Close notch panel"; onPressed: ShellState.closePanel() }
    GlobalShortcut { name: "notch"; description: "Control Centre"; onPressed: ShellState.togglePanel("control") }
    GlobalShortcut { name: "launcher"; description: "Application launcher"; onPressed: ShellState.togglePanel("launcher") }
    GlobalShortcut { name: "actions"; description: "System actions"; onPressed: ShellState.openLauncher("cmd") }
    GlobalShortcut { name: "power"; description: "Power menu"; onPressed: ShellState.togglePanel("power") }
    GlobalShortcut { name: "overview"; description: "Workspace map"; onPressed: ShellState.togglePanel("overview") }
    GlobalShortcut { name: "network"; description: "Network picker"; onPressed: ShellState.togglePanel("network") }
    GlobalShortcut { name: "bluetooth"; description: "Bluetooth devices"; onPressed: ShellState.togglePanel("bluetooth") }
    GlobalShortcut { name: "system"; description: "System status"; onPressed: ShellState.togglePanel("system") }
    GlobalShortcut { name: "calendar"; description: "Month calendar"; onPressed: ShellState.togglePanel("calendar") }
    GlobalShortcut { name: "bar"; description: "Hide/show the bar and notch"; onPressed: root.shown = !root.shown }
    GlobalShortcut {
        name: "notchstyle"
        description: "Toggle notch / island"
        onPressed: Config.notchStyle = Config.island ? "notch" : "island"
    }

    IpcHandler {
        target: "notch"
        function toggle(): void { ShellState.togglePanel("control"); }
        function control(): void { ShellState.togglePanel("control"); }
        function power(): void { ShellState.togglePanel("power"); }
        function network(): void { ShellState.togglePanel("network"); }
        function bluetooth(): void { ShellState.togglePanel("bluetooth"); }
        function system(): void { ShellState.togglePanel("system"); }
        function calendar(): void { ShellState.togglePanel("calendar"); }

        function settings(): void { ShellState.toggleSettings(); }
        function keys(): void { ShellState.openSettingsAt("keys"); }
        function style(): void { Config.notchStyle = Config.island ? "notch" : "island"; }
        function launcher(): void { ShellState.togglePanel("launcher"); }
        function open(mode: string): void {
            const ok = ["apps", "clip", "cmd", "win"];
            ShellState.openLauncher(ok.indexOf(mode) >= 0 ? mode : "apps");
        }
        function clipboard(): void { ShellState.openLauncher("clip"); }
        function overview(): void { ShellState.togglePanel("overview"); }

        function close(): void { ShellState.closePanel(); }

        function current(): string { return ShellState.panel; }
        function restore(name: string): void {
            if (name !== "" && ShellState.panel !== name) ShellState.togglePanel(name);
        }
        function bright(dir: string): void { ShellState.stepBrightness(dir); }
        function osd(kind: string): void {
            const ok = ["volume", "brightness", "track", "charge", "ws", "toast", "notif"];
            ShellState.flash(ok.indexOf(kind) >= 0 ? kind : "volume");
        }
        function btask(kind: string, name: string, code: string, entered: int): void {
            const ok = ["confirm", "display", "authorize"];
            if (ok.indexOf(kind) < 0) return;
            ShellState.btAsk(kind, name, code, entered);
        }
        function btclear(): void { ShellState.btClear(); }

        function timer(spec: string): void {
            if (spec === "stop" || spec === "off" || spec === "") { ShellState.timerClear(); return; }
            const secs = ShellState.parseDuration(spec);
            if (secs > 0) ShellState.timerStart(secs);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            readonly property bool primary: modelData.name === ShellState.focusedMon

            readonly property var hlMon: {
                const ms = Hyprland.monitors ? Hyprland.monitors.values : [];
                for (let i = 0; i < ms.length; i++)
                    if (ms[i] && ms[i].name === modelData.name) return ms[i];
                return null;
            }

            readonly property string faceMode: win.primary ? ShellState.mode
                : (ShellState.mediaLive ? "media" : "idle")
            readonly property int faceW: win.primary ? ShellState.notchW : ShellState.restW
            readonly property int faceH: win.primary ? ShellState.notchH : ShellState.bandH

            property real fsProg: (ShellState.fullscreen && win.primary) ? 1 : 0
            Behavior on fsProg { NumberAnimation { duration: Appearance.mIn; easing.type: Easing.OutCubic } }
            readonly property bool fsHidden: ShellState.fullscreen && win.primary
            visible: root.shown
            anchors { top: true; left: true; right: true }
            implicitHeight: win.primary ? root.maxH + 40 : root.barH + 40
            exclusiveZone: Config.reserveSpace ? root.barH : 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:bar"
            WlrLayershell.keyboardFocus: (win.primary && root.pideTeclado)
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: win.fsHidden ? nothing : shellRegion

            Region { id: nothing; width: 0; height: 0 }
            Region {
                id: shellRegion
                item: notch
                Region { item: leftGroup; intersection: Intersection.Combine }
                Region { item: rightGroup; intersection: Intersection.Combine }
                Region {
                    intersection: Intersection.Combine
                    x: Math.floor(bubble.x); y: Math.floor(bubble.y)
                    width: ShellState.bubbleOn ? Math.ceil(bubble.width) : 0
                    height: ShellState.bubbleOn ? Math.ceil(bubble.height) : 0
                }
            }

            HyprlandFocusGrab {
                windows: [win]
                active: ShellState.open && root.grabArmed && win.primary
                onCleared: ShellState.closePanel()
            }

            IdleInhibitor { window: win; enabled: ShellState.caffeine && win.primary }

            Item {
                id: surface
                width: parent.width
                height: root.maxH
                y: -(root.maxH) * win.fsProg
                opacity: 1 - win.fsProg

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: root.barH + 12
                    visible: root.scrimAlpha > 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.scrimAlpha) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                RowLayout {
                    id: leftGroup
                    anchors { left: parent.left; leftMargin: root.sideMargin; top: parent.top }
                    height: root.barH
                    spacing: 2

                    BarItem {
                        visible: Config.showArch
                        icon: Icons.nixos
                        iconSize: Appearance.fsL
                        iconColor: Colors.accent
                        hpad: 7
                        onClicked: ShellState.togglePanel("launcher")
                        onScrolled: function (d) { ShellState.nudgeVolume(d); }
                    }

                    Item {
                        id: wsGroup
                        visible: Config.showWorkspaces
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        property int hovered: -1        // which dot the mouse points at
                        readonly property int pill: 18
                        readonly property int pad: (pill - 8) / 2   // how far the pill sticks out at the ends
                        implicitWidth: wsRow.implicitWidth + pill - 8
                        implicitHeight: 8

                        Row {
                            id: wsRow
                            x: wsGroup.pad
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Repeater {
                                id: wsRepeater
                                model: ScriptModel {
                                    values: {
                                        const all = [...Hyprland.workspaces.values].filter(ws => ws.id > 0);
                                        const mine = all.filter(ws => ws.monitor && ws.monitor.name === win.modelData.name);
                                        return mine.length > 0 ? mine : all;
                                    }
                                }
                                Item {
                                    id: dot
                                    required property var modelData
                                    required property int index
                                    readonly property bool isActive: win.hlMon
                                        ? (win.hlMon.activeWorkspace && win.hlMon.activeWorkspace.id === modelData.id)
                                        : (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id)
                                    width: 8
                                    height: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    function aim() { if (isActive) worm.target = x + width / 2; }
                                    onIsActiveChanged: aim()
                                    onXChanged: aim()
                                    Component.onCompleted: aim()

                                    MouseArea {
                                        id: wsMa
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) ShellState.togglePanel("overview");
                                            else Hyprland.dispatch("hl.dsp.focus({ workspace = " + dot.modelData.id + " })");
                                        }
                                        onContainsMouseChanged: wsGroup.hovered = containsMouse ? dot.index : -1
                                    }
                                }
                            }
                        }

                        Item {
                            id: worm
                            visible: false
                            property real target: 0
                            property real lead: 0
                            property real trail: 0
                            onTargetChanged: { lead = target; trail = target; }
                            Behavior on lead {
                                SpringAnimation {
                                    spring: Appearance.sprTight
                                    damping: Appearance.dmpTight
                                    epsilon: Appearance.eppPx
                                }
                            }

                            Behavior on trail {
                                SequentialAnimation {
                                    PauseAnimation { duration: Appearance.mStagger }
                                    SpringAnimation {
                                        spring: Appearance.sprSquash
                                        damping: Appearance.dmpPanel
                                        epsilon: Appearance.eppPx
                                    }
                                }
                            }

                            readonly property real stretch: Math.abs(lead - trail)

                            readonly property real fly: Math.min(1, stretch / (8 + wsRow.spacing))

                            readonly property real thick: 8 - 3.4 * fly

                            readonly property bool live: target > 0
                            x: wsGroup.pad + Math.min(lead, trail) - wsGroup.pill / 2
                            width: stretch + wsGroup.pill
                            height: thick
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MultiEffect {
                            anchors.fill: liquid
                            source: liquid
                            shadowEnabled: true
                            shadowColor: "#000000"
                            shadowOpacity: 0.5
                            shadowBlur: 0.45
                            shadowScale: 1.04
                        }

                        ShaderEffect {
                            id: liquid
                            readonly property real m: 10
                            anchors.centerIn: parent
                            width: wsGroup.implicitWidth + 2 * m
                            height: 24
                            layer.enabled: true
                            visible: false

                            fragmentShader: Qt.resolvedUrl("shaders/liquid.v5.frag.qsb")

                            property real count: wsRepeater.count
                            property real stepX: 8 + wsRow.spacing
                            property real first: m + wsGroup.pad + 4
                            property real dotR: 4
                            property real pillR: Math.max(0.5, worm.height / 2)
                            property real pillA: m + worm.x + pillR
                            property real pillB: m + worm.x + worm.width - pillR
                            property real hasPill: worm.live ? 1 : 0
                            property real hoverIdx: wsGroup.hovered
                            property real k: 4.5
                            property real w: width
                            property real h: height
                            property color dotColor: Colors.onWallDim
                            property color pillColor: Colors.onWallAccent
                        }
                    }

                    BarItem {
                        Layout.leftMargin: 6
                        visible: Config.showAppName && ShellState.appName.length > 0
                        label: ShellState.appName
                        labelBold: true
                        interactive: false
                        hpad: 4
                    }
                }

                RowLayout {
                    id: rightGroup
                    anchors { right: parent.right; rightMargin: root.sideMargin; top: parent.top }
                    height: root.barH
                    spacing: 1

                    BarItem {
                        id: castItem
                        visible: ShellState.casting
                        icon: Icons.rec
                        iconColor: Colors.crit
                        interactive: false
                        SequentialAnimation {
                            id: castBlink
                            NumberAnimation { target: castItem; property: "opacity"; to: 0.35; duration: Appearance.mQuick; easing.type: Easing.OutQuad }
                            NumberAnimation { target: castItem; property: "opacity"; to: 1.0; duration: Appearance.mQuick; easing.type: Easing.OutQuad }
                        }
                        Timer {
                            interval: 2000; repeat: true
                            running: ShellState.casting
                            onTriggered: castBlink.restart()
                        }
                    }

                    BarItem {
                        visible: ShellState.caffeine
                        icon: Icons.coffee
                        iconColor: Colors.accent
                        onClicked: ShellState.caffeine = false
                    }

                    BarItem {
                        visible: ShellState.dnd
                        icon: ShellState.notifIcon
                        label: ShellState.notifCount > 0 ? String(ShellState.notifCount) : ""
                        iconColor: ShellState.dnd ? Colors.dim : Colors.accent
                        labelColor: iconColor
                        onClicked: ShellState.togglePanel("control")
                        onRightClicked: ShellState.dnd = !ShellState.dnd
                    }

                    Row {
                        visible: Config.showTray
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        spacing: 9
                        Repeater {
                            model: SystemTray.items
                            Item {
                                id: trayItem
                                required property var modelData
                                width: 16; height: 16
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                    sourceSize.width: 16; sourceSize.height: 16
                                    opacity: trayMa.containsMouse ? 1 : 0.85
                                    Behavior on opacity { NumberAnimation { duration: Appearance.mQuick } }
                                }
                                QsMenuAnchor {
                                    id: trayMenu
                                    menu: trayItem.modelData.menu
                                    anchor.item: trayItem
                                    anchor.edges: Edges.Bottom
                                    anchor.gravity: Edges.Bottom
                                }
                                MouseArea {
                                    id: trayMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onClicked: function (m) {
                                        if (m.button === Qt.MiddleButton) { trayItem.modelData.secondaryActivate(); return; }
                                        if (m.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                            if (trayItem.modelData.hasMenu) trayMenu.open();
                                            return;
                                        }
                                        trayItem.modelData.activate();
                                    }
                                }
                            }
                        }
                    }

                    BarItem {
                        visible: ShellState.btConnected > 0
                        icon: "󰂱"
                        iconColor: Colors.accent
                        onClicked: ShellState.togglePanel("bluetooth")
                    }

                    BarItem {
                        visible: !ShellState.online
                        icon: "󰤭"
                        iconColor: Colors.crit
                        onClicked: ShellState.togglePanel("network")
                    }

                    BarItem {
                        visible: ShellState.muted
                        icon: Icons.volMute
                        iconColor: Colors.warn
                        onClicked: ShellState.toggleMute()
                    }

                }

                Item {
                    id: bubble

                    readonly property bool on: ShellState.bubbleOn
                    readonly property real h: 28
                    readonly property real restRight: (surface.width
                        + (root.island ? ShellState.restW : ShellState.restW + 2 * root.flare)) / 2
                    readonly property real hiddenX: restRight - h * 0.62
                    readonly property real shownX: restRight + 8

                    property real reveal: on ? 1 : 0
                    Behavior on reveal {
                        SpringAnimation { spring: Appearance.sprPanel; damping: Appearance.dmpPanel; epsilon: Appearance.eppScale }
                    }

                    readonly property bool wide: bubbleMa.containsMouse || ShellState.bubbleAlert

                    x: hiddenX + (shownX - hiddenX) * reveal
                    y: notch.gap + (root.barH - notch.gap - h) / 2
                    height: h
                    width: h + (wide ? label.implicitWidth + 16 : 0)
                    Behavior on width { SpringAnimation { spring: Appearance.sprTight; damping: Appearance.dmpTight; epsilon: Appearance.eppPx } }

                    opacity: reveal
                    scale: 0.55 + 0.45 * reveal
                    transformOrigin: Item.Left
                    visible: reveal > 0.01

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root.notchColor
                    }

                    Shape {
                        id: ring
                        width: bubble.h; height: bubble.h
                        preferredRendererType: Shape.CurveRenderer
                        antialiasing: true
                        readonly property real det: ShellState.bubbleProgress
                        readonly property real r: bubble.h / 2 - 2.5

                        ShapePath {
                            strokeColor: Colors.fill1
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: bubble.h / 2; centerY: bubble.h / 2
                                radiusX: ring.r; radiusY: ring.r
                                startAngle: 0; sweepAngle: 360
                            }
                        }
                        ShapePath {
                            strokeColor: ShellState.bubbleAlert ? Colors.crit : Colors.accent
                            strokeWidth: 2.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: bubble.h / 2; centerY: bubble.h / 2
                                radiusX: ring.r; radiusY: ring.r
                                startAngle: -90
                                sweepAngle: ring.det >= 0 ? 360 * ring.det : 300
                            }
                        }
                        RotationAnimation on rotation {
                            running: ring.det < 0 && bubble.on
                            from: 0; to: 360
                            duration: 1100
                            loops: Animation.Infinite
                        }
                        onDetChanged: if (det >= 0) rotation = 0
                    }

                    Text {
                        x: (bubble.h - implicitWidth) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: ShellState.bubbleIcon
                        color: ShellState.bubbleAlert ? Colors.crit : Colors.label
                        font.family: Appearance.font
                        font.pixelSize: Appearance.fsS
                    }

                    Text {
                        id: label
                        x: bubble.h + 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: ShellState.bubbleLabel
                        color: Colors.label
                        font.family: Appearance.fontUI
                        font.pixelSize: Appearance.fsS
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })   // the seconds must not move the pill
                        opacity: bubble.wide ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: Appearance.mQuick } }
                    }

                    MouseArea {
                        id: bubbleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function (m) {
                            if (ShellState.bubbleKind !== "timer") return;
                            if (m.button === Qt.RightButton) ShellState.timerClear();
                            else ShellState.timerToggle();
                        }
                    }
                }

                Item {
                    id: notch
                    readonly property real gap: root.topGap
                    focus: true
                    Keys.onEscapePressed: function (e) { ShellState.closePanel(); e.accepted = true; }

                    width: root.island ? nw : nw + 2 * root.flare
                    height: nh - notch.gap
                    x: (surface.width - width) / 2
                    y: notch.gap

                    property real nw: win.faceW
                    property real nh: win.faceH
                    Behavior on nw { SpringAnimation { spring: Appearance.sprTight; damping: Appearance.dmpTight; epsilon: Appearance.eppPx } }
                    Behavior on nh { SpringAnimation { spring: Appearance.sprLoose; damping: Appearance.dmpLoose; epsilon: Appearance.eppPx } }

                    readonly property real fl: root.flare
                    readonly property real rb: Math.max(6, Math.min(root.roundMax, height - fl - 1))

                    Rectangle {
                        anchors.fill: parent
                        visible: root.island
                        radius: Math.min(root.roundMax, height / 2)
                        color: root.notchColor
                    }

                    Shape {
                        anchors.fill: parent
                        visible: !root.island
                        preferredRendererType: Shape.CurveRenderer
                        antialiasing: true

                        ShapePath {
                            id: sp
                            fillColor: root.notchColor
                            strokeWidth: 0
                            strokeColor: "transparent"

                            readonly property real fl: notch.fl
                            readonly property real rb: notch.rb
                            readonly property real w: notch.nw
                            readonly property real h: notch.height
                            readonly property real k: root.kArc
                            readonly property real ik: 1 - k

                            startX: 0; startY: 0
                            PathCubic {
                                control1X: sp.fl * sp.k; control1Y: 0
                                control2X: sp.fl;        control2Y: sp.fl * sp.ik
                                x: sp.fl;                y: sp.fl
                            }
                            PathLine { x: sp.fl; y: sp.h - sp.rb }
                            PathCubic {
                                control1X: sp.fl;                 control1Y: sp.h - sp.rb * sp.ik
                                control2X: sp.fl + sp.rb * sp.ik; control2Y: sp.h
                                x: sp.fl + sp.rb;                 y: sp.h
                            }
                            PathLine { x: sp.fl + sp.w - sp.rb; y: sp.h }
                            PathCubic {
                                control1X: sp.fl + sp.w - sp.rb * sp.ik; control1Y: sp.h
                                control2X: sp.fl + sp.w;                 control2Y: sp.h - sp.rb * sp.ik
                                x: sp.fl + sp.w;                         y: sp.h - sp.rb
                            }
                            PathLine { x: sp.fl + sp.w; y: sp.fl }
                            PathCubic {
                                control1X: sp.fl + sp.w;                control1Y: sp.fl * sp.ik
                                control2X: sp.fl + sp.w + sp.fl * sp.k; control2Y: 0
                                x: sp.fl + sp.w + sp.fl;                y: 0
                            }
                            PathLine { x: 0; y: 0 }
                        }
                    }

                    Connections {
                        target: Config
                        function onHoverPreviewChanged() {
                            if (!Config.hoverPreview) { dwell.stop(); ShellState.hovered = false; }
                        }
                    }
                    Timer { id: dwell; interval: Config.hoverDelay; onTriggered: if (Config.hoverPreview) ShellState.hovered = true }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (Config.hoverPreview) dwell.restart()
                        onExited: { dwell.stop(); ShellState.hovered = false; }
                        onClicked: function (m) {
                            if (m.button === Qt.RightButton && ShellState.player)
                                ShellState.player.isPlaying ? ShellState.player.pause() : ShellState.player.play();
                            else ShellState.togglePanel("control");
                        }
                        onWheel: function (w) {
                            const dx = w.angleDelta.x, dy = w.angleDelta.y;
                            if (Math.abs(dx) > Math.abs(dy)) {
                                if (!ShellState.open) ShellState.scrollWorkspace(dx);
                                return;
                            }
                            if (dy !== 0) ShellState.nudgeVolume(dy > 0 ? 1 : -1);
                        }
                    }

                    NotchContent {
                        mode: win.faceMode
                        x: root.island ? 0 : notch.fl
                        y: 0
                        width: notch.nw
                        height: notch.height
                        clip: true
                    }
                }
            }
        }
    }
}

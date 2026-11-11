// Customized for Daniel: Gruvbox / NixOS. Upstream attribution: NOTICE.md.
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property var loc: Qt.locale(I18n.english ? "en_GB" : (I18n.lang === "pt" ? "pt_BR" : "es_ES"))

    property string panel: ""     // "" | "control" | "system" | "launcher" | "power" | "network" | "bluetooth" | "overview" | "calendar"
    readonly property bool open: panel !== ""

    function closeStage() {  }

    property bool settingsOpen: false
    function toggleSettings() { root.settingsOpen = !root.settingsOpen; }

    signal settingsSection(string id)
    function openSettingsAt(id) { root.settingsSection(id); }

    property string settingsQuery: ""
    function settingsFold(value) {
        return String(value).toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    }
    function settingsMatch(label, hint) {
        const q = root.settingsFold(root.settingsQuery.trim());
        if (q.length === 0) return true;
        return root.settingsFold(String(label) + " " + String(hint)).indexOf(q) >= 0;
    }

    property string settingsHint: ""

    function togglePanel(name) {
        if (name === "launcher") { root.openLauncher("apps"); return; }
        root.panel = (root.panel === name) ? "" : name;
    }
    function closePanel() { root.panel = ""; }

    onPanelChanged: {
        if (root.panel !== "") {
            if (root.activity === "toast") {
                activityTimer.stop();
            } else if (root.activity !== "") {
                root.activity = "";
                activityTimer.stop();
            }
        } else {
            if (root.activity !== "")
                activityTimer.restart();
        }
    }
    property bool hovered: false             // mouse over the notch
    property string activity: ""             // "" | "volume" | "brightness" | "track"
    property bool armed: false               // start-up is over: OSDs are allowed

    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: activityTimer; onTriggered: root.activity = "" }

    function flash(kind, ms) {
        if (root.panel !== "" && kind !== "toast")
            return;
        root.activity = kind;
        activityTimer.interval = (ms !== undefined && ms > 0) ? ms
            : (kind === "track" || kind === "notif") ? 4200
            : kind === "toast" ? 1600
            : kind === "ws" ? 1100
            : kind === "charge" ? 2200
            : 1800;
        if (root.panel === "")
            activityTimer.restart();
    }

    readonly property bool mediaLive: player !== null && player.isPlaying && root.mediaDrives

    readonly property string mode: btAsking ? "btpair"
        : panel !== "" ? panel
        : activity === "notif" ? "notif"
        : activity === "toast" ? "toast"
        : activity === "track" ? "track"
        : activity === "ws" ? "ws"
        : activity === "charge" ? "charge"
        : activity !== "" ? "activity"
        : hovered ? "peek"
        : mediaLive ? "media" : "idle"

    readonly property int bandH: Config.bandH

    readonly property int notchTopGap: Config.island ? Config.islandGap : 0

    readonly property int notchW: Math.min(root.notchWWanted, root.maxNotchW)
    readonly property int maxNotchW: {
        const s = root.focusedScreen;
        return (s && s.width > 0) ? Math.max(220, s.width - 96) : 100000;
    }
    readonly property int notchWWanted: mode === "launcher" ? 660
        : mode === "btpair" ? 470
        : mode === "overview" ? ovW
        : mode === "control" ? 1080
        : mode === "system" ? 920
        : mode === "network" || mode === "bluetooth" ? 470
        : mode === "power" ? 520
        : mode === "calendar" ? 350
        : mode === "notif" ? 430
        : mode === "toast" ? 330
        : mode === "ws" ? 220
        : mode === "charge" ? 260
        : mode === "track" ? 400
        : mode === "peek" ? 380
        : mode === "activity" ? 330
        : mode === "media" ? root.mediaW : root.idleW

    readonly property int mediaW: 268

    readonly property int restW: root.mediaLive ? root.mediaW : root.idleW

    property int launcherRows: 0
    property bool launcherCalc: false
    property bool launcherFavs: false

    readonly property int launcherChrome: 73
    readonly property int launcherRowH: root.launcherMode === "clip" ? 60 : 48
    readonly property int launcherCalcH: 62      // 56 for the row + 6 of margin
    readonly property int launcherFavH: 70       // 58 for the row + 12 of margin
    readonly property int launcherMaxRows: 7     // beyond this, scrolling

    readonly property int launcherH: {
        const calc = root.launcherCalc ? root.launcherCalcH : 0;
        const favs = root.launcherFavs ? root.launcherFavH : 0;
        const rows = Math.min(root.launcherRows, root.launcherMaxRows) * root.launcherRowH;
        const vacio = (root.launcherRows === 0 && !root.launcherCalc) ? 46 : 0;  // "Sin resultados"
        return root.launcherChrome + calc + favs + rows + vacio;
    }

    readonly property int idleW: Config.idleW
        + (Config.showDate ? 92 : 0)
        + (Config.showBattery ? 64 : 0)

    readonly property var carasDePanel: ["launcher", "btpair", "overview", "control", "system",
                                         "network", "bluetooth", "power", "calendar",
                                         ]
    readonly property int notchGapDeCara: root.carasDePanel.indexOf(root.mode) >= 0 ? root.notchTopGap : 0

    readonly property int notchH: root.notchBaseH + root.notchGapDeCara

    readonly property int notchBaseH: mode === "launcher" ? launcherH
        : mode === "btpair" ? (btKind === "display" ? 96 : 112)
        : mode === "overview" ? ovH
        : mode === "control" ? 526
        : mode === "system" ? 420
        : mode === "network" || mode === "bluetooth" ? 412
        : mode === "power" ? 158
        : mode === "calendar" ? 320
        : mode === "notif" ? 66
        : mode === "toast" ? 44
        : mode === "ws" ? 44
        : mode === "charge" ? 46
        : mode === "track" ? 52
        : mode === "peek" ? 44
        : mode === "activity" ? 42
        : bandH

    readonly property int ovCols: 5
    readonly property int ovRows: 2
    readonly property int ovCount: ovCols * ovRows

    readonly property real ovScale: 0.14
    readonly property real ovGap: 6          // gap between cells
    readonly property real ovPad: 14         // air at the sides and at the bottom
    readonly property real ovPadTop: 16
    readonly property real ovFooterH: 24     // the strip with the title of the pointed-at window

    readonly property var ovMon: {
        const ms = Hyprland.monitors ? Hyprland.monitors.values : [];
        for (let i = 0; i < ms.length; i++)
            if (ms[i] && ms[i].name === root.focusedMon) return ms[i].lastIpcObject;
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.lastIpcObject : null;
    }
    readonly property real ovMonW: (ovMon && ovMon.width) ? ovMon.width
        : (root.focusedScreen ? root.focusedScreen.width : 1920)
    readonly property real ovMonH: (ovMon && ovMon.height) ? ovMon.height
        : (root.focusedScreen ? root.focusedScreen.height : 1080)
    readonly property var ovRes: (ovMon && ovMon.reserved) ? ovMon.reserved : [0, bandH, 0, 0]
    readonly property real ovCellW: (ovMonW - ovRes[0] - ovRes[2]) * ovScale
    readonly property real ovCellH: (ovMonH - ovRes[1] - ovRes[3]) * ovScale
    readonly property real ovGridW: ovCols * ovCellW + (ovCols - 1) * ovGap
    readonly property real ovGridH: ovRows * ovCellH + (ovRows - 1) * ovGap
    readonly property int ovW: Math.round(ovGridW + 2 * ovPad)
    readonly property int ovH: Math.round(ovPadTop + ovGridH + ovFooterH + ovPad)

    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property bool fullscreen: activeToplevel ? activeToplevel.fullscreen : false
    readonly property string appName: {
        if (!activeToplevel || !activeToplevel.appId) return "";
        const a = String(activeToplevel.appId).split(".").pop();
        return a.charAt(0).toUpperCase() + a.slice(1);
    }
    readonly property string winTitle: activeToplevel ? (activeToplevel.title || "") : ""

    readonly property var player: {
        const ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i];
        for (let i = 0; i < ps.length; i++) if (ps[i].trackTitle) return ps[i];
        return ps[0];
    }

    readonly property var browserHints: ["chrome", "chromium", "brave", "edge",
                                         "opera", "vivaldi", "firefox"]
    function isBrowser(p) {
        if (!p) return false;
        const campos = [p.dbusName, p.desktopEntry, p.identity];
        for (let i = 0; i < campos.length; i++) {
            const v = String(campos[i] || "").toLowerCase();
            if (v.length === 0) continue;
            for (let j = 0; j < root.browserHints.length; j++)
                if (v.indexOf(root.browserHints[j]) >= 0) return true;
        }
        return false;
    }

    readonly property bool mediaDrives: root.player !== null
        && (Config.browserMedia || !root.isBrowser(root.player))

    readonly property string mediaArtUrl: (player && player.trackArtUrl)
        ? String(player.trackArtUrl) : ""
    
    function mediaHsl(c) {
        const r = Number(c.r), g = Number(c.g), b = Number(c.b);
        const hi = Math.max(r, g, b), lo = Math.min(r, g, b);
        const d = hi - lo, l = (hi + lo) / 2;
        let h = 0, s = 0;
        if (d > 0.0001) {
            s = d / (1 - Math.abs(2 * l - 1));
            if (hi === r) h = ((g - b) / d) % 6;
            else if (hi === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h /= 6;
            if (h < 0) h += 1;
        }
        return { h: h, s: isFinite(s) ? s : 0, l: l };
    }
    readonly property color mediaAccent: Colors.orange
    property real pos: 0
    readonly property real len: (player && player.lengthSupported) ? player.length : 0
    Timer {
        interval: 500; repeat: true; running: root.player !== null && (root.open || root.mediaLive)
        onTriggered: root.pos = (root.player && root.player.positionSupported) ? root.player.position : 0
    }
    function capitalize(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""; }

    function fmt(sec) {
        if (!sec || sec < 0) return "0:00";
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }
    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() {
            if (root.armed && root.mediaDrives && root.player && root.player.trackTitle) root.flash("track");
            root.recordarTema();
        }
        function onIsPlayingChanged() { if (root.armed && root.mediaDrives && root.player && root.player.isPlaying) root.flash("track"); }
    }

    property string ultimoTitulo: ""
    property string ultimoArtista: ""
    property string ultimoArte: ""
    property string ultimoAppId: ""
    readonly property bool hayUltimo: root.player === null && root.ultimoTitulo.length > 0

    FileView {
        id: ultimoFile
        path: root.home + "/.cache/quickshell/ultimo-tema.json"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false      // the first time it does not exist, and that is not a failure
        onLoaded: {
            try {
                const d = JSON.parse(ultimoFile.text());
                root.ultimoTitulo = d.titulo || "";
                root.ultimoArtista = d.artista || "";
                root.ultimoArte = d.arte || "";
                root.ultimoAppId = d.app || "";
            } catch (e) {
            }
        }
    }

    function recordarTema(): void {
        const p = root.player;
        if (!p || !p.trackTitle)
            return;
        root.ultimoTitulo = p.trackTitle;
        root.ultimoArtista = p.trackArtist || "";
        root.ultimoArte = p.trackArtUrl ? String(p.trackArtUrl) : "";
        root.ultimoAppId = p.desktopEntry || "";
        ultimoFile.setText(JSON.stringify({
            titulo: root.ultimoTitulo,
            artista: root.ultimoArtista,
            arte: root.ultimoArte,
            app: root.ultimoAppId
        }));
    }

    onPlayerChanged: if (root.player) root.recordarTema()

    readonly property var ultimaApp: {
        if (!root.ultimoAppId.length)
            return null;
        const pela = s => String(s || "").toLowerCase().replace(/\.desktop$/, "");
        const id = pela(root.ultimoAppId);
        const vs = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        for (let i = 0; i < vs.length; i++)
            if (pela(vs[i].id) === id)
                return vs[i];
        return null;
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int vol: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    property var _sinkVisto: null
    Timer { id: sinkGracia; interval: 500 }

    onSinkChanged: {
        root._sinkVisto = root.sink;
        sinkGracia.restart();
    }

    function _audioEsTuyo() {
        if (root.sink !== root._sinkVisto) {
            root._sinkVisto = root.sink;
            sinkGracia.restart();
            return false;
        }
        return !sinkGracia.running;
    }

    onVolChanged: if (armed && _audioEsTuyo()) flash("volume")
    onMutedChanged: if (armed && _audioEsTuyo()) flash("volume")

    function setVolume(pct) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.4, pct / 100));
    }
    function nudgeVolume(dir) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.4, sink.audio.volume + dir * 0.02));
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }

    property real wsAccum: 0
    Timer { id: wsAccumReset; interval: 350; onTriggered: root.wsAccum = 0 }

    function scrollWorkspace(dx) {
        root.wsAccum += dx;
        wsAccumReset.restart();
        while (Math.abs(root.wsAccum) >= 120) {
            const dir = root.wsAccum > 0 ? 1 : -1;
            root.wsAccum -= dir * 120;
            Hyprland.dispatch('hl.dsp.focus({ workspace = "e' + (dir > 0 ? "+1" : "-1") + '" })');
            root.flash("ws");
        }
    }

    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    property string focusedMon: ""

    readonly property var focusedScreen: {
        const ss = Quickshell.screens;
        for (let i = 0; i < ss.length; i++)
            if (ss[i].name === root.focusedMon) return ss[i];
        return ss.length > 0 ? ss[0] : null;
    }

    Process {
        id: monSeed
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'"]
        stdout: SplitParser {
            onRead: function (line) {
                const n = String(line).trim();
                if (n !== "") root.focusedMon = n;
            }
        }
    }
    function reseedMonitor(): void { monSeed.running = false; monSeed.running = true; }
    Component.onCompleted: root.reseedMonitor()

    Timer { id: awwwHotplug }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const n = String(ev.name);
            if (n === "focusedmon" || n === "focusedmonv2") {
                const m = String(ev.data).split(",")[0].trim();
                if (m !== "") root.focusedMon = m;
            } else if (n.indexOf("monitor") === 0) {
                root.reseedMonitor();
                awwwHotplug.restart();
            }
        }
    }

    readonly property int bands: 8

    readonly property int cavaSube: 32    // attack
    readonly property int cavaBaja: 110   // decay

    property var cavaTarget: new Array(bands).fill(0)   // what cava says

    readonly property int cavaRango: 2500
    readonly property real cavaRangoMin: 0.25
    property var cavaHi: new Array(bands).fill(0.5)
    property var cavaLo: new Array(bands).fill(0.3)
    property real cavaUltima: 0
    property var levels: new Array(bands).fill(0)       // what gets painted
    property bool cavaQuieto: true

    FrameAnimation {
        running: cavaProc.running || !root.cavaQuieto
        onTriggered: {
            const dt = smoothFrameTime * 1000;
            const aSube = 1 - Math.exp(-dt / root.cavaSube);
            const aBaja = 1 - Math.exp(-dt / root.cavaBaja);
            const out = new Array(root.bands);
            let quieto = true;
            for (let i = 0; i < root.bands; i++) {
                const falta = root.cavaTarget[i] - root.levels[i];
                if (Math.abs(falta) > 0.001) {
                    out[i] = root.levels[i] + falta * (falta > 0 ? aSube : aBaja);
                    quieto = false;
                } else {
                    out[i] = root.cavaTarget[i];
                }
            }
            root.levels = out;
            root.cavaQuieto = quieto;
        }
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.mediaLive
        onTriggered: cavaProc.running = true
    }
    onMediaLiveChanged: if (!root.mediaLive) cavaProc.running = false

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.shellDir + "/scripts/cava.conf"]
        stdout: SplitParser {
            onRead: function (line) {
                const parts = line.split(";");
                const now = Date.now();
                const dt = root.cavaUltima ? Math.min(100, now - root.cavaUltima) : 16.7;
                root.cavaUltima = now;
                const olvido = 1 - Math.exp(-dt / root.cavaRango);
                const hi = root.cavaHi.slice();
                const lo = root.cavaLo.slice();
                const out = new Array(root.bands);
                for (let i = 0; i < root.bands; i++) {
                    const v = Math.max(0, Math.min(1, (+parts[i] || 0) / 1000));
                    hi[i] = v > hi[i] ? v : hi[i] + (v - hi[i]) * olvido;
                    lo[i] = v < lo[i] ? v : lo[i] + (v - lo[i]) * olvido;
                    const span = Math.max(hi[i] - lo[i], root.cavaRangoMin);
                    const base = Math.min(lo[i], Math.max(0, hi[i] - span));
                    out[i] = Math.max(0, Math.min(1, (v - base) / span));
                }
                root.cavaHi = hi;
                root.cavaLo = lo;
                root.cavaTarget = out;   // only the target; moving is the FrameAnimation's job
                root.cavaQuieto = false;
            }
        }
        onRunningChanged: if (!running) {
            root.cavaTarget = new Array(root.bands).fill(0);
            root.cavaUltima = 0;
        }
    }

    property int bright: -1
    property string backlightDevice: ""
    property real backlightMaximum: 0
    Timer { id: brightnessWriteHold; interval: 350 }
    Process {
        id: backlightDiscovery
        command: ["brightnessctl", "-c", "backlight", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0] || "";
                const fields = line.split(",");
                const maximum = Number(fields[4]);
                if (fields.length < 5 || !/^[A-Za-z0-9_.:-]+$/.test(fields[0])
                    || !isFinite(maximum) || maximum <= 0) return;
                root.backlightMaximum = maximum;
                root.backlightDevice = fields[0];
            }
        }
    }
    FileView {
        id: backlightValue
        path: root.backlightDevice.length > 0
            ? "/sys/class/backlight/" + root.backlightDevice + "/brightness" : ""
        printErrors: false
        onLoaded: {
            if (brightnessWriteHold.running || root.backlightMaximum <= 0) return;
            const raw = backlightValue.text().trim();
            if (!/^[0-9]+$/.test(raw)) return;
            const percent = Math.max(0, Math.min(100,
                Math.round(Number(raw) * 100 / root.backlightMaximum)));
            const previous = root.bright;
            if (previous === percent) return;
            root.bright = percent;
            if (previous >= 0 && root.armed) root.flash("brightness");
        }
    }
    Timer {
        interval: 250
        repeat: true
        running: root.backlightDevice.length > 0
        onTriggered: if (!brightnessWriteHold.running) backlightValue.reload()
    }

    Process {
        id: brightProc
        stdout: SplitParser {
            onRead: function (line) {
                const v = parseInt(line.trim());
                if (!isNaN(v)) { root.bright = v; root.flash("brightness"); }
            }
        }
    }
    function stepBrightness(dir) {
        brightnessWriteHold.restart();
        brightProc.command = ["bash", "-c",
            "brightnessctl -c backlight -m set 5%" + (dir === "down" ? "-" : "+") +
            " >/dev/null 2>&1; brightnessctl -c backlight -m 2>/dev/null | awk -F, '{gsub(\"%\",\"\",$4); print $4}'"];
        brightProc.running = false;
        brightProc.running = true;
    }
    function setBrightness(pct) {
        brightnessWriteHold.restart();
        if (root.bright < 0) return;
        const v = Math.max(0, Math.min(100, Math.round(pct)));
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-q", "set", v + "%"]);
        root.bright = v;
    }

    property int cpu: 0
    property int mem: 0
    property int batt: -1
    property int disk: 0
    property bool ac: false
    property real memUsedKib: 0
    property real memTotalKib: 0
    property real diskUsedBytes: 0
    property real diskTotalBytes: 0
    property real cpuTemp: -1
    property real cpuLoad: 0
    property int uptimeSeconds: 0
    property int cpuThreads: 1

    property var cpuHistory: []
    property var memHistory: []
    property var tempHistory: []
    function appendMetric(history, value) {
        const next = history.slice(Math.max(0, history.length - 59));
        next.push(isFinite(value) ? value : 0);
        return next;
    }
    Process {
        id: sysstatsProc
        command: [Quickshell.shellDir + "/scripts/sysstats.sh"]
        running: true
        onExited: function (exitCode, exitStatus) {
            console.warn(I18n.tr("sysstats.sh murio (code={0}, status={1}); relanzando en 2 s", exitCode, exitStatus));
            sysstatsRestart.restart();
        }
        stdout: SplitParser {
            onRead: function (line) {
                const p = line.trim().split(/\s+/);
                if (p.length < 8) return;
                root.cpu = parseInt(p[0]); root.mem = parseInt(p[1]);
                root.batt = parseInt(p[2]); root.ac = p[3] === "1";
                if (p.length >= 9) root.disk = parseInt(p[8]);
                if (p.length >= 17) {
                    root.memUsedKib = parseFloat(p[9]);
                    root.memTotalKib = parseFloat(p[10]);
                    root.diskUsedBytes = parseFloat(p[11]);
                    root.diskTotalBytes = parseFloat(p[12]);
                    const milliC = parseFloat(p[13]);
                    root.cpuTemp = milliC >= 0 ? milliC / 1000 : -1;
                    root.cpuLoad = parseFloat(p[14]);
                    root.uptimeSeconds = parseInt(p[15]);
                    root.cpuThreads = Math.max(1, parseInt(p[16]));
                }
                root.cpuHistory = root.appendMetric(root.cpuHistory, root.cpu);
                root.memHistory = root.appendMetric(root.memHistory, root.mem);
                if (root.cpuTemp >= 0)
                    root.tempHistory = root.appendMetric(root.tempHistory, root.cpuTemp);
                if (root.bright < 0) root.bright = parseInt(p[4]);   // only the initial value
            }
        }
    }

    Timer {
        id: sysstatsRestart
        interval: 2000
        repeat: false
        onTriggered: if (!sysstatsProc.running) sysstatsProc.running = true;
    }
    onAcChanged: if (root.armed) root.flash("charge")

    readonly property string battIcon: ac ? "󰂄"
        : batt < 0 ? "󰂑"
        : batt >= 90 ? "󰁹" : batt >= 70 ? "󰂂" : batt >= 50 ? "󰁿"
        : batt >= 30 ? "󰁼" : batt >= 15 ? "󰁻" : "󰁺"

    readonly property var batteryDevice: {
        const ds = UPower.devices ? UPower.devices.values : [];
        for (let i = 0; i < ds.length; i++)
            if (ds[i] && ds[i].isLaptopBattery && ds[i].isPresent) return ds[i];
        const display = UPower.displayDevice;
        return (display && display.isPresent) ? display : null;
    }
    readonly property real battHealth: batteryDevice && batteryDevice.ready
        && batteryDevice.healthSupported ? batteryDevice.healthPercentage : -1
    readonly property real battFullWh: batteryDevice && batteryDevice.ready
        ? batteryDevice.energyCapacity : -1
    readonly property real battDesignWh: battHealth > 0 && battFullWh > 0
        ? battFullWh / (battHealth / 100) : -1
    readonly property real battRateW: batteryDevice && batteryDevice.ready
        ? Math.abs(batteryDevice.changeRate) : -1
    readonly property real battEstimateSeconds: {
        if (!batteryDevice || !batteryDevice.ready) return -1;
        const seconds = root.ac ? batteryDevice.timeToFull : batteryDevice.timeToEmpty;
        return seconds > 0 ? seconds : -1;
    }
    property int battCycles: -1

    function fmtBatteryTime(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "";
        const mins = Math.max(1, Math.round(seconds / 60));
        const h = Math.floor(mins / 60), m = mins % 60;
        if (h <= 0) return I18n.tr("{0} min", m);
        return m > 0 ? I18n.tr("{0} h {1} min", h, m) : I18n.tr("{0} h", h);
    }
    function fmtWh(value) { return value > 0 ? I18n.tr("{0} Wh", value.toFixed(1)) : ""; }
    readonly property string battEstimateText: {
        if (root.batt < 0) return I18n.tr("sin batería");
        if (root.ac && root.batt >= 99 && root.battEstimateSeconds < 0) return I18n.tr("completa");
        const time = root.fmtBatteryTime(root.battEstimateSeconds);
        if (time.length === 0) return I18n.tr("calculando…");
        return root.ac ? I18n.tr("{0} para completar", time) : I18n.tr("{0} restantes", time);
    }

    Process {
        id: battCyclesProc
        stdout: SplitParser {
            onRead: function (line) {
                const cycles = parseInt(line.trim());
                if (!isNaN(cycles) && cycles >= 0) root.battCycles = cycles;
            }
        }
    }
    function refreshBatteryCycles() {
        if (!root.batteryDevice || battCyclesProc.running) return;
        const nativeName = String(root.batteryDevice.nativePath || "");
        if (!/^[A-Za-z0-9._-]+$/.test(nativeName)) return;
        battCyclesProc.command = ["cat", "/sys/class/power_supply/" + nativeName + "/cycle_count"];
        battCyclesProc.running = true;
    }
    onBatteryDeviceChanged: root.refreshBatteryCycles()
    Timer {
        interval: 3600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshBatteryCycles()
    }

    property int castCount: 0
    property bool casting: false
    Timer { id: castArm; interval: 1500; onTriggered: root.casting = root.castCount > 0 }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (String(ev.name) !== "screencast") return;
            const p = String(ev.data).split(",");
            if (p.length < 2) return;
            if (p[1] !== "monitor" && p[1] !== "region") return;
            root.castCount = Math.max(0, root.castCount + (p[0] === "1" ? 1 : -1));
            if (root.castCount > 0) {
                castArm.restart();
            } else {
                castArm.stop();
                root.casting = false;
            }
        }
    }

    readonly property string bubbleKind: timerTotal > 0 ? "timer" : ""
    readonly property bool bubbleOn: bubbleKind !== ""
    readonly property real bubbleProgress: (bubbleKind === "timer" && timerTotal > 0)
        ? Math.max(0, Math.min(1, timerLeft / timerTotal)) : -1
    readonly property string bubbleIcon: bubbleKind === "timer"
        ? (timerDone ? Icons.alarm : (timerRunning ? Icons.timer : Icons.pause))
        : Icons.sync
    readonly property string bubbleLabel: bubbleKind === "timer"
        ? (timerDone ? I18n.tr("¡Tiempo!") : timerClock(timerLeft))
        : I18n.tr("Sincronizando")
    readonly property bool bubbleAlert: timerDone

    property int timerTotal: 0        // seconds requested; 0 = no timer
    property int timerLeft: 0
    property bool timerRunning: false
    property bool timerDone: false    // already went off and you have not dismissed it yet

    Timer {
        interval: 1000
        repeat: true
        running: root.timerRunning
        onTriggered: {
            root.timerLeft = Math.max(0, root.timerLeft - 1);
            if (root.timerLeft > 0) return;
            root.timerRunning = false;
            root.timerDone = true;
            root.toast(Icons.bell, "Timer finished");
        }
    }

    function timerStart(seconds) {
        if (seconds <= 0) return;
        root.timerTotal = seconds;
        root.timerLeft = seconds;
        root.timerDone = false;
        root.timerRunning = true;
    }
    function timerToggle() {
        if (root.timerDone) { root.timerClear(); return; }
        if (root.timerTotal <= 0) return;
        root.timerRunning = !root.timerRunning;
    }
    function timerClear() {
        root.timerRunning = false;
        root.timerTotal = 0;
        root.timerLeft = 0;
        root.timerDone = false;
    }

    function timerClock(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), x = sec % 60;
        const two = n => (n < 10 ? "0" + n : String(n));
        return h > 0 ? (h + ":" + two(m) + ":" + two(x)) : (m + ":" + two(x));
    }
    function timerSpoken(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), x = sec % 60;
        const parts = [];
        if (h > 0) parts.push(I18n.tr("{0} h", h));
        if (m > 0) parts.push(I18n.tr("{0} min", m));
        if (x > 0 && h === 0) parts.push(I18n.tr("{0} s", x));
        return parts.join(" ");
    }

    function parseDuration(text) {
        const t = String(text || "").trim().toLowerCase().replace(/\s+/g, "");
        if (t.length === 0) return -1;
        const hm = t.match(/^(\d+)h(\d{1,2})$/);
        if (hm) return parseInt(hm[1]) * 3600 + parseInt(hm[2]) * 60;
        const m = t.match(/^(?:(\d+)(?:horas?|hours?|hrs?|h))?(?:(\d+)(?:minutos?|minutes?|mins?|m))?(?:(\d+)(?:segundos?|seconds?|segs?|secs?|s))?$/);
        if (!m || (!m[1] && !m[2] && !m[3])) return -1;
        const sec = parseInt(m[1] || 0) * 3600 + parseInt(m[2] || 0) * 60 + parseInt(m[3] || 0);
        return (sec > 0 && sec <= 86400) ? sec : -1;
    }

    readonly property var wifiDev: {
        const ds = Networking.devices ? Networking.devices.values : [];
        for (let i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wifi) return ds[i];
        return null;
    }
    readonly property var wiredDev: {
        const ds = Networking.devices ? Networking.devices.values : [];
        for (let i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wired && ds[i].connected) return ds[i];
        return null;
    }
    readonly property var wifiNet: {
        if (!wifiDev || !wifiDev.networks) return null;
        const ns = wifiDev.networks.values;
        for (let i = 0; i < ns.length; i++) if (ns[i].connected) return ns[i];
        return null;
    }
    readonly property bool online: wiredDev !== null || wifiNet !== null

    readonly property bool hasWifi: wifiDev !== null

    readonly property bool wifiOn: Networking.wifiEnabled
    function setWifi(on) { Networking.wifiEnabled = on; }
    function toggleWifi() { root.setWifi(!root.wifiOn); }

    Binding {
        target: root.wifiDev
        property: "scannerEnabled"
        value: root.panel === "network"
        when: root.wifiDev !== null
        restoreMode: Binding.RestoreNone
    }
    property bool btScanWanted: false
    Binding {
        target: root.btAdapter
        property: "discovering"
        value: (root.panel === "bluetooth" || root.btScanWanted) && root.btOn
        when: root.btAdapter !== null
        restoreMode: Binding.RestoreNone
    }

    readonly property var wifiNetworks: {
        if (!wifiDev || !wifiDev.networks) return [];
        const ns = wifiDev.networks.values;
        const best = {};
        for (let i = 0; i < ns.length; i++) {
            const n = ns[i];
            const k = n.name || "";
            if (k.length === 0) continue;
            const prev = best[k];
            if (!prev || (n.signalStrength || 0) > (prev.signalStrength || 0)) best[k] = n;
        }
        const out = [];
        for (const k in best) out.push(best[k]);
        out.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return (b.signalStrength || 0) - (a.signalStrength || 0);
        });
        return out;
    }

    function wifiIconFor(s) {
        return s >= 72 ? "󰤨" : s >= 48 ? "󰤥" : s >= 24 ? "󰤢" : "󰤟";
    }
    function isSecured(net) {
        if (!net) return false;
        return net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Unknown;
    }
    function isEnterprise(net) {
        if (!net) return false;
        return net.security === WifiSecurityType.WpaEap
            || net.security === WifiSecurityType.Wpa2Eap
            || net.security === WifiSecurityType.Wpa3SuiteB192
            || net.security === WifiSecurityType.DynamicWep
            || net.security === WifiSecurityType.Leap;
    }
    function editEnterprise(net) {  }
    function openNetworkProfiles() {  }
    readonly property string netIcon: {
        if (wiredDev) return "󰈀";
        if (!wifiNet) return "󰤭";
        const s = wifiNet.signalStrength;
        return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟";
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter ? btAdapter.enabled : false
    readonly property int btConnected: {
        const ds = Bluetooth.devices ? Bluetooth.devices.values : [];
        let n = 0;
        for (let i = 0; i < ds.length; i++) if (ds[i].connected) n++;
        return n;
    }
    readonly property string btIcon: btBlocked ? "󰂲" : !btOn ? "󰂲" : (btConnected > 0 ? "󰂱" : "󰂯")

    readonly property bool btBlocked: btAdapter !== null && btAdapter.state === BluetoothAdapterState.Blocked

    readonly property var btPaired: {
        const vs = Bluetooth.devices ? Bluetooth.devices.values : [];
        const out = [];
        for (let i = 0; i < vs.length; i++) if (vs[i].paired || vs[i].bonded) out.push(vs[i]);
        out.sort(function (a, b) { return (b.connected ? 1 : 0) - (a.connected ? 1 : 0); });
        return out;
    }
    readonly property var btNearby: {
        const vs = Bluetooth.devices ? Bluetooth.devices.values : [];
        const out = [];
        for (let i = 0; i < vs.length; i++) if (!vs[i].paired && !vs[i].bonded) out.push(vs[i]);
        return out;
    }
    function btLabel(d) {
        if (!d) return "";
        return d.deviceName || d.name || d.address || "";
    }
    property bool btPendingOn: false

    function toggleBt() {
        if (!btAdapter) return;
        if (btBlocked) {
            btPendingOn = true;
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
            return;
        }
        btAdapter.enabled = !btAdapter.enabled;
    }

    onBtBlockedChanged: {
        if (!btBlocked && btPendingOn) {
            btPendingOn = false;
            if (btAdapter) btAdapter.enabled = true;
        }
    }

    property bool dnd: false
    property var lastNotif: null

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: function (n) {
            n.tracked = true;               // stays in the history
            root.lastNotif = n;
            Qt.callLater(root.trimNotifs);
            if (!root.dnd) root.flash("notif", root.notifFlashMs(n));
        }
    }

    Connections {
        target: root.lastNotif
        ignoreUnknownSignals: true
        function onClosed(reason) {
            root.lastNotif = null;
            if (root.activity === "notif") {
                root.activity = "";
                activityTimer.stop();
            }
        }
    }

    readonly property var notifications: {
        const vs = notifServer.trackedNotifications ? notifServer.trackedNotifications.values : [];
        return vs.slice().reverse();
    }
    readonly property int notifCount: notifications.length

    readonly property int notifMax: 50

    function trimNotifs() {
        if (!notifServer.trackedNotifications) return;
        const vs = notifServer.trackedNotifications.values;
        const sobran = vs.length - root.notifMax;
        if (sobran <= 0) return;
        const viejas = vs.slice(0, sobran);
        for (let i = 0; i < viejas.length; i++)
            if (viejas[i] !== root.lastNotif) viejas[i].expire();
    }

    function notifFlashMs(n) {
        const crit = !!n && n.urgency === NotificationUrgency.Critical;
        const suelo = crit ? 10000 : 1500;
        const techo = crit ? 12000 : 15000;
        const porDefecto = crit ? 11000 : 4200;
        if (!n) return porDefecto;
        const t = Number(n.expireTimeout);
        if (!isFinite(t) || t < 0) return porDefecto;   // -1: you decide
        if (t === 0) return techo;                      // 0: never expire
        return Math.max(suelo, Math.min(techo, Math.round(t)));
    }

    function dismissNotif(n) { if (n) n.dismiss(); }
    function clearNotifs() {
        const vs = notifServer.trackedNotifications ? notifServer.trackedNotifications.values.slice() : [];
        for (let i = 0; i < vs.length; i++) vs[i].dismiss();
    }

    readonly property string notifIcon: dnd ? (notifCount > 0 ? "󰂠" : "󰪓")
        : (notifCount > 0 ? "󱅫" : "󰂜")

    property bool caffeine: false
    property bool caffeineBeforeBattery: false
    property bool batteryIdleApplied: false
    function updateBatteryIdle() {
        if (!Config.loaded) return;
        if (Energy.onBattery && Config.batteryAllowIdle) {
            if (!root.batteryIdleApplied) {
                root.caffeineBeforeBattery = root.caffeine;
                root.batteryIdleApplied = true;
                root.caffeine = false;
            }
        } else if (root.batteryIdleApplied) {
            root.batteryIdleApplied = false;
            root.caffeine = root.caffeineBeforeBattery;
        }
    }
    Connections {
        target: Energy
        function onOnBatteryChanged() { root.updateBatteryIdle(); }
    }
    Connections {
        target: Config
        function onLoadedChanged() { root.updateBatteryIdle(); }
        function onBatteryAllowIdleChanged() { root.updateBatteryIdle(); }
    }
    Timer { interval: 1800; running: true; onTriggered: root.updateBatteryIdle() }

    readonly property var allApps: {
        const out = [];
        const vs = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        for (let i = 0; i < vs.length; i++) if (!vs[i].noDisplay) out.push(vs[i]);
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out;
    }

    function scoreApp(app, q) {
        const name = (app.name || "").toLowerCase();
        if (name === q) return 1000;
        if (name.startsWith(q)) return 900 - name.length * 0.1;
        const words = name.split(/[\s\-_.]+/);
        for (let i = 0; i < words.length; i++)
            if (words[i].startsWith(q)) return 800 - name.length * 0.1;
        const idx = name.indexOf(q);
        if (idx >= 0) return 700 - idx - name.length * 0.1;
        if ((app.genericName || "").toLowerCase().indexOf(q) >= 0) return 500;
        if ((app.comment || "").toLowerCase().indexOf(q) >= 0) return 400;
        let kw = "";
        try { kw = (app.keywords || []).join(" ").toLowerCase(); } catch (e) {}
        if (kw.indexOf(q) >= 0) return 300;
        let ti = 0;
        for (let i = 0; i < q.length; i++) {
            ti = name.indexOf(q[i], ti);
            if (ti < 0) return -1;
            ti++;
        }
        return 200 - name.length * 0.1;
    }

    function searchApps(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) {
            const apps = root.allApps.slice();
            if (Config.learnLauncher) apps.sort((a, b) => LauncherUsage.scoreOf(b.id)
                - LauncherUsage.scoreOf(a.id) || (a.name || "").localeCompare(b.name || ""));
            return apps;
        }
        const hits = [];
        for (let i = 0; i < root.allApps.length; i++) {
            const s = root.scoreApp(root.allApps[i], q);
            if (s > 0) hits.push({ app: root.allApps[i], score: s });
        }
        hits.sort((a, b) => Math.floor(b.score / 100) - Math.floor(a.score / 100)
            || (Config.learnLauncher ? LauncherUsage.scoreOf(b.app.id) - LauncherUsage.scoreOf(a.app.id) : 0)
            || b.score - a.score || (a.app.name || "").localeCompare(b.app.name || ""));
        return hits.map(h => h.app);
    }

    property string launcherMode: "apps"     // "apps" | "clip" | "cmd" | "win"

    readonly property var launcherModes: [
        
        { key: "cmd",  prefix: ">", icon: Icons.bolt,      name: I18n.tr("Acciones"),
          hint: I18n.tr("Buscar una acción del sistema…") },
        { key: "win",  prefix: "@", icon: Icons.windows,   name: I18n.tr("Ventanas"),
          hint: I18n.tr("Buscar una ventana abierta…") }
    ]

    readonly property var launcherAppsMode: ({ key: "apps", prefix: "", icon: "󰍉",
        name: I18n.tr("Aplicaciones"), hint: I18n.tr("Buscar aplicaciones…") })

    function launcherModeOf(ch) {
        for (let i = 0; i < root.launcherModes.length; i++)
            if (root.launcherModes[i].prefix === ch) return root.launcherModes[i].key;
        return "";
    }

    function launcherModeInfo(key) {
        for (let i = 0; i < root.launcherModes.length; i++)
            if (root.launcherModes[i].key === key) return root.launcherModes[i];
        return root.launcherAppsMode;
    }

    function openLauncher(m) {
        const mode = m === "clip" ? "apps" : (m || "apps");
        if (root.panel === "launcher" && root.launcherMode === mode) { root.closePanel(); return; }
        root.launcherMode = mode;
        root.launcherPreload(mode);
        if (mode === "clip") root.clipRefresh();
        if (mode === "win") root.winRefresh();
        root.panel = "launcher";
    }

    function launcherPreload(mode) {
        root.launcherCalc = false;
        root.launcherFavs = mode === "apps" && root.favApps.length > 0;
        root.launcherRows = mode === "apps" ? root.allApps.length
            : mode === "cmd" ? root.sysActions.length
            : mode === "win" ? root.winItems.length
            : root.clipItems.length > 0 ? root.clipItems.length : root.launcherMaxRows;
    }

    readonly property string clipTool: Quickshell.shellDir + "/scripts/cliphist-tool.sh"

    property var clipItems: []
    property bool clipLoading: false

    Process { id: clipListProc; property bool forceSync: false; property bool announce: false; }

    function clipRefresh() {  }

    function searchClip(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.clipItems;
        const out = [];
        for (let i = 0; i < root.clipItems.length; i++)
            if (root.clipItems[i].label.toLowerCase().indexOf(q) >= 0) out.push(root.clipItems[i]);
        return out;
    }

    function clipShort(t) {
        const s = String(t).replace(/\s+/g, " ").trim();
        return s.length > 32 ? s.slice(0, 32) + "…" : s;
    }

    function clipCopy(item) {  }

    function clipDelete(item) {  }

    readonly property var sysActions: [
        {
          kind: "cmd",
          id: "wallpapers",
          icon: Icons.monitor,
          name: "Wallpapers",
          desc: "Choose your desktop wallpaper",
          keys: "wallpaper wallpapers background image picture"
        },
        { kind: "cmd", id: "lock", icon: Icons.lock, name: I18n.tr("Bloquear pantalla"),
          desc: "hyprlock",
          keys: "lock bloquear candado lock screen padlock" },
        { kind: "cmd", id: "wifi", icon: Icons.wifi, name: I18n.tr("Wifi"),
          desc: I18n.tr("Redes disponibles"),
          keys: "wifi red network internet wi-fi wireless networks" },
        { kind: "cmd", id: "bt", icon: Icons.bluetooth, name: I18n.tr("Bluetooth"),
          desc: I18n.tr("Dispositivos emparejados"),
          keys: "bluetooth bt auriculares mando headphones headset controller pair devices" },
        { kind: "cmd", id: "overview", icon: Icons.grid, name: I18n.tr("Mapa de escritorios"),
          desc: I18n.tr("Ver y mover ventanas"),
          keys: "overview escritorios workspaces mapa workspace map windows grid" },
        { kind: "cmd", id: "system", icon: Icons.cpu, name: I18n.tr("Tu máquina"),
          desc: I18n.tr("Actividad, temperatura y batería"),
          keys: "sistema monitor cpu ram memoria disco temperatura bateria rendimiento equipo system memory disk temperature battery performance machine" },
        { kind: "cmd", id: "settings", icon: Icons.cog, name: I18n.tr("Ajustes"),
          desc: I18n.tr("Apariencia, sonido, atajos…"),
          keys: "settings ajustes preferencias config preferences configuration" },
        { kind: "cmd", id: "dnd", icon: Icons.bellOff, name: I18n.tr("No molestar"),
          desc: I18n.tr("Silenciar notificaciones"),
          keys: "dnd molestar silencio notificaciones do not disturb silence notifications mute" },
        { kind: "cmd", id: "caffeine", icon: Icons.coffee, name: I18n.tr("Café"),
          desc: I18n.tr("Impedir que se apague la pantalla"),
          keys: "caffeine cafe insomnio despierto suspender coffee awake keep screen on sleep" },
        { kind: "cmd", id: "power", icon: Icons.power, name: I18n.tr("Apagar / salir"),
          desc: I18n.tr("Apagar, reiniciar, cerrar sesión"),
          keys: "power apagar reiniciar salir logout suspender shutdown shut down restart reboot log out sign out suspend hibernate" }
    ]

    function searchActions(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.sysActions;
        const out = [];
        for (let i = 0; i < root.sysActions.length; i++) {
            const a = root.sysActions[i];
            const hay = (a.name + " " + a.desc + " " + a.keys).toLowerCase();
            if (hay.indexOf(q) >= 0) out.push(a);
        }
        return out;
    }

    function runAction(a) {
        if (!a || !root.sysActions.some(x => x.id === a.id)) return;

        switch (a.id) {
        case "wallpapers":root.openSettingsAt("wallpapers"); return;
        case "wifi":     root.panel = "network"; return;
        case "bt":       root.panel = "bluetooth"; return;
        case "power":    root.panel = "power"; return;
        case "overview": Hyprland.refreshToplevels(); root.panel = "overview"; return;
        case "system":   root.panel = "system"; return;
        case "settings": root.closePanel(); root.settingsOpen = true; return;
        case "dnd":
            root.dnd = !root.dnd; root.closePanel();
            root.toast(Icons.bell, root.dnd ? I18n.tr("No molestar activado")
                                            : I18n.tr("No molestar desactivado"));
            return;
        case "caffeine":
            root.caffeine = !root.caffeine; root.closePanel();
            root.toast(Icons.coffee, root.caffeine ? I18n.tr("Café: la pantalla no se apaga")
                                                   : I18n.tr("Café desactivado"));
            return;
        }

        root.closePanel();
        switch (a.id) {
        case "lock":  Quickshell.execDetached(["hyprlock"]); break;
        }
    }

    property int winTick: 0
    Timer {
        id: winPoll
        interval: 90
        onTriggered: { Hyprland.refreshToplevels(); root.winTick++; }
    }
    function winRefresh() { Hyprland.refreshToplevels(); root.winTick++; }
    Connections {
        target: Hyprland
        enabled: root.panel === "launcher" && root.launcherMode === "win"
        function onRawEvent(ev) {
            const n = String(ev.name);
            if (n.indexOf("window") >= 0 || n.indexOf("title") >= 0 || n.indexOf("workspace") >= 0)
                winPoll.restart();
        }
    }

    readonly property var winItems: {
        root.winTick;   // dependency on purpose: see the note above
        const out = [];
        const ts = Hyprland.toplevels ? [...Hyprland.toplevels.values] : [];
        for (let i = 0; i < ts.length; i++) {
            const t = ts[i];
            if (!t || !t.workspace || t.workspace.id < 1) continue;   // leave out the special ones
            const c = t.lastIpcObject;
            const cls = c ? String(c["class"] || "") : "";
            out.push({
                kind: "win",
                addr: (function () {
                    const s = String(t.address || "");
                    return s.startsWith("0x") ? s : "0x" + s;
                })(),
                ws: t.workspace.id,
                cls: cls,
                title: (t.title && t.title.length > 0) ? String(t.title) : cls,
                icon: root.iconForClass(cls),
                tl: t
            });
        }
        out.sort((a, b) => a.ws - b.ws || a.title.localeCompare(b.title));
        return out;
    }

    function iconForClass(cls) {
        if (!cls) return "";
        try {
            const e = DesktopEntries.heuristicLookup(cls);
            if (e && e.icon) return e.icon;
        } catch (err) {}
        return cls.toLowerCase();
    }

    function searchWins(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.winItems;
        const out = [];
        for (let i = 0; i < root.winItems.length; i++) {
            const w = root.winItems[i];
            if ((w.title + " " + w.cls + " " + w.ws).toLowerCase().indexOf(q) >= 0) out.push(w);
        }
        return out;
    }

    property string winPending: ""
    Timer {
        id: winFocusDefer
        interval: 60
        onTriggered: {
            if (root.winPending === "") return;
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + root.winPending + '" })');
            root.winPending = "";
        }
    }
    function focusWindow(w) {
        if (!w) return;
        root.winPending = w.addr;
        root.closePanel();
        winFocusDefer.restart();
    }

    readonly property var calcWords: ["sqrt", "abs", "sin", "cos", "tan", "asin", "acos", "atan",
        "log", "log2", "log10", "exp", "round", "floor", "ceil", "min", "max", "pow", "pi", "e"]

    function calcEval(q) {
        let e = (q || "").trim();
        if (e.startsWith("=")) e = e.slice(1);      // "=" forces calculator mode
        if (e.length === 0) return null;
        if (!/\d/.test(e)) return null;                    // no numbers, no sum
        if (!/[+\-*\/^%()]/.test(e)) return null;           // no operator either: "5" is not a sum

        if (!/^[0-9\s+\-*\/^%().,×÷a-zA-Z]+$/.test(e)) return null;
        const words = e.match(/[a-zA-Z]+/g) || [];
        for (let i = 0; i < words.length; i++)
            if (root.calcWords.indexOf(words[i].toLowerCase()) < 0) return null;

        let x = e.replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");
        x = x.replace(/(\d),(\d)/g, "$1.$2");               // decimal comma
        x = x.replace(/\bpi\b/gi, "Math.PI").replace(/\be\b/gi, "Math.E");
        x = x.replace(/\b(sqrt|abs|sin|cos|tan|asin|acos|atan|log2|log10|log|exp|round|floor|ceil|min|max|pow)\b/gi,
                      function (m) { return "Math." + m.toLowerCase(); });
        try {
            const v = Function('"use strict"; return (' + x + ')')();
            if (typeof v !== "number" || !isFinite(v)) return null;
            return v;
        } catch (err) {
            return null;
        }
    }

    function calcFormat(v) {
        if (v === null || v === undefined) return "";
        const r = Math.round(v * 1e10) / 1e10;
        if (Number.isInteger(r) && Math.abs(r) < 1e15) return String(r);
        return String(parseFloat(r.toPrecision(12)));
    }

    function copyText(t) {
        Quickshell.clipboardText = String(t);
        root.toast("󰆏", I18n.tr("Copiado: {0}", t));
    }

    property string toastIcon: ""
    property string toastText: ""
    function toast(icon, text) {
        root.toastIcon = icon;
        root.toastText = text;
        root.flash("toast");
    }

    function launchApp(app) {
        if (!app) return;
        root.closePanel();
        app.execute();
        if (Config.learnLauncher) LauncherUsage.record(app.id);
    }

    readonly property var favApps: {
        const out = [];
        const ids = Config.favApps;
        for (let i = 0; i < ids.length; i++) {
            const a = root.appById(ids[i]);
            if (a) out.push(a);
        }
        return out;
    }

    function appById(id) {
        const vs = root.allApps;
        for (let i = 0; i < vs.length; i++) if (vs[i].id === id) return vs[i];
        return null;
    }

    function isFav(app) { return !!app && Config.favApps.indexOf(app.id) >= 0; }

    function toggleFav(app) {
        if (!app) return;
        const ids = Config.favApps.slice();
        const i = ids.indexOf(app.id);
        if (i >= 0) ids.splice(i, 1); else ids.push(app.id);
        Config.favApps = ids;
        Config.save();
    }

    property string btKind: ""     // "" | "confirm" | "display" | "authorize"
    property string btName: ""     // name of the device
    property string btCode: ""     // the six digits, "" if there are none
    property int btEntered: -1     // digits already typed (only in "display")
    readonly property bool btAsking: root.btKind !== ""

    function btAsk(kind, name, code, entered) {
        root.btKind = kind;
        root.btName = name;
        root.btCode = code;
        root.btEntered = entered;
    }

    function btClear() {
        root.btKind = ""; root.btName = ""; root.btCode = ""; root.btEntered = -1;
    }

    function btReply(accept) {
        btReplyProc.command = ["busctl", "--user", "call",
            "org.quickshell.BtAgent", "/org/quickshell/btagent",
            "org.quickshell.BtAgent1", "Reply", "b", accept ? "true" : "false"];
        btReplyProc.running = true;
        root.btClear();
    }

    Process { id: btReplyProc }

    function moveFav(from, to) {
        const ids = Config.favApps.slice();
        if (from < 0 || from >= ids.length) return;
        let t = Math.max(0, Math.min(ids.length, to));
        if (t > from) t -= 1;
        if (t === from) return;
        ids.splice(t, 0, ids.splice(from, 1)[0]);
        Config.favApps = ids;
        Config.save();
    }
}

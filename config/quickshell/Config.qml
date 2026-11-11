// Customized for Daniel: Gruvbox / NixOS. Upstream attribution: NOTICE.md.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "AppearanceProfiles.js" as Profiles

Singleton {
    id: root

    property alias language: opts.language

    property alias energyOnAC: opts.energyOnAC
    property alias energyOnBattery: opts.energyOnBattery
    property alias batteryAllowIdle: opts.batteryAllowIdle
    property alias dimOnSaver: opts.dimOnSaver
    property alias saverBrightness: opts.saverBrightness
    property bool powerSaverActive: false

    property alias notchStyle: opts.notchStyle
    property alias islandGap: opts.islandGap
    readonly property bool island: opts.notchStyle === "island"

    property alias notchColor: opts.notchColor
    property alias bandH: opts.bandH            // band height = notch height at rest
    property alias flare: opts.flare            // radius of the inverted top corner
    property alias roundMax: opts.roundMax      // maximum bottom radius
    property alias idleW: opts.idleW            // width at rest for the TIME ALONE; grows if you enable date or battery
    property alias hoverPreview: opts.hoverPreview
    property alias hoverDelay: opts.hoverDelay  // ms before the "peek" opens
    property alias browserMedia: opts.browserMedia
    property alias showDate: opts.showDate
    property alias showBattery: opts.showBattery
    property alias reserveSpace: opts.reserveSpace

    property alias scrimAlpha: opts.scrimAlpha  // veil under the bar (0 = transparent)
    property alias sideMargin: opts.sideMargin
    property alias showArch: opts.showArch
    property alias showWorkspaces: opts.showWorkspaces
    property alias showAppName: opts.showAppName
    property alias showTray: opts.showTray

    property alias favApps: opts.favApps
    property alias learnLauncher: opts.learnLauncher
    property alias appearanceProfiles: opts.appearanceProfiles

    property alias displays: opts.displays

    function appearanceSnapshot() { return Profiles.snapshot(root); }

    function uniqueName(label, exceptId) {
        const usados = opts.appearanceProfiles
            .filter(p => p.id !== exceptId)
            .map(p => String(p.name || "").trim().toLowerCase());
        if (usados.indexOf(label.toLowerCase()) < 0) return label;
        for (let n = 2; n < 1000; n++) {
            const probe = (label + " " + n).slice(0, 48);
            if (usados.indexOf(probe.toLowerCase()) < 0) return probe;
        }
        return label;
    }

    function saveProfile(name) {
        if (!root.loaded) return false;
        const label = String(name || "").trim().slice(0, 48);
        if (!label) return false;
        const entries = opts.appearanceProfiles.slice();
        entries.push({ id: Date.now().toString(36) + Math.random().toString(36).slice(2, 8),
                       name: root.uniqueName(label, null), values: root.appearanceSnapshot() });
        opts.appearanceProfiles = entries;
        root.save();
        return true;
    }
    function changeProfile(id, name, replaceValues) {
        if (!root.loaded) return false;
        const entries = opts.appearanceProfiles.slice();
        const at = entries.findIndex(p => p.id === id);
        const label = String(name || "").trim().slice(0, 48);
        if (at < 0 || !label) return false;
        if (!replaceValues && entries[at].name === label) return true;
        entries[at] = { id: id, name: root.uniqueName(label, id),
            values: replaceValues ? root.appearanceSnapshot() : entries[at].values };
        opts.appearanceProfiles = entries;
        root.save();
        return true;
    }
    function removeProfile(id) {
        if (!root.loaded) return;
        opts.appearanceProfiles = opts.appearanceProfiles.filter(p => p.id !== id);
        root.save();
    }
    function applyProfile(values) {
        if (!root.loaded) return false;
        const clean = Profiles.complete(values);
        if (!clean) return false;
        for (const key of Object.keys(clean)) root[key] = clean[key];
        
        root.save();
        return true;
    }

    property alias fontUI: opts.fontUI
    property alias clockSize: opts.clockSize

    readonly property var fontChoices: ["Liberation Sans", "CaskaydiaCove Nerd Font", "Iosevka Nerd Font", "JetBrainsMono Nerd Font"]

    property bool loaded: false
    function save() { if (root.loaded) saver.restart(); }
    Timer { id: saver; interval: 0; onTriggered: file.writeAdapter() }

    function reset() {
        opts.notchStyle = "notch"; opts.islandGap = 4;
        opts.notchColor = "#000000";
        opts.bandH = 32; opts.flare = 13; opts.roundMax = 30; opts.idleW = 140;
        opts.hoverDelay = 240; opts.hoverPreview = true; opts.browserMedia = false;
        opts.showDate = false; opts.showBattery = false; opts.reserveSpace = true;
        opts.scrimAlpha = 0.0; opts.sideMargin = 16;
        opts.showArch = true; opts.showWorkspaces = true;
        opts.showAppName = true; opts.showTray = true;
        opts.fontUI = "Liberation Sans"; opts.clockSize = 17;
        root.save();
    }

    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell-settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: root.save()
        onLoaded: { root.loaded = true;  }
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) { root.loaded = true; root.save();  }
        }

        JsonAdapter {
            id: opts

            property string language: "en"

            property string energyOnAC: "performance"
            property string energyOnBattery: "power-saver"
            property bool batteryAllowIdle: true
            property bool dimOnSaver: true
            property int saverBrightness: 40

            property string notchStyle: "notch"
            property int islandGap: 4
            property string notchColor: "#1d2021"
            property int bandH: 32
            property int flare: 13
            property int roundMax: 30
            property int idleW: 140
            property bool hoverPreview: true
            property int hoverDelay: 240
            property bool browserMedia: false
            property bool showDate: false   // at rest only time and battery; the full date appears on hover
            property bool showBattery: false
            property bool reserveSpace: true

            property real scrimAlpha: 0.0
            property int sideMargin: 16
            property bool showArch: true
            property bool showWorkspaces: true
            property bool showAppName: true
            property bool showTray: true

            property string fontUI: "Liberation Sans"
            property int clockSize: 17

            property list<string> favApps: []
            property bool learnLauncher: true
            property var appearanceProfiles: []
            property var displays: ({})
        }
    }
}

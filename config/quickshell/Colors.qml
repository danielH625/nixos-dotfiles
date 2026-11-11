// Gruvbox shell component. Upstream attribution: NOTICE.md.
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property color bg:      "#1d2021"
    property color bgAlt:   "#282828"
    property color fg:      "#d4be98"
    property color accent:  "#7daea3"
    property color accent2: "#d8a657"
    property color dim:     "#928374"
    property color c1: "#ea6962"
    property color c2: "#a9b665"
    property color c3: "#d8a657"
    property color c4: "#7daea3"
    property color c5: "#d3869b"

    readonly property color blue: "#7daea3"
    readonly property color orange: "#e78a4e"
    readonly property color aqua: "#89b482"
    readonly property color purple: "#d3869b"
    readonly property color yellow: "#d8a657"
    readonly property color workspaceAccent: accent2
    readonly property color volumeAccent: aqua
    readonly property color brightnessAccent: yellow

    readonly property color ok:   "#a9b665"
    readonly property color warn: "#d8a657"
    readonly property color crit: "#ea6962"

    property string wallpaper: ""

    readonly property bool darkWall: wallStrip.hslLightness < 0.5

    readonly property color onWallAccent: {
        const h = workspaceAccent.hslHue < 0 ? 0 : workspaceAccent.hslHue;
        const s = workspaceAccent.hslSaturation < 0.08
            ? workspaceAccent.hslSaturation : workspaceAccent.hslSaturation;
        let l = workspaceAccent.hslLightness;
        let out = Qt.hsla(h, s, l, 1);
        for (let i = 0; i < 60 && contrast(out, wallStrip) < 3.5; i++) {
            l = darkWall ? Math.min(l + 0.02, 1) : Math.max(l - 0.02, 0);
            out = Qt.hsla(h, s, l, 1);
        }
        return out;
    }

    readonly property color onWallDim: {
        const h = workspaceAccent.hslHue < 0 ? 0 : workspaceAccent.hslHue;
        const target = Math.sqrt(contrast(onWallAccent, wallStrip));
        let l = wallStrip.hslLightness;
        let out = Qt.hsla(h, 0.12, l, 1);
        for (let i = 0; i < 60 && contrast(out, wallStrip) < target; i++) {
            l = darkWall ? Math.min(l + 0.02, 1) : Math.max(l - 0.02, 0);
            out = Qt.hsla(h, 0.12, l, 1);
        }
        return out;
    }

    property color wallStrip: bg

    function _lin(x) { return x <= 0.03928 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4); }
    function luminance(c) { return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b); }
    function contrast(a, b) {
        const x = luminance(a), y = luminance(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    function inkOn(base) {
        const cand = [bg, fg, Qt.rgba(0, 0, 0, 1), Qt.rgba(1, 1, 1, 1)];
        let mejor = cand[0], mejorC = 0;
        for (let i = 0; i < cand.length; i++) {
            const k = contrast(cand[i], base);
            if (k >= 4.5) return cand[i];       // the first one from the theme that makes it
            if (k > mejorC) { mejorC = k; mejor = cand[i]; }
        }
        return mejor;
    }
    readonly property color accentText:  inkOn(accent)
    readonly property color accent2Text: inkOn(accent2)

    function typeInk(hex) {
        if (!hex)
            return dim;
        const c = Qt.color(hex);
        const oscuro = bg.hslLightness < 0.5;
        const luz = oscuro ? Math.max(c.hslLightness, 0.66)
                           : Math.min(c.hslLightness, 0.38);
        return Qt.hsla(c.hslHue < 0 ? 0 : c.hslHue, Math.max(c.hslSaturation, 0.45), luz, 1);
    }

    readonly property string notchTheme: "theme"
    function notchTint(v) {
        return (!v || String(v) === root.notchTheme) ? root.bg : v;
    }

    function _mixFg(a) {
        return Qt.rgba(bg.r + (fg.r - bg.r) * a,
                       bg.g + (fg.g - bg.g) * a,
                       bg.b + (fg.b - bg.b) * a, 1);
    }

    function inkLevel(target) {
        let lo = 0, hi = 1;
        for (let i = 0; i < 40; i++) {
            const mid = (lo + hi) / 2;
            if (contrast(_mixFg(mid), bg) < target) lo = mid; else hi = mid;
        }
        return _mixFg((lo + hi) / 2);
    }

    readonly property color label:  fg                 // the datum
    readonly property color label2: inkLevel(7.0)      // what goes with the datum
    readonly property color label3: inkLevel(5.0)      // labels, units, notes
    readonly property color label4: inkLevel(3.5)      // disabled ONLY

    function surface(n) {
        if (n <= 0)
            return bg;
        const paso = 0.045 * n;
        const l = darkTheme ? Math.min(bg.hslLightness + paso, 1)
                            : Math.max(bg.hslLightness - paso, 0);
        return Qt.hsla(bg.hslHue < 0 ? 0 : bg.hslHue, bg.hslSaturation, l, 1);
    }
    readonly property bool darkTheme: bg.hslLightness < 0.5
    readonly property color surface1: surface(1)       // group within the view
    readonly property color surface2: surface(2)       // group within the group

    function _inkAccent(base, sobre) {
        const h = base.hslHue < 0 ? 0 : base.hslHue;
        const s = base.hslSaturation < 0.08
            ? base.hslSaturation : Math.max(base.hslSaturation, 0.45);
        let l = base.hslLightness;
        let out = Qt.hsla(h, s, l, 1);
        const subir = sobre.hslLightness < 0.5;
        for (let i = 0; i < 80 && contrast(out, sobre) < 4.5; i++) {
            l = subir ? Math.min(l + 0.01, 1) : Math.max(l - 0.01, 0);
            out = Qt.hsla(h, s, l, 1);
        }
        return out;
    }
    readonly property color accentInk:  _inkAccent(accent, bg)
    readonly property color accent2Ink: _inkAccent(accent2, bg)

    function _fg(a) { return Qt.rgba(fg.r, fg.g, fg.b, a) }
    readonly property color fill1:  _fg(0.14)   // pressed, selected
    readonly property color fill2:  _fg(0.09)   // hover
    readonly property color fill3:  _fg(0.055)  // rest state of a body with a background
    readonly property color hairline: _fg(0.10) // the border and the separator, a single one

    function _c(hex, fb) { return (hex && String(hex).length > 0) ? hex : fb }

    function apply() {  }
}

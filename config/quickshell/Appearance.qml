// Gruvbox shell component. Upstream attribution: NOTICE.md.
pragma Singleton
import Quickshell
import QtQuick   // FontMetrics, to centre the clock by its real metrics

Singleton {
    id: root
    readonly property string font: "JetBrainsMono Nerd Font"

    readonly property string fontUI: Config.fontUI   // chosen in Settings › Appearance

    readonly property string fontClock: Config.fontUI

    function clockPixelSize(base) {
        if (fontClock === fontUI)
            return base;
        return Math.max(8, Math.round(base / 8) * 8);
    }

    readonly property int clockQuantum: fontClock === fontUI ? 1 : 8

    FontMetrics {
        id: clockMetrics
        font.family: root.fontClock
        font.pixelSize: 100
    }

    readonly property real clockNudgeRatio: {
        var r = clockMetrics.tightBoundingRect("0123456789:");
        var centroDigitos = r.y + r.height / 2;                        // < 0: above the baseline
        var centroCaja = (clockMetrics.descent - clockMetrics.ascent) / 2;
        return (centroCaja - centroDigitos) / 100;
    }

    function clockNudge(base) {
        if (fontClock === fontUI)
            return 0;
        return Math.round(clockPixelSize(base) * clockNudgeRatio);
    }

    readonly property int fsXXS: 10
    readonly property int fsXS: 11
    readonly property int fsS:  12
    readonly property int fsM:  13
    readonly property int fsL:  16
    readonly property int fsXL: 22
    readonly property int fsXXL: 42

    readonly property var _leadTable: [[10,13],[11,14],[12,15],[13,16],[15,20],[17,22],[22,26],[26,32]]
    function leading(px) {
        const t = _leadTable;
        if (px <= t[0][0])
            return Math.round(px * t[0][1] / t[0][0]);
        for (let i = 1; i < t.length; i++) {
            if (px === t[i][0])
                return t[i][1];
            if (px < t[i][0]) {
                const a = t[i - 1], b = t[i];
                return Math.round(a[1] + (b[1] - a[1]) * (px - a[0]) / (b[0] - a[0]));
            }
        }
        const ult = t[t.length - 1];
        return Math.round(px * ult[1] / ult[0]);
    }

    readonly property int wRegular: Font.Normal
    readonly property int wMedium:  Font.Medium     // selected, soft emphasis
    readonly property int wSemi:    Font.DemiBold   // Apple's "emphasized"
    readonly property int wBold:    Font.Bold       // heading at body size

    readonly property int radS: 10
    readonly property int radM: 14
    readonly property int radL: 18
    readonly property int radPill: 999

    function radInner(radOuter, margin) {
        return Math.max(2, radOuter - margin);
    }

    readonly property int gapS: 6
    readonly property int gapM: 10
    readonly property int gapL: 14
    readonly property int pad:  16

    readonly property int mQuick: 130        // RESPONSE: hover, colour, press, knobs
    readonly property int mIn: 210           // CONTENT coming in (opacity)
    readonly property int mOut: 110          // CONTENT going out: half
    readonly property int mInScale: 320      // PANEL coming in (scale, elastic)
    readonly property int mOutScale: 170     // PANEL going out
    readonly property int mShape: 440        // SHAPE: the notch morph
    readonly property int mOutShape: 220     // SHAPE going out

    readonly property int animFast: mQuick
    readonly property int animMed:  mIn
    readonly property int animSlow: mInScale

    readonly property real mOvershoot: 1.3    // the shape morph
    readonly property real mInOvershoot: 1.05 // content and panels coming in
    readonly property real mScaleFrom: 0.90   // where incoming things grow from

    readonly property int mTick: 500

    readonly property int mStagger: 110      // = mOut

    readonly property real sprTight: 5.2      // RESPONSE: arrives and stays, barely overshooting
    readonly property real dmpTight: 0.58

    readonly property real sprPanel: 4.0      // PANEL: a surface that appears
    readonly property real dmpPanel: 0.42

    readonly property real sprLoose: 3.1      // SHAPE: the morph, with travel to spare
    readonly property real dmpLoose: 0.34

    readonly property real sprSquash: 6.5

    readonly property real eppPx: 0.25
    readonly property real eppScale: 0.001

    readonly property int mTravel: 34
}

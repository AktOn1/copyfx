import QtQuick
import "../.."

// The original letters drop into place like falling blocks in tetromino colours.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: fx.n * fx.step * 0.7 + 800
  readonly property var pal: ["#00f0f0", "#f0f000", "#a000f0", "#00f000", "#f00000", "#0000f0", "#f0a000"]
  function p(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.7) / 380)) }
  dyFn: function(i) { var q = fx.p(i); return -(1 - q) * (1 - q) * fx.lh * 4 }
  alphaFn: function(l, cx, cy, gi) { return fx.p(gi) > 0 ? 1 : 0 }
  colorFn: function(i) { return fx.p(i) < 1 ? fx.pal[i % 7] : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

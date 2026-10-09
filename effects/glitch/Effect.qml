import QtQuick
import "../.."

// The original text tears: letters jitter and split into red and cyan for a moment.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 800
  function on(i) { return fx.t < 520 && fx.hash(i, Math.floor(fx.t / 55)) > 0.72 }
  dxFn: function(i) { return fx.on(i) ? (fx.hash(i, 3) - 0.5) * fx.lh * 1.2 : 0 }
  colorFn: function(i) { return fx.on(i) ? (fx.hash(i, 5) > 0.5 ? "#ff2a6d" : "#05d9e8") : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

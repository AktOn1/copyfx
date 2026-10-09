import QtQuick
import "../.."

// The original letters hop one after another, first to last.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: fx.n * fx.step + 700
  dyFn: function(i) { var a = fx.t - i * fx.step; return a < 0 || a > 520 ? 0 : -Math.sin(a / 520 * Math.PI) * fx.lh * 0.8 }
  colorFn: function(i) { var a = fx.t - i * fx.step; return a >= 0 && a < 520 ? fx.accent : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

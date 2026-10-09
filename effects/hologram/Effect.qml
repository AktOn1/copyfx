import QtQuick
import "../.."

// The original text flickers as a cyan hologram with scanlines.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1200
  hlColor: "#062a33"
  colorFn: function() { return "#7ff9ff" }
  alphaFn: function(l, cx, cy, gi) { return fx.t < 600 && Math.floor(fx.t / 45 + gi) % 5 === 0 ? 0.4 : 1 }
  Scanlines { x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; gap: 3; strength: 0.35; opacity: fx.hlAlpha }
  Rectangle { x: fx.tg.x; y: fx.tg.y + (fx.tg.h - 2) * ((fx.t % 700) / 700); width: fx.tg.w; height: 2; color: "#7ff9ff"; opacity: 0.6 * fx.hlAlpha }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

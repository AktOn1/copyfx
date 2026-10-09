import QtQuick
import "../.."

// The original text flashes stamp-red with a shake, a border and a shockwave.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 900
  dxFn: function(i) { return fx.t < 240 ? (i % 2 ? 2 : -2) * (1 - fx.t / 240) : 0 }
  colorFn: function() { return fx.t < 520 ? "#ff5c57" : fx.srcFg }
  Rectangle { x: fx.tg.x - 6; y: fx.tg.y - 4; width: fx.tg.w + 12; height: fx.tg.h + 8; radius: 6; color: "transparent"; border.color: "#ff5c57"; border.width: 2; opacity: fx.t < 520 ? 1 : Math.max(0, 1 - (fx.t - 520) / 300) }
  Rectangle {
    readonly property real p: Math.min(1, fx.t / 550)
    readonly property real d: 30 * fx.u + p * Math.max(fx.tg.w, 120)
    x: fx.tg.x + fx.tg.w / 2 - d / 2; y: fx.tg.y + fx.tg.h / 2 - d / 2; width: d; height: d; radius: d / 2
    color: "transparent"; border.color: fx.accent; border.width: 3 * fx.u; opacity: fx.t <= 0 ? 0 : 0.8 * (1 - p)
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

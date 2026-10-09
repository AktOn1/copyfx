import QtQuick
import "../.."

// An amber LED display: dotted amber letters flicker on a dark block.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1100
  hlColor: "#140a00"
  colorFn: function() { return "#ffb000" }
  alphaFn: function() { return fx.t < 500 && Math.floor(fx.t / 70) % 3 === 0 ? 0.5 : 1 }
  Scanlines { x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; gap: 3; strength: 0.45; opacity: fx.hlAlpha }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

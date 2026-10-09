import QtQuick
import "../.."

// The original text flickers on as a neon sign and settles into a pink glow.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1500
  readonly property var fl: [1, 0.15, 1, 0.3, 0.3, 1, 0.6, 1, 1]
  readonly property real a: fx.t < 630 ? fx.fl[Math.floor(fx.t / 70)] : 1
  hlColor: "#0b0714"
  colorFn: function() { return "#ffb3ec" }
  alphaFn: function() { return fx.a }
  Rectangle { x: fx.tg.x - 6; y: fx.tg.y - 5; width: fx.tg.w + 12; height: fx.tg.h + 10; radius: 8; color: "transparent"; border.color: "#ff3dcb"; border.width: 2; opacity: fx.a * fx.hlAlpha }
  Rectangle { x: fx.tg.x - 11; y: fx.tg.y - 10; width: fx.tg.w + 22; height: fx.tg.h + 20; radius: 12; color: "transparent"; border.color: "#ff3dcb"; border.width: 2; opacity: 0.25 * fx.a * fx.hlAlpha }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

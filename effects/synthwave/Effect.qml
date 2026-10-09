import QtQuick
import "../.."

// Pink-to-cyan gradient letters on a dusk block with neon lines drawn under them.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1300
  hlColor: "#1a0b2e"
  colorFn: function(i, cx) { var q = fx.tg.w > 0 ? Math.max(0, Math.min(1, (cx - fx.tg.x) / fx.tg.w)) : 0; return Qt.hsla(0.9 - 0.4 * q, 1, 0.65, 1) }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - Math.min(1, fx.t / 400)); y: fx.tg.y + fx.tg.h + 3; width: fx.tg.w * Math.min(1, fx.t / 400); height: 2; color: "#ff2fd1" }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - Math.min(1, fx.t / 400)); y: fx.tg.y + fx.tg.h + 8; width: fx.tg.w * Math.min(1, fx.t / 400); height: 2; color: "#00e5ff" }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - Math.min(1, fx.t / 400)); y: fx.tg.y - 5; width: fx.tg.w * Math.min(1, fx.t / 400); height: 2; color: "#ff2fd1" }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

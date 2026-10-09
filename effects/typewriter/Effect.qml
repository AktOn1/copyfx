import QtQuick
import "../.."

// The original text is typed out letter by letter with a blinking caret.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real per: Math.max(6, Math.min(30, 800 / Math.max(1, fx.n)))
  readonly property int k: Math.floor(fx.t / fx.per)
  readonly property real total: fx.n * fx.per + 300 + 150
  alphaFn: function(l, cx, cy, gi) { return gi < fx.k ? 1 : 0 }
  Rectangle {
    readonly property var g: fx.glyphItems[Math.min(fx.k, fx.n - 1)]
    readonly property point gp: g ? g.mapToItem(fx, 0, 0) : Qt.point(fx.tg.x, fx.tg.y)
    x: gp.x + (fx.k >= fx.n && g ? g.width : 0); y: gp.y + (g ? g.height : fx.lh) * 0.1
    width: 2; height: (g ? g.height : fx.lh) * 0.8
    color: fx.srcFg; visible: Math.floor(fx.t / 350) % 2 === 0 || fx.k < fx.n
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

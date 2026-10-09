import QtQuick
import "../.."

// A cannon sweeps under the original text and zaps the letters away line by line.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 500 + fx.n * 22 + 400
  readonly property real prog: Math.min(1, fx.t / (fx.total - 400))
  readonly property var sw: fx.sweep(fx.prog * fx.lineRects.length)
  alphaFn: function(l, cx, cy, gi) { if (!fx.hasSel) return gi < fx.prog * fx.n ? 0 : 1; return l < fx.sw.li || (l === fx.sw.li && cx < fx.sw.x - 3) ? 0 : 1 }
  colorFn: function(i, cx, cy) { return fx.hasSel && Math.abs(cx - fx.sw.x) < fx.lh * 0.7 && Math.abs(cy - fx.sw.r.y - fx.sw.r.h / 2) < fx.sw.r.h ? "#ff4d4d" : fx.srcFg }
  Rectangle { x: fx.sw.x - 1; y: fx.sw.r.y; width: 2; height: fx.sw.r.h + 3; color: "#7cff7c"; opacity: 0.85; visible: fx.prog < 1 }
  Rectangle { x: fx.sw.x - 8; y: fx.sw.r.y + fx.sw.r.h + 2; width: 16; height: 6; color: "#7cff7c"; visible: fx.prog < 1
    Rectangle { x: 6; y: -4; width: 4; height: 5; color: "#7cff7c" } }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

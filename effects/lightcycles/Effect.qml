import QtQuick
import "../.."

// Two light cycles race around the original text and leave glowing trails.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1500
  readonly property real p: Math.min(1, fx.t / 800)
  readonly property real fade: fx.t > 1100 ? Math.max(0, 1 - (fx.t - 1100) / 300) : 1
  Rectangle { x: fx.tg.x - 3; y: fx.tg.y - 4; width: (fx.tg.w + 6) * fx.p; height: 2; color: "#00e5ff"; opacity: fx.fade }
  Rectangle { x: fx.tg.x - 3 + (fx.tg.w + 6) * fx.p - 3; y: fx.tg.y - 6; width: 6; height: 6; color: "#ffffff"; opacity: fx.fade * (fx.p < 1 ? 1 : 0) }
  Rectangle { x: fx.tg.x + fx.tg.w + 3 - (fx.tg.w + 6) * fx.p; y: fx.tg.y + fx.tg.h + 2; width: (fx.tg.w + 6) * fx.p; height: 2; color: "#ff9f1c"; opacity: fx.fade }
  Rectangle { x: fx.tg.x + fx.tg.w + 3 - (fx.tg.w + 6) * fx.p - 3; y: fx.tg.y + fx.tg.h; width: 6; height: 6; color: "#ffffff"; opacity: fx.fade * (fx.p < 1 ? 1 : 0) }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

import QtQuick
import "../.."

// A ring pulses on the original text and the selection flashes in the accent colour.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 900
  Rectangle {
    anchors.fill: undefined
    x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; radius: 3
    color: fx.accent; opacity: fx.t < 120 ? fx.t / 120 * 0.4 : Math.max(0, 0.4 * (1 - (fx.t - 120) / 500))
  }
  Rectangle {
    readonly property real p: Math.min(1, fx.t / 520)
    readonly property real d: 20 * fx.u + p * Math.max(fx.tg.w, 90)
    x: fx.tg.x + fx.tg.w / 2 - d / 2; y: fx.tg.y + fx.tg.h / 2 - d / 2; width: d; height: d; radius: d / 2
    color: "transparent"; border.color: fx.accent; border.width: 2
    opacity: fx.t <= 0 ? 0 : 0.9 * (1 - p)
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

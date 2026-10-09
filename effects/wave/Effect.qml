import QtQuick
import "../.."

// The original letters ride a wave and change colour along the rainbow.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1600
  readonly property real amp: Math.min(1, fx.t / 250) * (fx.t > 1300 ? Math.max(0, 1 - (fx.t - 1300) / 300) : 1)
  dyFn: function(i) { return Math.sin(fx.t / 130 + i * 0.55) * fx.lh * 0.3 * fx.amp }
  colorFn: function(i) { return fx.amp > 0.02 ? Qt.hsla(((fx.t / 900 + i * 0.03) % 1 + 1) % 1, 0.75, 0.65, 1) : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

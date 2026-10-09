import QtQuick
import "../.."

// Every letter of the original text flashes red, one after another, first to last.
SourceText {
  id: fx

  property real t: 0                                              // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(60, 700 / Math.max(1, fx.n)))
  readonly property real total: fx.n * fx.step + 200
  colorFn: function(i) { var a = i * fx.step; return fx.t >= a && fx.t < a + 160 ? "#ff3b30" : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

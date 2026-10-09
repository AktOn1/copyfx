import QtQuick
import "../.."

// All letters of the original text flash red once, together.
SourceText {
  id: fx

  property real t: 0                                              // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(60, 700 / Math.max(1, fx.n)))
  readonly property real total: 260
  colorFn: function(i) { return fx.t < 170 ? "#ff3b30" : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

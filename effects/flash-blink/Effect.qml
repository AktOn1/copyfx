import QtQuick
import "../.."

// The whole text blinks red, green, blue.
SourceText {
  id: fx

  property real t: 0                                              // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(60, 700 / Math.max(1, fx.n)))
  readonly property real total: 430
  colorFn: function(i) { var ph = Math.floor(fx.t / 130); return ph < 3 ? ["#ff3b30", "#34c759", "#0a84ff"][ph] : fx.srcFg }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

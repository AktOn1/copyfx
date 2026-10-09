import QtQuick
import "../.."

// A yellow/red arcade blink on the original text and a +score pops up.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1200
  hlColor: "#000000"
  colorFn: function() { return Math.floor(fx.t / 120) % 2 === 0 ? "#ffe600" : "#ff4d4d" }
  Text { textFormat: Text.PlainText;
    x: fx.tg.x + fx.tg.w / 2 - width / 2; y: fx.tg.y - fx.lh * 1.1 - Math.min(1, fx.t / 700) * fx.lh
    text: "+" + fx.n * 10
    color: "#ff9f1c"; font.family: "monospace"; font.bold: true; font.pixelSize: Math.max(11, fx.lh * 0.9)
    opacity: fx.t < 900 ? 1 : Math.max(0, 1 - (fx.t - 900) / 300)
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

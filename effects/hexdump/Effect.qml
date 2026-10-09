import QtQuick
import "../.."

// The bytes of the copied text appear above the original text in hex.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1300
  readonly property string hex: Array.from(fx.text).slice(0, 14).map(function(c) { return ("0" + c.charCodeAt(0).toString(16)).slice(-2) }).join(" ")
  hlColor: "#0b1020"
  colorFn: function() { return "#9ecbff" }
  Text { textFormat: Text.PlainText;
    x: fx.tg.x; y: fx.tg.y - fx.lh * 1.15
    text: fx.hex + (fx.n > 14 ? " …" : "") + "   " + fx.n + " chars"
    color: "#6a7fa8"; font.family: "monospace"; font.pixelSize: Math.max(9, fx.lh * 0.6)
    opacity: Math.min(1, fx.t / 200) * (fx.t > 1000 ? Math.max(0, 1 - (fx.t - 1000) / 300) : 1)
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

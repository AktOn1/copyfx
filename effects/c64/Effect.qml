import QtQuick
import "../.."

// Commodore 64: blue screen, light-blue text, thick border, blinking block cursor.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: 1200 + 150
  hlColor: "#4040e0"
  colorFn: function() { return "#a0a0ff" }
  Rectangle {
    x: fx.tg.x - 14; y: fx.tg.y - 12; width: fx.tg.w + 28; height: fx.tg.h + 24
    color: "transparent"; border.color: "#a0a0ff"; border.width: 8; z: -1
    opacity: fx.hlAlpha
  }
  Rectangle {
    x: fx.tg.x + fx.tg.w + 3; y: fx.tg.y + fx.tg.h - fx.lh; width: fx.lh * 0.6; height: fx.lh
    color: "#a0a0ff"; visible: Math.floor(fx.t / 260) % 2 === 0
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

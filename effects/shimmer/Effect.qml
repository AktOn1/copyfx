import QtQuick
import "../.."

// A glint of light sweeps across the original text.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  property real sweep: -0.3
  readonly property real total: 1900
  Item {
    x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; clip: true
    Rectangle {
      width: fx.tg.h * 0.9; height: fx.tg.h * 2.4; y: -fx.tg.h * 0.7
      x: fx.sweep * (fx.tg.w + width) - width * 0.5
      rotation: 20; opacity: 0.55
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#00ffffff" }
        GradientStop { position: 0.5; color: "#ffffffff" }
        GradientStop { position: 1; color: "#00ffffff" }
      }
    }
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "sweep"; from: -0.3; to: 1.3; duration: fx.runMs; easing.type: Easing.InOutQuad }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

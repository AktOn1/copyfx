import QtQuick
import "../.."

// A border draws itself around the original text and fades.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  property real fade: 0
  readonly property real total: 1300
  Rectangle {
    x: fx.tg.x - 8; y: fx.tg.y - 6; width: fx.tg.w + 16; height: fx.tg.h + 12
    radius: 8; color: "transparent"; border.color: fx.accent; border.width: 2
    opacity: fx.fade
  }
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "fade"; to: 1; duration: 40 * fx.k }
    PauseAnimation { duration: 90 * fx.k }
    NumberAnimation { target: fx; property: "fade"; to: 0; duration: 70 * fx.k }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

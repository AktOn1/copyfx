import QtQuick
import "../.."

// Sonar rings spread out from where the text was, the text sits in the middle.
SpriteText {
  id: fx
  autoRun: false                      // this effect drives its own timeline

  Repeater {
    model: 3
    delegate: Rectangle {
      id: ring
      required property int index
      property real p: 0
      readonly property real d: 40 * fx.u + p * 460 * fx.u
      x: fx.startCX - d / 2
      y: fx.startCY - d / 2
      width: d
      height: d
      radius: d / 2
      color: "transparent"
      border.color: fx.accent
      border.width: Math.max(1, 3 * (1 - p) * fx.u)
      opacity: p > 0 ? 0.9 * (1 - p) : 0
      SequentialAnimation {
        running: true
        PauseAnimation { duration: ring.index * 25 * fx.k }
        NumberAnimation { target: ring; property: "p"; from: 0.001; to: 1; duration: 150 * fx.k; easing.type: Easing.OutCubic }
      }
    }
  }

  Item { id: pill; x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 130 * fx.k }
    NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 70 * fx.k }
  }
  Timer { interval: fx.runMs; running: true; onTriggered: fx.hlAlpha = 0 }
}

import QtQuick
import "../.."

// A border draws itself around the real text and fades.
SpriteText {
  id: fx
  autoRun: false
  property real fade: 0
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
  }
}

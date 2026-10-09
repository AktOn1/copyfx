import QtQuick
import "../.."

// Soap bubbles float up from the text and pop.
SpriteText {
  id: fx
  autoRun: false                      // this effect drives its own timeline

  function r(i, k) { var x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }

  Item { id: pill; x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h }

  Repeater {
    model: 16
    delegate: Rectangle {
      id: b
      required property int index
      property real p: 0
      readonly property real sz: (10 + fx.r(index, 1) * 22) * fx.u
      width: sz
      height: sz
      radius: sz / 2
      color: Qt.rgba(0.55, 0.85, 1, 0.12)
      border.color: Qt.rgba(0.75, 0.93, 1, 0.9)
      border.width: 1.5
      x: pill.x + fx.r(index, 2) * pill.width + Math.sin(p * 7 + index) * 12 * fx.u - sz / 2
      y: pill.y + pill.height * 0.4 - p * (90 + fx.r(index, 3) * 90) * fx.u
      opacity: p <= 0 ? 0 : (p > 0.9 ? (1 - p) * 10 : 0.95)
      scale: p > 0.9 ? 1 + (p - 0.9) * 5 : 1
      Rectangle { x: parent.width * 0.2; y: parent.height * 0.18; width: parent.width * 0.22; height: width; radius: width / 2; color: "#ccffffff" }
      SequentialAnimation {
        running: true
        PauseAnimation { duration: fx.r(index, 4) * 50 * fx.k }
        NumberAnimation { target: b; property: "p"; from: 0.001; to: 1; duration: (130 + fx.r(index, 5) * 60) * fx.k; easing.type: Easing.OutSine }
      }
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 130 * fx.k }
    NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 70 * fx.k }
  }
  Timer { interval: fx.runMs; running: true; onTriggered: fx.hlAlpha = 0 }
}

import QtQuick
import "../.."

// The text pops up and a burst of confetti shoots out of it and rains down.
SourceText {
  id: fx

  property real t: 0
  readonly property var palette: ["#ff5c8a", "#ffd166", "#06d6a0", "#4cc9f0", "#b388ff", "#ff9f1c"]
  function r(i, k) { var x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }

  Item { id: pill; x: fx.target.x; y: fx.target.y; width: fx.target.w; height: fx.target.h }

  Repeater {
    model: 44
    delegate: Rectangle {
      required property int index
      readonly property real vx: (fx.r(index, 1) - 0.5) * 1000 * fx.u
      readonly property real vy: -(220 + fx.r(index, 2) * 520) * fx.u
      width: (5 + fx.r(index, 3) * 6) * fx.u
      height: width * (0.4 + fx.r(index, 4))
      color: fx.palette[index % fx.palette.length]
      x: pill.x + pill.width / 2 + vx * fx.t
      y: pill.y + pill.height / 2 + vy * fx.t + 900 * fx.u * fx.t * fx.t
      rotation: (fx.r(index, 5) - 0.5) * 900 * fx.t
      opacity: fx.t < 1.1 ? 1 : Math.max(0, (1.5 - fx.t) / 0.4)
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    ParallelAnimation {
      NumberAnimation { target: fx; property: "t"; from: 0; to: 1.5; duration: fx.runMs }
      SequentialAnimation {
        PauseAnimation { duration: 130 * fx.k }
        NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 70 * fx.k }
      }
    }
  }
  Timer { interval: fx.runMs; running: true; onTriggered: fx.hlAlpha = 0 }
}

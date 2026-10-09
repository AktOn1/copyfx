import QtQuick
import "../.."

// Three little firework bursts go off around the text.
SpriteText {
  id: fx
  autoRun: false                      // this effect drives its own timeline

  readonly property var palette: [fx.theme.magenta, fx.theme.yellow, fx.theme.cyan, fx.theme.magenta, fx.theme.green]
  function r(i, k) { var x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }

  Item { id: pill; x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h }

  Repeater {
    model: 3
    delegate: Item {
      id: burst
      required property int index
      readonly property real bx: pill.x + pill.width * [0.15, 0.85, 0.5][index]
      readonly property real by: pill.y - (40 + 30 * (index === 2 ? 1.6 : 1)) * fx.u + (index === 2 ? 0 : 20 * fx.u)
      readonly property real lt: Math.max(0, fx.t - index * 0.28)      // local time of this burst
      Repeater {
        model: 16
        delegate: Rectangle {
          required property int index
          readonly property real ang: index / 16 * 6.2832 + fx.r(burst.index, 1)
          readonly property real dist: (70 + fx.r(index, burst.index) * 40) * fx.u * (1 - Math.pow(1 - Math.min(1, burst.lt / 0.9), 2))
          width: 5 * fx.u
          height: width
          radius: width / 2
          color: fx.palette[(index + burst.index) % fx.palette.length]
          x: burst.bx + Math.cos(ang) * dist
          y: burst.by + Math.sin(ang) * dist + 30 * fx.u * burst.lt * burst.lt
          opacity: burst.lt <= 0 ? 0 : Math.max(0, 1 - burst.lt / 1.0)
        }
      }
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    ParallelAnimation {
      NumberAnimation { target: fx; property: "t"; from: 0; to: 1.7; duration: fx.runMs }
      SequentialAnimation {
        PauseAnimation { duration: 130 * fx.k }
        NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 70 * fx.k }
      }
    }
  }
  Timer { interval: fx.runMs; running: true; onTriggered: fx.hlAlpha = 0 }
}

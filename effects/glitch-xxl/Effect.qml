import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 14 : Math.round(fx.fontSize * 1.3)
  readonly property real maxW: Math.min(fx.width * (fx.compact ? 0.85 : 0.6), 760)
  property real age: 0
  property real intensity: 1
  property real rx: 0
  property real cx2: 0
  property real jx: 0
  property var slices: [{ y: 0, h: 0, x: 0 }, { y: 0, h: 0, x: 0 }, { y: 0, h: 0, x: 0 }, { y: 0, h: 0, x: 0 }, { y: 0, h: 0, x: 0 }]

  Item {
    id: block
    x: fx.boxX(width) + fx.jx
    y: fx.boxY(height)
    width: main.width
    height: main.height

    Rectangle { anchors.fill: parent; anchors.margins: -12; color: Qt.rgba(0, 0, 0, 0.62); radius: 4 }

    FxText { textFormat: Text.PlainText; id: red; x: fx.rx; text: fx.text; color: "#ff2a55"; opacity: 0.85; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: fx.maxW; maxLines: 8 }
    FxText { textFormat: Text.PlainText; x: fx.cx2; text: fx.text; color: "#00e5ff"; opacity: 0.85; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: fx.maxW; maxLines: 8 }
    FxText { textFormat: Text.PlainText; id: main; text: fx.text; color: "#f4f4f4"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: fx.maxW; maxLines: 8 }

    Repeater {
      model: 5
      delegate: Item {
        required property int index
        readonly property var s: fx.slices[index]
        clip: true
        x: 0
        y: s.y
        width: main.width + 60
        height: s.h
        visible: s.h > 0
        FxText { textFormat: Text.PlainText;
          x: s.x
          y: -parent.y
          text: fx.text
          color: index % 2 ? "#00e5ff" : "#ff2a55"
          font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: fx.maxW; maxLines: 8
        }
      }
    }
  }

  Timer {
    interval: 55
    repeat: true
    running: true
    onTriggered: {
      fx.age += 55
      var i = fx.age < 900 ? 1 - fx.age / 900 : (Math.random() < 0.07 ? 0.55 : 0)     // settles, then the odd flicker
      fx.intensity = i
      fx.rx = (Math.random() - 0.5) * 2 * 14 * i * fx.u
      fx.cx2 = (Math.random() - 0.5) * 2 * 14 * i * fx.u
      fx.jx = i > 0.3 ? (Math.random() - 0.5) * 10 * i * fx.u : 0
      var sl = []
      for (var k = 0; k < 5; k++) {
        var on = Math.random() < i + 0.05
        sl.push({ y: Math.random() * block.height, h: on ? (3 + Math.random() * 12) * fx.u : 0, x: (Math.random() - 0.5) * 50 * i * fx.u })
      }
      fx.slices = sl
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 800 + fx.readMs }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 300 }
  }
}

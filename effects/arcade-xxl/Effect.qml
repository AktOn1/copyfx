import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 9 : Math.round(fx.fontSize * 0.8)
  readonly property var chars: Array.from(fx.text)
  property int score: 0
  property real hue: 0
  property int tick: 0
  property bool coin: true

  Rectangle {
    id: cab
    width: Math.min(fx.width * (fx.compact ? 0.94 : 0.5), 640)
    height: top.height + play.height + bottom.height + fx.fs * 3.6
    x: fx.boxX(width)
    y: fx.boxY(height)
    color: "#08082a"
    border.color: "#3a3ad8"
    border.width: 2
    radius: 6

    Row {                    // header: 1UP / HIGH SCORE
      id: top
      x: fx.fs * 1.2
      y: fx.fs * 1.1
      width: parent.width - fx.fs * 2.4
      Text { textFormat: Text.PlainText; width: parent.width / 3; text: "1UP"; color: "#ff3b3b"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs }
      Text { textFormat: Text.PlainText; width: parent.width / 3; text: "HIGH SCORE"; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs }
      Text { textFormat: Text.PlainText;
        width: parent.width / 3
        text: ("000000" + fx.score).slice(-6)
        color: "#ffe600"
        horizontalAlignment: Text.AlignRight
        font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs
      }
    }

    Flow {                   // the copied text, one rainbow letter at a time
      id: play
      x: fx.fs * 1.4
      y: top.y + top.height + fx.fs * 1.3
      width: parent.width - fx.fs * 2.8
      Repeater {
        model: fx.chars
        delegate: Text { textFormat: Text.PlainText;
          required property string modelData
          required property int index
          text: modelData
          color: Qt.hsla((index * 0.045 + fx.hue) % 1, 1, 0.62, 1)
          font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs * 1.5
        }
      }
    }

    Item {                   // footer: INSERT COIN / CREDIT
      id: bottom
      x: fx.fs * 1.2
      y: play.y + play.height + fx.fs * 1.3
      width: parent.width - fx.fs * 2.4
      height: fx.fs * 1.3
      Text { textFormat: Text.PlainText; visible: fx.coin; text: "INSERT COIN"; color: "#ffffff"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs }
      Text { textFormat: Text.PlainText; anchors.right: parent.right; text: "CREDIT 00"; color: "#00e5ff"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs }
    }

    // marquee bulbs chasing round the edge
    Repeater {
      model: Math.floor(2 * (cab.width + cab.height) / (fx.fs * 1.5))
      delegate: Rectangle {
        required property int index
        readonly property real per: 2 * (cab.width + cab.height)
        readonly property real sp: per / Math.floor(per / (fx.fs * 1.5))
        readonly property real d: index * sp
        readonly property bool lit: (index + fx.tick) % 3 === 0
        width: fx.fs * 0.4; height: width; radius: width / 2
        x: (d < cab.width ? d : d < cab.width + cab.height ? cab.width : d < 2 * cab.width + cab.height ? 2 * cab.width + cab.height - d : 0) - width / 2
        y: (d < cab.width ? 0 : d < cab.width + cab.height ? d - cab.width : d < 2 * cab.width + cab.height ? cab.height : per - d) - height / 2
        color: lit ? "#ffee55" : "#5a4a10"
      }
    }
    Scanlines { anchors.fill: parent; z: 6; strength: 0.1 }
  }

  Timer { interval: 90; repeat: true; running: true; onTriggered: { fx.tick++; fx.hue = (fx.hue + 0.02) % 1 } }
  Timer { interval: 420; repeat: true; running: true; onTriggered: fx.coin = !fx.coin }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "score"; to: Math.min(999900, fx.chars.length * 100); duration: 450; easing.type: Easing.OutCubic }
    PauseAnimation { duration: Math.max(300, fx.readMs) }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 350 }
  }
}

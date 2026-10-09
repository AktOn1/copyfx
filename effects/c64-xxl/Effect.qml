import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property string up: fx.text.toUpperCase()
  readonly property string cmd: "10 PRINT \"" + fx.up + "\""
  readonly property real fs: fx.compact ? 10 : Math.round(fx.fontSize * 0.8)
  readonly property color light: "#887ecb"     // C64 light blue: text and border
  readonly property color dark: "#40318d"      // C64 blue: screen
  property int typed: 0
  property bool cursorOn: true

  Rectangle {
    id: frame
    width: Math.min(fx.width * (fx.compact ? 0.94 : 0.6), 780)
    height: body.height + fx.fs * 2.6
    x: fx.boxX(width)
    y: fx.boxY(height)
    color: fx.light
    radius: 4

    Rectangle {
      id: screen
      anchors.fill: parent
      anchors.margins: fx.fs * 0.9
      color: fx.dark

      Column {
        id: body
        x: fx.fs * 0.4
        y: fx.fs * 0.4
        width: parent.width - fx.fs * 0.8

        FxText { textFormat: Text.PlainText; text: "READY."; color: fx.light; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width }
        FxText { textFormat: Text.PlainText;
          text: fx.cmd.slice(0, fx.typed) + (fx.typed < fx.cmd.length && fx.cursorOn ? "█" : "")
          color: fx.light; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width; maxLines: 6
        }
        FxText { textFormat: Text.PlainText; visible: fx.typed >= fx.cmd.length; text: "RUN"; color: fx.light; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width }
        FxText { textFormat: Text.PlainText; visible: fx.typed >= fx.cmd.length; text: fx.up; color: fx.light; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width; maxLines: 6 }
        FxText { textFormat: Text.PlainText; visible: fx.typed >= fx.cmd.length; text: " "; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width }
        FxText { textFormat: Text.PlainText;
          visible: fx.typed >= fx.cmd.length
          text: "READY." + (fx.cursorOn ? "█" : " ")
          color: fx.light; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: body.width
        }
      }
      Scanlines { anchors.fill: parent; z: 5; strength: 0.12 }
    }
  }

  // the command is typed fast (a few ms per key); the copied text is already in it from the first frame
  Timer { interval: 16; repeat: true; running: fx.typed < fx.cmd.length; onTriggered: fx.typed = Math.min(fx.cmd.length, fx.typed + 4) }
  Timer { interval: 380; repeat: true; running: true; onTriggered: fx.cursorOn = !fx.cursorOn }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 300 + fx.readMs }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 350 }
  }
}

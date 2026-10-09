import QtQuick
import "../.."

// The text gets a coat of glitter: little four-point stars twinkle in and out around it.
SourceText {
  id: fx

  function r(i, k) { var x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }

  Item { id: pill; x: fx.target.x; y: fx.target.y; width: fx.target.w; height: fx.target.h }

  Repeater {
    model: 26
    delegate: Text { textFormat: Text.PlainText;
      id: star
      required property int index
      text: index % 3 === 0 ? "✧" : "✦"
      color: index % 2 ? "#fff3b0" : "#ffffff"
      font.pixelSize: (10 + fx.r(index, 3) * 16) * fx.u
      x: pill.x - 14 + fx.r(index, 1) * (pill.width + 28) - width / 2
      y: pill.y - 12 + fx.r(index, 2) * (pill.height + 24) - height / 2
      scale: 0
      rotation: fx.r(index, 4) * 90
      SequentialAnimation {
        running: true
        PauseAnimation { duration: fx.r(index, 5) * 40 * fx.k }
        NumberAnimation { target: star; property: "scale"; to: 1; duration: 40 * fx.k; easing.type: Easing.OutBack }
        NumberAnimation { target: star; property: "scale"; to: 0; duration: 50 * fx.k; easing.type: Easing.InQuad }
        NumberAnimation { target: star; property: "scale"; to: 0.8; duration: 40 * fx.k; easing.type: Easing.OutBack }
        NumberAnimation { target: star; property: "scale"; to: 0; duration: 50 * fx.k; easing.type: Easing.InQuad }
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

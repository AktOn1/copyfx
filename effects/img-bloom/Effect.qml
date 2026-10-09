import QtQuick
import "../.."

// Little flowers sprout on top of the real letters, one after another, and open up.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.6 + 900
  function q(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.6) / 420)) }
  readonly property var pal: [fx.theme.magenta, fx.theme.yellow, "#ffffff", "#c4a1ff", fx.theme.orange]
  Repeater {
    model: fx.units
    delegate: Item {
      required property var modelData
      readonly property real k: fx.q(modelData.i)
      visible: modelData.i % (fx.n > 60 ? 3 : fx.n > 30 ? 2 : 1) === 0 && k > 0
      opacity: fx.hlAlpha
      Rectangle { x: modelData.cx - 1; y: modelData.y - modelData.h * 0.5 * parent.k + modelData.h * 0.5; width: 2; height: modelData.h * 0.5 * parent.k; color: "#5fbf6a" }
      Text { textFormat: Text.PlainText;
        text: modelData.i % 4 === 3 ? "❀" : "✿"
        color: fx.pal[modelData.i % 5]
        font.pixelSize: modelData.h * 0.9
        scale: parent.k * (1 + 0.25 * Math.sin(Math.PI * parent.k))
        x: modelData.cx - width / 2; y: modelData.y - modelData.h * 0.55 * parent.k - height * 0.3
      }
    }
  }
}

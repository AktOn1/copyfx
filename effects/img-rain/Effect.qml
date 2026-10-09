import QtQuick
import "../.."

// Rain streaks down over the real text, drops run down the letters and ripples spread below; heavier with real precipitation, slanted by the real wind.
SpriteText {
  id: fx
  total: 1700
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  readonly property real amt: Math.max(0.4, Math.min(1, 0.4 + fx.weather.precip / 2))
  readonly property real slant: fx.windSign * (0.06 + 0.35 * fx.windAmt)
  tintFn: function() { return fx.env > 0.1 ? 8 : 0 }
  Repeater {
    model: Math.round(28 + 60 * fx.amt)
    delegate: Rectangle {                                      // falling streaks
      required property int index
      readonly property real p: (fx.t / 520 + fx.hash(index, 1)) % 1
      width: Math.max(1.5, fx.lh * 0.08); height: fx.lh * (0.7 + fx.hash(index, 2) * 0.6); color: fx.theme.cyan
      rotation: -fx.slant * 60
      x: fx.tg.x - fx.lh + (fx.tg.w + fx.lh * 2) * fx.hash(index, 3) + p * fx.slant * fx.lh * 4
      y: fx.tg.y - fx.lh * 3 + p * (fx.tg.h + fx.lh * 5)
      opacity: 0.55 * fx.env * fx.hlAlpha
    }
  }
  Repeater {
    model: fx.units
    delegate: Rectangle {                                      // a drop running down each letter
      required property var modelData
      readonly property real p: (fx.t / 760 + fx.hash(modelData.i, 5)) % 1
      visible: modelData.i % 2 === 0
      width: Math.max(1.5, fx.lh * 0.13); height: fx.lh * 0.22; radius: width / 2; color: "#d6efff"
      x: modelData.x + modelData.w * (0.2 + 0.6 * fx.hash(modelData.i, 6)); y: modelData.y + p * modelData.h * 1.25
      opacity: (p < 0.85 ? 0.95 : (1 - p) / 0.15) * fx.env * fx.hlAlpha
    }
  }
  Repeater {
    model: 5
    delegate: Rectangle {                                      // ripples in the puddle under the text
      required property int index
      readonly property real p: (fx.t / 700 + index * 0.2) % 1
      width: p * fx.lh * 2.4; height: width * 0.28; radius: height / 2
      x: fx.tg.x + fx.tg.w * (0.12 + 0.19 * index) - width / 2; y: fx.tg.y + fx.tg.h + fx.lh * (0.5 + 0.15 * (index % 2)) - height / 2
      color: "transparent"; border.color: fx.theme.cyan; border.width: 1.5; opacity: (1 - p) * 0.8 * fx.env * fx.hlAlpha
    }
  }
}

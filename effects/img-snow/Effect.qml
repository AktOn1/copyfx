import QtQuick
import "../.."

// Soft snow drifts down and settles as little caps on top of the real letters.
SpriteText {
  id: fx
  total: 1600
  function q(i) { return Math.max(0, Math.min(1, (fx.t - 200 - fx.hash(i, 1) * 600) / 500)) }
  readonly property real melt: fx.t > fx.total * 0.8 ? Math.max(0, 1 - (fx.t - fx.total * 0.8) / (fx.total * 0.2)) : 1
  Repeater {
    model: 34
    delegate: Rectangle {
      required property int index
      readonly property real p: (fx.t / 900 + fx.hash(index, 1)) % 1
      width: Math.max(2, fx.lh * (0.1 + fx.hash(index, 2) * 0.12)); height: width; radius: width / 2; color: "#ffffff"
      x: fx.tg.x - fx.lh + (fx.tg.w + fx.lh * 2) * fx.hash(index, 3) + Math.sin(p * 9 + index) * fx.lh * 0.5
      y: fx.tg.y - fx.lh * 2.5 + p * (fx.tg.h + fx.lh * 3.4)
      opacity: 0.9 * fx.melt * fx.hlAlpha
    }
  }
  Repeater {
    model: fx.units
    delegate: Rectangle {                              // the snow cap on each letter
      required property var modelData
      x: modelData.x + modelData.w * 0.1; width: modelData.w * 0.8
      height: Math.max(0, fx.lh * 0.16 * fx.q(modelData.i)); y: modelData.y - height * 0.5 + 1
      radius: height / 2; color: "#f4fbff"; opacity: fx.melt * fx.hlAlpha
    }
  }
}

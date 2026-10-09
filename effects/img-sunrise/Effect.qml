import QtQuick
import "../.."

// A warm sun rises behind the real text and washes it in golden light.
SpriteText {
  id: fx
  total: 1500
  readonly property real rise: Math.min(1, fx.t / (fx.total * 0.7))
  readonly property real fadeOut: fx.t > fx.total * 0.75 ? Math.max(0, 1 - (fx.t - fx.total * 0.75) / (fx.total * 0.25)) : 1
  tintFn: function() { return fx.rise > 0.3 ? 16 : 0 }
  Rectangle {
    x: fx.tg.x - fx.lh; y: fx.tg.y - fx.lh * 0.5; width: fx.tg.w + fx.lh * 2; height: fx.tg.h + fx.lh
    opacity: 0.85 * fx.fadeOut * fx.hlAlpha
    gradient: Gradient {
      GradientStop { position: 0; color: "#00ffb347" }
      GradientStop { position: 1; color: Qt.rgba(1, 0.55 + 0.2 * fx.rise, 0.2, 0.55 * fx.rise) }
    }
  }
  Rectangle {                                          // the sun
    readonly property real d: fx.lh * 3.2
    x: fx.tg.x + fx.tg.w / 2 - d / 2; y: fx.tg.y + fx.tg.h + fx.lh * 0.6 - fx.rise * (fx.tg.h + fx.lh * 2.2); width: d; height: d; radius: d / 2
    color: fx.theme.yellow; opacity: 0.75 * fx.fadeOut * fx.hlAlpha
  }
  Repeater {
    model: 9
    delegate: Rectangle {                              // rays
      required property int index
      width: fx.lh * 0.14; height: fx.lh * (1.2 + fx.rise * 1.6); color: fx.theme.yellow
      x: fx.tg.x + fx.tg.w / 2 - width / 2; y: fx.tg.y + fx.tg.h + fx.lh * 0.6 - fx.rise * (fx.tg.h + fx.lh * 2.2) + fx.lh * 1.6 - height
      transformOrigin: Item.Bottom
      rotation: -80 + index * 20; opacity: 0.5 * fx.rise * fx.fadeOut * fx.hlAlpha
    }
  }
}

import QtQuick
import "../.."

// The real text ripples in the heat haze under a glaring sun, glowing orange to red with the temperature.
SpriteText {
  id: fx
  total: 1600
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  readonly property real hot: Math.max(0.3, Math.min(1, (fx.weather.temp - 18) / 22))
  dxFn: function(u) { return Math.sin(fx.t / 90 + u.line * 1.7 + u.i * 0.3) * fx.lh * 0.2 * fx.hot * fx.env }
  dyFn: function(u) { return Math.sin(fx.t / 140 + u.i * 0.7) * fx.lh * 0.12 * fx.hot * fx.env }
  tintFn: function() { return fx.env > 0.1 ? (fx.hot > 0.7 ? 1 : 2) : 0 }
  Rectangle {
    x: fx.tg.x - fx.lh; y: fx.tg.y - fx.lh * 2.2; width: fx.tg.w + fx.lh * 2; height: fx.lh * 2.4
    opacity: 0.8 * fx.env * fx.hlAlpha
    gradient: Gradient { GradientStop { position: 0; color: "#00ffe08a" } GradientStop { position: 1; color: "#88ffb347" } }
  }
  Repeater {
    model: 7
    delegate: Rectangle {                                       // rising haze
      required property int index
      readonly property real p: (fx.t / 900 + index * 0.14) % 1
      width: fx.tg.w * 0.12; height: 2; radius: 1; color: "#ffe6b0"
      x: fx.tg.x + fx.tg.w * (0.06 + 0.14 * index) + Math.sin(p * 14 + index) * fx.lh * 0.3; y: fx.tg.y - p * fx.lh * 2
      opacity: (1 - p) * 0.6 * fx.env * fx.hlAlpha
    }
  }
}

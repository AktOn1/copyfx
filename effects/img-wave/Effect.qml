import QtQuick
import "../.."

// The real letters ride a rainbow wave.
SpriteText {
  id: fx
  total: 1600
  readonly property real amp: Math.min(1, fx.t / 250) * (fx.t > 1300 ? Math.max(0, 1 - (fx.t - 1300) / 300) : 1)
  dyFn: function(u) { return Math.sin(fx.t / 130 + u.i * 0.55) * fx.lh * 0.3 * fx.amp }
  tintFn: function(u) { return fx.amp > 0.02 ? 1 + Math.floor((((fx.t / 900 + u.i * 0.03) % 1) + 1) % 1 * 12) : 0 }

}

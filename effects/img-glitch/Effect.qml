import QtQuick
import "../.."

// The real letters tear: pieces jitter and flash red and cyan for a moment.
SpriteText {
  id: fx
  total: 800
  function on(i) { return fx.t < 520 && fx.hash(i, Math.floor(fx.t / 55)) > 0.72 }
  dxFn: function(u) { return fx.on(u.i) ? (fx.hash(u.i, 3) - 0.5) * fx.lh * 1.2 : 0 }
  dyFn: function(u) { return fx.on(u.i) ? (fx.hash(u.i, 7) - 0.5) * fx.lh * 0.3 : 0 }
  tintFn: function(u) { return fx.on(u.i) ? (fx.hash(u.i, 5) > 0.5 ? 12 : 7) : 0 }

}

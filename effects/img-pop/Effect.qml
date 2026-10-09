import QtQuick
import "../.."

// The real letters pop up one after another with an elastic overshoot.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.7 + 500
  function q(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.7) / 300)) }
  scaleFn: function(u) { var k = fx.q(u.i); return 1 + 0.9 * Math.sin(Math.PI * k) * (1 - 0.4 * k) }
  dyFn: function(u) { return -fx.lh * 0.15 * Math.sin(Math.PI * fx.q(u.i)) }
  tintFn: function(u) { var k = fx.q(u.i); return k > 0 && k < 1 ? 13 : 0 }

}

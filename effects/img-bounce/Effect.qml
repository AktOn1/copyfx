import QtQuick
import "../.."

// The real letters drop and bounce like rubber balls, settling back one after another.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.5 + 900
  function q(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.5) / 700)) }
  dyFn: function(u) { var k = fx.q(u.i); return k >= 1 ? 0 : fx.lh * 1.6 * (1 - Math.abs(Math.cos(2.5 * Math.PI * k))) * (1 - k) }
  tintFn: function(u) { var k = fx.q(u.i); return k > 0 && k < 1 ? 2 : 0 }

}

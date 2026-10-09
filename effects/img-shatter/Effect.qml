import QtQuick
import "../.."

// The real letters fall away, tilting and fading, first to last (like Bleed, with the true glyphs).
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.8 + 450
  function q(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.8) / 380)) }
  dyFn: function(u) { var k = fx.q(u.i); return k * k * fx.lh * 2.2 }
  rotFn: function(u) { return (u.i % 2 ? 1 : -1) * (10 + u.i * 7 % 25) * fx.q(u.i) }
  alphaFn: function(u) { return 1 - fx.q(u.i) }
  tintFn: function(u) { return fx.q(u.i) > 0 ? 13 : 0 }

}

import QtQuick
import "../.."

// The real letters topple like dominoes, one knocking the next, and spring back up.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.7 + 600
  function q(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.7) / 320)) }
  rotFn: function(u) { return Math.sin(Math.PI * fx.q(u.i)) * 75 }
  dyFn: function(u) { return Math.sin(Math.PI * fx.q(u.i)) * fx.lh * 0.28 }
  tintFn: function(u) { var k = fx.q(u.i); return k > 0 && k < 1 ? 3 : 0 }

}

import QtQuick
import "../.."

// The real letters burst outward from the middle of the text, spinning, and fly back.
SpriteText {
  id: fx
  total: 900
  readonly property real ph: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  function dir(u) {
    var dx = u.cx - (fx.tg.x + fx.tg.w / 2), dy = (fx.hash(u.i, 1) - 0.5) * 2 * fx.lh * 2
    var d = Math.max(1, Math.sqrt(dx * dx + dy * dy))
    return { x: dx / d, y: dy / d, r: 0.6 + fx.hash(u.i, 2) * 1.2 }
  }
  dxFn: function(u) { return fx.dir(u).x * fx.dir(u).r * fx.lh * 4 * fx.ph }
  dyFn: function(u) { return fx.dir(u).y * fx.dir(u).r * fx.lh * 2.2 * fx.ph }
  rotFn: function(u) { return (fx.hash(u.i, 3) - 0.5) * 540 * fx.ph }
  alphaFn: function() { return 1 - 0.35 * fx.ph }
  tintFn: function(u) { return fx.ph > 0.05 ? 1 + Math.floor(fx.hash(u.i, 4) * 3) : 0 }

}

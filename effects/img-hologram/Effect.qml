import QtQuick
import "../.."

// The real text flickers as a cyan hologram with scanlines.
SpriteText {
  id: fx
  total: 1200
  hlColor: "#062a33"
  tintFn: function() { return 19 }
  alphaFn: function(u) { return fx.t < 600 && Math.floor(fx.t / 45 + u.i) % 5 === 0 ? 0.4 : 1 }
  Scanlines { x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; gap: 3; strength: 0.35; opacity: fx.hlAlpha }
  Rectangle { x: fx.tg.x; y: fx.tg.y + (fx.tg.h - 2) * ((fx.t % 700) / 700); width: fx.tg.w; height: 2; color: fx.theme.cyan; opacity: 0.6 * fx.hlAlpha }
}

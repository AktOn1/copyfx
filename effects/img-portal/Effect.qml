import QtQuick
import "../.."

// The real letters stream through a blue portal on the right and come out of an orange one on the left.
SpriteText {
  id: fx
  total: 1600
  readonly property real span: fx.tg.w + fx.lh * 2
  readonly property real shift: Math.min(1, fx.t / (fx.total * 0.85)) * fx.span
  readonly property real xr: fx.tg.x + fx.tg.w + fx.lh * 0.8
  readonly property real xl: fx.tg.x - fx.lh * 0.8
  function pos(u) { var p = u.cx + fx.shift; return p > fx.xr ? p - fx.span : p }
  dxFn: function(u) { return fx.pos(u) - u.cx }
  scaleFn: function(u) { var p = fx.pos(u), e = fx.lh * 1.6, a = Math.min(1, Math.max(0, (fx.xr - p) / e)), b = Math.min(1, Math.max(0, (p - fx.xl) / e)); return Math.max(0.05, Math.min(a, b)) }
  tintFn: function(u) { var p = fx.pos(u); return p < fx.xl + fx.lh * 2 ? 2 : p > fx.xr - fx.lh * 2 ? 8 : 0 }
  Rectangle { x: fx.xr - fx.lh * 0.35; y: fx.tg.y - fx.lh * 0.3; width: fx.lh * 0.7; height: fx.tg.h + fx.lh * 0.6; radius: fx.lh * 0.35; color: "#004a80"; border.color: fx.theme.blue; border.width: 3; opacity: fx.hlAlpha }
  Rectangle { x: fx.xl - fx.lh * 0.35; y: fx.tg.y - fx.lh * 0.3; width: fx.lh * 0.7; height: fx.tg.h + fx.lh * 0.6; radius: fx.lh * 0.35; color: "#6b2b00"; border.color: fx.theme.orange; border.width: 3; opacity: fx.hlAlpha }
}

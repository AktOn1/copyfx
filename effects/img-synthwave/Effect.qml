import QtQuick
import "../.."

// Pink-to-cyan gradient letters on a dusk block with neon lines drawn around them.
SpriteText {
  id: fx
  total: 1300
  hlColor: "#1a0b2e"
  readonly property real grow: Math.min(1, fx.t / 400)
  tintFn: function(u) { var q = fx.tg.w > 0 ? Math.max(0, Math.min(0.999, (u.cx - fx.tg.x) / fx.tg.w)) : 0; return [11, 10, 9, 8, 7][Math.floor(q * 5)] }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - fx.grow); y: fx.tg.y + fx.tg.h + 3; width: fx.tg.w * fx.grow; height: 2; color: fx.theme.magenta }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - fx.grow); y: fx.tg.y + fx.tg.h + 8; width: fx.tg.w * fx.grow; height: 2; color: fx.theme.cyan }
  Rectangle { x: fx.tg.x + fx.tg.w / 2 * (1 - fx.grow); y: fx.tg.y - 5; width: fx.tg.w * fx.grow; height: 2; color: fx.theme.magenta }
}

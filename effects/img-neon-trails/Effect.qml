import QtQuick
import "../.."

// Two neon bikes race around the real text and leave glowing trails.
SpriteText {
  id: fx
  total: 1500
  readonly property real p: Math.min(1, fx.t / 800)
  readonly property real fade: fx.t > 1100 ? Math.max(0, 1 - (fx.t - 1100) / 300) : 1
  Rectangle { x: fx.tg.x - 3; y: fx.tg.y - 4; width: (fx.tg.w + 6) * fx.p; height: 2; color: fx.theme.cyan; opacity: fx.fade }
  Rectangle { x: fx.tg.x - 3 + (fx.tg.w + 6) * fx.p - 3; y: fx.tg.y - 6; width: 6; height: 6; color: "#ffffff"; opacity: fx.fade * (fx.p < 1 ? 1 : 0) }
  Rectangle { x: fx.tg.x + fx.tg.w + 3 - (fx.tg.w + 6) * fx.p; y: fx.tg.y + fx.tg.h + 2; width: (fx.tg.w + 6) * fx.p; height: 2; color: fx.theme.orange; opacity: fx.fade }
  Rectangle { x: fx.tg.x + fx.tg.w + 3 - (fx.tg.w + 6) * fx.p - 3; y: fx.tg.y + fx.tg.h; width: 6; height: 6; color: "#ffffff"; opacity: fx.fade * (fx.p < 1 ? 1 : 0) }
}

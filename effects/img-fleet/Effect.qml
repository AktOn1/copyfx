import QtQuick
import "../.."

// A cannon well below the real text fires up and zaps the letters away, line by line.
SpriteText {
  id: fx
  total: 900
  readonly property real prog: Math.min(1, fx.t / (fx.total - 300)) * fx.rects.length
  readonly property int li: Math.max(0, Math.min(fx.rects.length - 1, Math.floor(fx.prog)))
  readonly property var cur: fx.hasSprite ? fx.rects[fx.li] : { x: fx.tg.x, y: fx.tg.y, w: fx.tg.w, h: fx.tg.h }
  readonly property real cx: fx.cur.x + Math.min(1, fx.prog - fx.li) * fx.cur.w
  readonly property real gap: fx.lh * 1.6                      // clear air between the line and the cannon
  readonly property real cy: fx.tg.y + fx.tg.h + fx.gap         // top of the cannon: under the whole block
  readonly property bool live: fx.t < fx.total - 300
  alphaFn: function(u) { return u.line < fx.li || (u.line === fx.li && u.cx < fx.cx - 3) ? 0 : 1 }
  tintFn: function(u) { return u.line === fx.li && Math.abs(u.cx - fx.cx) < fx.lh * 0.7 ? 1 : 0 }
  Rectangle {                                                    // the shot: a short bright streak travelling from the cannon up to the line
    readonly property real ph: (fx.t % 90) / 90
    visible: fx.live
    x: fx.cx - 1.5; width: 3; height: fx.lh * 0.7
    y: fx.cy - height - ph * (fx.cy - fx.cur.y - fx.cur.h * 0.5 - height)
    color: fx.theme.green
  }
  Item {                                                         // the cannon: a base, a hull and the barrel
    visible: fx.live
    x: fx.cx - fx.lh * 0.7; y: fx.cy; width: fx.lh * 1.4; height: fx.lh * 0.7
    Rectangle { x: 0; y: fx.lh * 0.25; width: parent.width; height: fx.lh * 0.45; color: fx.theme.green }
    Rectangle { x: fx.lh * 0.2; y: fx.lh * 0.1; width: fx.lh * 1.0; height: fx.lh * 0.2; color: fx.theme.green }
    Rectangle { x: fx.lh * 0.62; y: -fx.lh * 0.1; width: fx.lh * 0.16; height: fx.lh * 0.3; color: fx.theme.green }
  }
}

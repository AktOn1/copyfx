import QtQuick
import "../.."

// A glowing blade sweeps through the real text; letters flinch and spark where it cuts.
SpriteText {
  id: fx
  total: 1200
  readonly property real bx: fx.tg.x - fx.lh + Math.min(1, fx.t / (fx.total * 0.75)) * (fx.tg.w + fx.lh * 2)
  function age(u) { return Math.max(0, Math.min(1, (fx.bx - u.cx) / (fx.lh * 3))) }
  readonly property bool cutting: fx.t < fx.total * 0.75
  dyFn: function(u) { var a = fx.age(u); return a > 0 && a < 1 ? (u.i % 2 ? 1 : -1) * fx.lh * 0.35 * (1 - a) : 0 }
  rotFn: function(u) { var a = fx.age(u); return a > 0 && a < 1 ? (u.i % 2 ? 1 : -1) * 9 * (1 - a) : 0 }
  tintFn: function(u) { var a = fx.age(u); return a > 0 && a < 0.45 ? 7 : 0 }
  Rectangle { x: fx.bx - fx.lh * 0.55; y: fx.tg.y - fx.lh * 1.4; width: fx.lh * 1.1; height: fx.tg.h + fx.lh * 2.8; radius: fx.lh * 0.5; color: "#5533c8ff"; visible: fx.cutting; opacity: fx.hlAlpha }
  Rectangle { x: fx.bx - 2; y: fx.tg.y - fx.lh * 1.4; width: 4; height: fx.tg.h + fx.lh * 2.8; radius: 2; color: "#e8fbff"; visible: fx.cutting; opacity: fx.hlAlpha }
  Repeater {
    model: 14
    delegate: Rectangle {
      required property int index
      readonly property real life: (fx.t / 260 + fx.hash(index, 1)) % 1
      width: Math.max(2, fx.lh * 0.12); height: width; radius: width / 2; color: index % 2 ? fx.theme.cyan : "#ffffff"
      x: fx.bx + (fx.hash(index, 2) - 0.3) * fx.lh * 2.4 * life
      y: fx.tg.y + fx.tg.h / 2 + (fx.hash(index, 3) - 0.5) * fx.tg.h * 1.6 * life + life * life * fx.lh
      visible: fx.cutting; opacity: (1 - life) * fx.hlAlpha
    }
  }
}

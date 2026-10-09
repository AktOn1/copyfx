import QtQuick
import "../.."

// The copied text is keyed out in Morse code by a lamp while the matching real letters glow.
SpriteText {
  id: fx
  readonly property var morseMap: ({ a: ".-", b: "-...", c: "-.-.", d: "-..", e: ".", f: "..-.", g: "--.", h: "....", i: "..", j: ".---", k: "-.-", l: ".-..", m: "--", n: "-.", o: "---", p: ".--.", q: "--.-", r: ".-.", s: "...", t: "-", u: "..-", v: "...-", w: ".--", x: "-..-", y: "-.--", z: "--..", "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----." })
  readonly property string src: fx.text.toLowerCase().slice(0, 14)
  readonly property var seq: {                      // [ {on:bool, len, ch} ] in dot units
    var out = []
    for (var c = 0; c < fx.src.length; c++) {
      var ch = fx.src.charAt(c), m = fx.morseMap[ch]
      if (ch === " ") { out.push({ on: false, len: 4, ch: c }); continue }
      if (!m) continue
      for (var k = 0; k < m.length; k++) { out.push({ on: true, len: m.charAt(k) === "-" ? 3 : 1, ch: c }); out.push({ on: false, len: 1, ch: c }) }
      out.push({ on: false, len: 2, ch: c })
    }
    return out
  }
  readonly property real units_total: fx.seq.reduce(function(a, s) { return a + s.len }, 0)
  total: 1500
  readonly property real pos: Math.min(fx.units_total, fx.t / (fx.total * 0.9) * fx.units_total)
  readonly property var cur: {
    var acc = 0
    for (var i = 0; i < fx.seq.length; i++) { if (fx.pos < acc + fx.seq[i].len) return fx.seq[i]; acc += fx.seq[i].len }
    return { on: false, len: 1, ch: fx.src.length - 1 }
  }
  hlColor: "#0a0d10"
  tintFn: function(u) { return fx.cur.on && u.i === Math.min(fx.n - 1, Math.floor(fx.cur.ch / Math.max(1, fx.src.length) * fx.n)) ? 16 : 21 }
  Rectangle {                                           // the lamp
    readonly property real d: fx.lh * 1.1
    x: fx.tg.x - fx.lh * 1.6; y: fx.tg.y + fx.tg.h / 2 - d / 2; width: d; height: d; radius: d / 2
    color: fx.cur.on ? fx.theme.yellow : "#3a3320"; border.color: "#6b5d33"; border.width: 1; opacity: fx.hlAlpha
  }
  Text { textFormat: Text.PlainText;
    x: fx.tg.x; y: fx.tg.y - fx.lh * 1.4; color: fx.theme.blue; font.family: "monospace"; font.pixelSize: fx.lh * 0.8; opacity: fx.hlAlpha
    text: { var s = "", acc = 0; for (var i = 0; i < fx.seq.length; i++) { if (acc >= fx.pos) break; if (fx.seq[i].on) s += fx.seq[i].len === 3 ? "—" : "·"; else if (fx.seq[i].len >= 2) s += " "; acc += fx.seq[i].len } return s }
  }
}

import QtQuick
import "../.."

// The film's digital rain, falling out of the real text: every copied letter (cut from the screen) is the bright head of its own
// column and drops away at a constant speed, leaving a long trail of mirrored half-width katakana, digits and symbols that
// flicker and fade from pale green to black. A second, dimmer column follows some of them. The animation-length box only says how
// long it runs; the fall distance is always the same (6 cells, +-20% per column like the film), so a longer box = slower and calmer.
SpriteText {
  id: fx
  autoRun: false

  readonly property string kana: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"
  readonly property string other: "0123456789:.=*+-<>¦|"
  readonly property real fallCells: 6                             // how far the main columns fall over the whole run (5..7 cells with the per-column variation)
  readonly property real fade: fx.t > fx.runMs * 0.7 ? Math.max(0, 1 - (fx.t - fx.runMs * 0.7) / (fx.runMs * 0.3)) : 1
  property int tick: 0
  property var cols: []                                           // per unit: main column + optional second column

  function fall(h, f) { return fx.t / fx.runMs * fx.fallCells * h * f }
  function rnd() { return Math.random() }
  function glyph() {
    return fx.rnd() < 0.78 ? { c: fx.kana.charAt(Math.floor(fx.rnd() * fx.kana.length)), m: true }
                           : { c: fx.other.charAt(Math.floor(fx.rnd() * fx.other.length)), m: false }
  }
  function column(f, len, delay) {
    var cells = []
    for (var k = 0; k <= len; k++) cells.push(fx.glyph())
    return { f: f, len: len, delay: delay, cells: cells }
  }
  function build() {
    var out = []
    for (var i = 0; i < fx.units.length; i++) {
      var main = fx.column(0.8 + 0.4 * fx.hash(i, 1), 3 + Math.floor(fx.hash(i, 2) * 7), 0)          // 3..9 cells long
      var second = fx.units.length <= 48 && fx.hash(i, 3) > 0.35
        ? fx.column(0.65 + 0.35 * fx.hash(i, 4), 3 + Math.floor(fx.hash(i, 5) * 5), 2 + fx.hash(i, 6) * 3) : null   // dimmer, starts a few cells later
      out.push({ main: main, second: second })
    }
    fx.cols = out
  }
  onUnitsChanged: build()

  // the letter itself is the head: pale, almost white
  dyFn: function(u) { var c = fx.cols[u.i]; return c ? fx.fall(u.h, c.main.f) : 0 }
  tintFn: function() { return 14 }
  alphaFn: function() { return fx.fade }

  Canvas {
    id: rain
    anchors.fill: parent
    renderTarget: Canvas.Image
    opacity: fx.fade
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      for (var i = 0; i < fx.units.length && i < fx.cols.length; i++) {
        var u = fx.units[i], h = u.h
        ctx.font = Math.round(h * 0.78) + "px monospace"
        var cs = fx.cols[i]
        var list = cs.second ? [cs.main, cs.second] : [cs.main]
        for (var q = 0; q < list.length; q++) {
          var col = list[q], d = fx.fall(h, col.f) - col.delay * h
          if (d <= 0) continue
          var dim = q === 0 ? 1 : 0.55
          for (var k = q === 0 ? 1 : 0; k <= col.len; k++) {
            var top = u.y + d - k * h                             // cell k behind the head; nothing above the source row
            if (top < u.y - 0.5 || top > height) continue
            var g = col.cells[k]
            var a, r, gr, b
            if (q === 1 && k === 0) { r = 200; gr = 255; b = 200; a = 0.85 * dim }         // the second column's own bright head
            else {
              var s = k / col.len
              a = Math.pow(1 - s, 1.5) * dim
              if (k === 1 && q === 0) { r = 150; gr = 255; b = 150 }                       // just behind the head: still pale
              else { r = 0; gr = Math.round(255 - 110 * s); b = Math.round(65 - 40 * s) }
            }
            ctx.fillStyle = "rgba(" + r + "," + gr + "," + b + "," + a + ")"
            if (g.m) {                                            // the film's katakana are mirrored
              ctx.save(); ctx.translate(u.cx, top + h / 2); ctx.scale(-1, 1); ctx.fillText(g.c, 0, 0); ctx.restore()
            } else ctx.fillText(g.c, u.cx, top + h / 2)
          }
        }
      }
    }
  }

  Timer {
    interval: 16
    repeat: true
    running: true
    onTriggered: {
      var reroll = fx.tick % 5 === 0                 // glyphs change ~12x/s, not every frame (that looked like noise)
      for (var i = 0; reroll && i < fx.cols.length; i++) {
        var cs = fx.cols[i]
        var list = cs.second ? [cs.main, cs.second] : [cs.main]
        for (var q = 0; q < list.length; q++) {
          var cells = list[q].cells
          for (var k = 0; k < cells.length; k++)
            if (fx.rnd() < (k < 3 ? 0.4 : 0.15)) cells[k] = fx.glyph()      // glyphs keep changing, the ones near the head faster
        }
      }
      fx.tick++
      rain.requestPaint()
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.runMs; duration: fx.runMs }   // t is plain elapsed ms here
  }
}

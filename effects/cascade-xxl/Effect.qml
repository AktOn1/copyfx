import QtQuick
import "../.."

// Code rain straight from the ORIGINAL text (no panel behind it): every letter leads its own stream that falls down the
// screen from where it sits, trailed by film-style katakana and digits.
SourceText {
  id: fx

  readonly property real gs: 1.5          // glyph scale relative to the original letters (1 = exactly their size)
  readonly property int trail: fx.compact ? 8 : 14

  // Film-style glyphs (half-width katakana, digits, a few symbols) fill the trails; the copied letter leads each stream.
  readonly property string film: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789:.=*+<>"
  function glyph(letter) { return Math.random() < 0.12 ? letter : fx.film.charAt(Math.floor(Math.random() * fx.film.length)) }
  function cellsFor(letter) { var c = []; for (var k = 0; k < fx.trail; k++) c.push(fx.glyph(letter)); return c }

  property var streams: []      // one per letter: { ch, x, y, d, speed }
  property real fade: 1
  property bool raining: true


  // After the layout settled, read where each letter ended up and start a stream under it.
  function collect() {
    var out = []
    for (var i = 0; i < fx.glyphItems.length; i++) {
      var g = fx.glyphItems[i], p = g.mapToItem(fx, 0, 0)
      out.push({ ch: g.text, cells: fx.cellsFor(g.text), x: p.x + g.width / 2, y: p.y + g.height, px: g.font.pixelSize * fx.gs, lh: g.height * fx.gs,
                 d: -(i * (fx.compact ? 5 : 9)) - Math.random() * 120,
                 speed: (fx.compact ? 4.4 : 8) + Math.random() * (fx.compact ? 4 : 10) })
    }
    fx.streams = out
  }
  Timer { id: collectTimer; interval: 20; running: true; onTriggered: fx.collect() }
  // the layout is not final at 20ms (the block moves when it grows): re-read the letter positions once it settled
  function refresh() {
    for (var i = 0; i < fx.streams.length && i < fx.glyphItems.length; i++) {
      var g = fx.glyphItems[i], p = g.mapToItem(fx, 0, 0)
      fx.streams[i].x = p.x + g.width / 2
      fx.streams[i].y = p.y + g.height
    }
  }
  Timer { interval: 120; running: true; onTriggered: fx.refresh() }

  Canvas {
    id: rain
    anchors.fill: parent
    opacity: fx.fade
    renderTarget: Canvas.Image

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      for (var i = 0; i < fx.streams.length; i++) {
        var s = fx.streams[i], lh = s.lh
        ctx.font = "bold " + s.px + "px monospace"
        for (var k = 0; k < fx.trail; k++) {
          var top = s.y + s.d - k * lh                                   // cells are exactly one letter line tall
          var yy = top + lh / 2
          if (top < s.y - 0.5 || top > height) continue   // only below its source letter, on screen
          var a = k === 0 ? 1 : Math.max(0, 1 - k / fx.trail)
          ctx.fillStyle = k === 0 ? "rgba(220,255,225," + a + ")" : "rgba(0,255,65," + (a * 0.9) + ")"
          ctx.fillText(k === 0 ? s.ch : s.cells[k], s.x, yy)
        }
      }
    }
  }

  Timer {
    interval: 33
    repeat: true
    running: true
    onTriggered: {
      for (var i = 0; i < fx.streams.length; i++) {
        var s = fx.streams[i]
        s.d += s.speed
        if (Math.random() < 0.5) s.cells[1 + Math.floor(Math.random() * (fx.trail - 1))] = fx.glyph(s.ch)   // flicker
        if (fx.raining && s.y + s.d - fx.trail * s.lh > fx.height) {
          s.d = -Math.random() * 60; s.cells = fx.cellsFor(s.ch)
          s.speed = (fx.compact ? 4.4 : 8) + Math.random() * (fx.compact ? 4 : 10)
        }
      }
      rain.requestPaint()
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: Math.max(1800, Math.min(4000, fx.readMs + 800)) }
    ScriptAction { script: fx.raining = false }
    PauseAnimation { duration: fx.compact ? 500 : 1200 }   // let the last streams fall out
    NumberAnimation { target: fx; property: "fade"; to: 0; duration: 500 }
  }
}

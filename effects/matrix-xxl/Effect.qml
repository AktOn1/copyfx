import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real cell: fx.compact ? 9 : 16
  // The film's set: half-width katakana (drawn mirrored most of the time, as on screen in the film), digits, and a
  // few symbols and Latin letters.
  readonly property string katakana: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"
  readonly property string others: "0123456789012345678Z:.\"=*+-<>¦|"
  readonly property int trail: fx.compact ? 10 : 18
  property var drops: []
  property real fade: 1        // overall opacity (visible from the first frame)
  property real decode: 1      // 0..1 how much of the text has resolved (the text is shown at once)
  property real spread: 0      // px the rain fans out beyond the text's edges
  property bool raining: true
  property string shown: ""

  function rnd(n) { return Math.floor(Math.random() * n) }
  function pick() {
    var kana = Math.random() < 0.72
    var s = kana ? fx.katakana : fx.others
    return { c: s.charAt(rnd(s.length)), m: kana ? Math.random() < 0.85 : Math.random() < 0.15 }
  }
  function glyph() { return fx.pick().c }
  function startRow() { return Math.ceil((band.y + band.height) / fx.cell) }
  function newSpeed() { return 0.9 + Math.random() * 1.6 }

  function resetDrops() {
    var cols = Math.ceil(fx.width / fx.cell) + 1, d = [], r0 = startRow()
    for (var i = 0; i < cols; i++) d.push({ y: r0 - rnd(24), speed: newSpeed(), cells: {} })
    fx.drops = d
  }

  onWidthChanged: if (fx.width > 0) resetDrops()

  // The text pill sits above the mouse; the rain starts at its lower edge.
  Rectangle {
    id: band
    x: fx.boxX(width)
    y: fx.boxY(height)
    width: label.width + 36
    height: label.height + 20
    radius: 8
    color: Qt.rgba(0, 0.04, 0.01, 0.92)
    border.color: "#00ff41"
    border.width: 1
    opacity: fx.fade
    z: 2

    FxText { textFormat: Text.PlainText;
      id: label
      anchors.centerIn: parent
      text: fx.shown
      color: "#7dff9a"
      font.family: "monospace"
      font.pixelSize: fx.fontSize
      maxWidth: fx.width * 0.6
      maxLines: fx.compact ? 2 : 10
    }
  }

  Canvas {
    id: rain
    anchors.fill: parent
    opacity: fx.fade
    renderTarget: Canvas.Image

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.font = fx.cell + "px monospace"
      var rows = Math.ceil(height / fx.cell), r0 = fx.startRow()
      var c0 = Math.max(0, Math.floor((band.x - fx.spread) / fx.cell))
      var c1 = Math.min(fx.drops.length - 1, Math.ceil((band.x + band.width + fx.spread) / fx.cell))
      for (var i = c0; i <= c1; i++) {
        var d = fx.drops[i]
        for (var t = 0; t < fx.trail; t++) {
          var r = Math.floor(d.y) - t
          if (r < r0 || r > rows) continue
          var g = d.cells[r]
          if (!g) { g = fx.pick(); d.cells[r] = g }
          var a = t === 0 ? 1 : Math.max(0, 1 - t / fx.trail)
          ctx.fillStyle = t === 0 ? "rgba(225,255,230," + a + ")" : "rgba(0,255,65," + (a * 0.9) + ")"
          if (g.m) {
            ctx.save()
            ctx.translate(i * fx.cell + fx.cell * 0.85, r * fx.cell)
            ctx.scale(-1, 1)
            ctx.fillText(g.c, 0, 0)
            ctx.restore()
          } else {
            ctx.fillText(g.c, i * fx.cell, r * fx.cell)
          }
        }
      }
    }
  }

  Timer {
    interval: 25
    repeat: true
    running: true
    onTriggered: {
      var rows = Math.ceil(fx.height / fx.cell), r0 = fx.startRow()
      for (var i = 0; i < fx.drops.length; i++) {
        var d = fx.drops[i]
        d.y += d.speed
        // Glyphs flicker into new ones as the stream passes, like in the film.
        if (Math.random() < 0.35) d.cells[Math.floor(d.y) - fx.rnd(fx.trail)] = fx.pick()
        if (d.y - fx.trail > rows && fx.raining) { d.y = r0 - fx.rnd(8); d.speed = fx.newSpeed(); d.cells = {} }
      }
      // Decode: letters resolve left to right, the rest still scrambled.
      var chars = Array.from(fx.text), out = ""
      var resolved = Math.floor(chars.length * fx.decode)
      for (var c = 0; c < chars.length; c++)
        out += (c < resolved || chars[c] === " ") ? chars[c] : fx.glyph()
      fx.shown = out
      rain.requestPaint()
    }
  }

  Component.onCompleted: resetDrops()

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "spread"; to: fx.compact ? 60 : 200; duration: 900; easing.type: Easing.OutQuad }
    PauseAnimation { duration: Math.max(300, Math.min(1400, fx.readMs * 0.5)) }
    ScriptAction { script: fx.raining = false }
    NumberAnimation { target: fx; property: "fade"; to: 0; duration: 400 }
  }
}

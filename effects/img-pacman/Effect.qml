import QtQuick
import "../.."

// Pac-Man runs along the real text and eats it, line by line.
SpriteText {
  id: fx
  total: 1000
  readonly property real prog: Math.min(1, fx.t / fx.total) * fx.rects.length
  readonly property int li: Math.max(0, Math.min(fx.rects.length - 1, Math.floor(fx.prog)))
  readonly property var cur: fx.hasSprite ? fx.rects[fx.li] : { x: fx.tg.x, y: fx.tg.y, w: fx.tg.w, h: fx.tg.h }
  readonly property real pacX: fx.cur.x + Math.min(1, fx.prog - fx.li) * fx.cur.w
  readonly property real pacR: Math.max(6, fx.cur.h * 0.5)
  property real mouth: 0.7
  readonly property real ghostX: fx.pacX + fx.pacR * 7             // the frightened ghost runs a few cells ahead of Pac-Man
  readonly property bool ghostOn: fx.hasSprite && fx.ghostX < fx.cur.x + fx.cur.w + fx.pacR * 2
  alphaFn: function(u) { return u.line < fx.li || (u.line === fx.li && u.cx < fx.pacX) ? 0 : 1 }
  Canvas {
    visible: fx.hasSprite
    width: fx.pacR * 2; height: fx.pacR * 2
    x: fx.pacX - fx.pacR
    y: fx.cur.y + fx.cur.h / 2 - fx.pacR
    property real m: fx.mouth
    onMChanged: requestPaint()
    onPaint: { var c = getContext("2d"); c.clearRect(0, 0, width, height); c.fillStyle = "#ffe600"; c.beginPath(); c.moveTo(width / 2, height / 2); c.arc(width / 2, height / 2, width / 2 - 1, m, Math.PI * 2 - m); c.closePath(); c.fill() }
  }
  Canvas {                                                       // the blue frightened ghost, running away (flashes white near the end of the line)
    visible: fx.ghostOn
    width: fx.pacR * 2; height: fx.pacR * 2
    x: fx.ghostX - fx.pacR
    y: fx.cur.y + fx.cur.h / 2 - fx.pacR
    property bool flash: (fx.ghostX > fx.cur.x + fx.cur.w * 0.75) && Math.floor(fx.t / 60) % 2 === 0
    property real wob: fx.mouth
    onFlashChanged: requestPaint()
    onWobChanged: requestPaint()
    onPaint: {
      var c = getContext("2d"), w = width, h = height
      c.clearRect(0, 0, w, h)
      c.fillStyle = flash ? "#ffffff" : "#2121de"
      c.beginPath()
      c.arc(w / 2, h * 0.5, w * 0.46, Math.PI, 0)
      c.lineTo(w * 0.96, h * 0.95)
      var feet = 4
      for (var i = feet; i >= 0; i--) c.lineTo(w * 0.04 + (w * 0.92) * i / feet, h * (i % 2 ? 0.95 : 0.8 + (wob > 0.4 ? 0.1 : 0)))
      c.closePath(); c.fill()
      c.fillStyle = flash ? "#2121de" : "#ffcfcf"
      c.fillRect(w * 0.28, h * 0.32, w * 0.14, h * 0.16); c.fillRect(w * 0.58, h * 0.32, w * 0.14, h * 0.16)
      c.strokeStyle = c.fillStyle; c.lineWidth = Math.max(1, h * 0.06); c.beginPath()
      c.moveTo(w * 0.22, h * 0.72); for (var k = 1; k <= 5; k++) c.lineTo(w * (0.22 + 0.11 * k), h * (k % 2 ? 0.62 : 0.72))
      c.stroke()
    }
  }
  SequentialAnimation { running: true; loops: Animation.Infinite
    NumberAnimation { target: fx; property: "mouth"; to: 0.06; duration: 40 }
    NumberAnimation { target: fx; property: "mouth"; to: 0.75; duration: 40 } }
}

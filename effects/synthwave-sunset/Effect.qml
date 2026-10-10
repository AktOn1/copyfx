import QtQuick
import "../.."

EffectBase {
  id: fx

  property real tick: 0
  property real fade: 1
  readonly property real pw: fx.compact ? fx.width * 0.94 : Math.min(fx.width * 0.6, 780)
  readonly property real ph: fx.pw * 0.5

  Item {
    id: panel
    width: fx.pw
    height: fx.ph
    x: fx.boxX(width)
    y: fx.boxY(height)
    opacity: fx.fade
    clip: true

    Canvas {
      id: cv
      anchors.fill: parent
      renderTarget: Canvas.Image
      onPaint: {
        var ctx = getContext("2d"), w = width, h = height, i
        ctx.clearRect(0, 0, w, h)
        var hz = h * 0.56
        var sky = ctx.createLinearGradient(0, 0, 0, hz)
        sky.addColorStop(0, "#0b0033"); sky.addColorStop(0.55, "#3a0a6e"); sky.addColorStop(1, "#ff2a9d")
        ctx.fillStyle = sky; ctx.fillRect(0, 0, w, hz)
        ctx.fillStyle = "rgba(255,255,255,0.8)"
        for (i = 0; i < 28; i++) ctx.fillRect(((i * 97) % 100) / 100 * w, ((i * 53) % 100) / 100 * hz * 0.6, 1.5, 1.5)

        // the sun, with stripes cut out of its lower half
        var sr = h * 0.3, scx = w / 2, scy = hz - sr * 0.35
        var sg = ctx.createLinearGradient(0, scy - sr, 0, scy + sr)
        sg.addColorStop(0, "#fff275"); sg.addColorStop(0.55, "#ff8a3d"); sg.addColorStop(1, "#ff2a6d")
        ctx.save()
        ctx.beginPath(); ctx.arc(scx, scy, sr, 0, Math.PI * 2); ctx.clip()
        ctx.fillStyle = sg; ctx.fillRect(scx - sr, scy - sr, sr * 2, sr * 2)
        ctx.fillStyle = sky
        for (i = 0; i < 6; i++) ctx.fillRect(scx - sr, scy + sr * 0.05 + i * sr * 0.16, sr * 2, 2 + i * 1.6)
        ctx.restore()

        var gg = ctx.createLinearGradient(0, hz, 0, h)
        gg.addColorStop(0, "#2a0a4a"); gg.addColorStop(1, "#0a0016")
        ctx.fillStyle = gg; ctx.fillRect(0, hz, w, h - hz)

        ctx.shadowColor = "#ff2bd6"; ctx.shadowBlur = 10
        ctx.strokeStyle = "#ff5edb"; ctx.lineWidth = 2
        ctx.beginPath(); ctx.moveTo(0, hz); ctx.lineTo(w, hz); ctx.stroke()
        ctx.lineWidth = 1.2; ctx.strokeStyle = "rgba(255,60,220,0.85)"; ctx.shadowBlur = 4
        for (i = -14; i <= 14; i++) { ctx.beginPath(); ctx.moveTo(w / 2 + i * w * 0.02, hz); ctx.lineTo(w / 2 + i * w * 0.16, h); ctx.stroke() }
        for (i = 0; i < 9; i++) {
          var f = (i + (fx.tick * 1.4) % 1) / 9, yy = hz + (h - hz) * f * f
          ctx.beginPath(); ctx.moveTo(0, yy); ctx.lineTo(w, yy); ctx.stroke()
        }

        // chrome text, wrapped to at most three lines
        var size = Math.min(w * 0.13, fx.fontSize * (fx.compact ? 1.1 : 2)), lines = [], tries = 0, over = false
        do {
          ctx.font = "italic bold " + size + "px sans-serif"
          lines = []
          var words = fx.text.split(" "), cur = ""
          for (var k = 0; k < words.length; k++) {
            var t = cur ? cur + " " + words[k] : words[k]
            if (ctx.measureText(t).width > w * 0.86 && cur) { lines.push(cur); cur = words[k] } else cur = t
          }
          if (cur) lines.push(cur)
          over = lines.length > 3 || lines.length * size * 1.12 > hz * 0.86     // must fit in the sky above the horizon
          if (over) size *= 0.88
          tries++
        } while (over && tries < 14)
        var lh = size * 1.12, top = hz * 0.48 - (lines.length * lh) / 2
        ctx.textAlign = "center"
        for (i = 0; i < lines.length; i++) {
          var by = top + (i + 1) * lh
          ctx.shadowColor = "#ff2bd6"; ctx.shadowBlur = 18; ctx.strokeStyle = "#ff2bd6"; ctx.lineWidth = 3
          ctx.strokeText(lines[i], w / 2, by)
          ctx.shadowBlur = 0
          var tg = ctx.createLinearGradient(0, by - size * 0.85, 0, by + size * 0.15)
          tg.addColorStop(0, "#ffffff"); tg.addColorStop(0.45, "#b9c4ff"); tg.addColorStop(0.5, "#3a2a8f"); tg.addColorStop(0.56, "#ff7ad9"); tg.addColorStop(1, "#ffe6fb")
          ctx.fillStyle = tg
          ctx.fillText(lines[i], w / 2, by)
        }
        ctx.shadowBlur = 0
      }
    }
    Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#ff2bd6"; border.width: 2; radius: 6 }
  }

  Timer { interval: 33; repeat: true; running: true; onTriggered: { fx.tick += 0.033; cv.requestPaint() } }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 500 + fx.readMs }
    NumberAnimation { target: fx; property: "fade"; to: 0; duration: 400 }
  }
}

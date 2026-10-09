import QtQuick
import "../.."

// STILL TEST TWIN of Bleed: identical detection and layout, but it holds for 8s and never animates, so a screenshot at any moment
// shows exactly where the overlay is. Draws the copied text on top of the selection it came from: the selection's highlight block is repainted in its own
// colour (so it looks untouched), the text is laid out inside it, then the letters detach and bleed away.
// The screen position comes from find-selection; if no highlight is found it falls back to a one-line box at the mouse.
EffectBase {
  id: fx

  readonly property bool hasSel: !!(fx.selFound && fx.selRects && fx.selRects.length > 0)
  readonly property real fbH: fx.compact ? 16 : 26
  readonly property var rects: fx.hasSel ? fx.selRects
    : [{ x: Math.max(6, fx.origin.x - 20), y: fx.origin.y - fx.fbH / 2, w: Math.min(fx.width * 0.5, 420), h: fx.fbH }]
  readonly property var box: {
    var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
    fx.rects.forEach(function(r) { x0 = Math.min(x0, r.x); y0 = Math.min(y0, r.y); x1 = Math.max(x1, r.x + r.w); y1 = Math.max(y1, r.y + r.h) })
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
  }
  readonly property real lineH: fx.rects[0].h
  // The app's real font cannot be read, so try the likely families (the theme font, sans, serif, monospace) and keep the
  // one whose letter HEIGHT best matches the ink measured on screen, once the text is scaled to the measured WIDTH.
  FontMetrics { id: fmT; font.family: fx.fontFamily; font.pixelSize: 20 }
  FontMetrics { id: fmS; font.family: "sans-serif"; font.pixelSize: 20 }
  FontMetrics { id: fmR; font.family: "serif"; font.pixelSize: 20 }
  FontMetrics { id: fmM; font.family: "monospace"; font.pixelSize: 20 }
  readonly property var fmList: fx.srcMono ? [fmM] : [fmT, fmS, fmR, fmM]
  readonly property var famList: fx.srcMono ? ["monospace"] : [fx.fontFamily, "sans-serif", "serif", "monospace"]

  // Measured on screen by find-selection: where the letters sit inside each line's box (left/right/top/bottom insets).
  readonly property var inkW: fx.rects.map(function(r) { return Math.max(4, r.w - (r.il || 0) - (r.ir || 0)) })
  readonly property real sumInk: fx.inkW.reduce(function(a, b) { return a + b }, 0)
  readonly property real measH: Math.max(1, Math.max.apply(null, fx.rects.map(function(r) { return r.h - (r.it || 0) - (r.ib || 0) })))

  // Word gaps measured on screen (find-selection reports every blank run >= 2px between the letters of a line). With W words
  // on L lines there must be exactly W - L word gaps, so take the W - L widest gaps overall (double spaces are just wider
  // ones) - provided they stand clearly apart from the letter gaps. If they do, every word is placed in its own measured
  // slot, whatever the font: exact word positions and line breaks. `null` = not trustworthy, use the width-based layout.
  readonly property var wordTokens: fx.text.split(" ").filter(function(w) { return w.length > 0 })
  readonly property var wordGaps: {
    if (!fx.hasSel) return null
    var K = fx.wordTokens.length - fx.rects.length, all = []
    fx.rects.forEach(function(r, li) { (r.gaps || []).forEach(function(g) { all.push({ li: li, s: g[0], e: g[1], w: g[1] - g[0] }) }) })
    all.sort(function(a, b) { return b.w - a.w })
    if (K < 0 || all.length < K) return null
    if (K > 0 && all[K - 1].w < 2) return null
    if (K > 0 && K < all.length && all[K - 1].w < 1.3 * all[K].w) return null        // no clear gap between word gaps and letter gaps
    var per = fx.rects.map(function() { return [] })
    for (var i = 0; i < K; i++) per[all[i].li].push([all[i].s, all[i].e])
    per.forEach(function(a) { a.sort(function(x, y) { return x[0] - y[0] }) })
    return per
  }
  readonly property bool exactWords: fx.wordGaps !== null

  // The last line was cut with an ellipsis: the text does not fit the selection, so exact word slots make no sense.
  function cutLast(out, n) { return out.length > 0 && out[out.length - 1].text.slice(-1) === "…" }
  // Choose one measured gap for each expected word boundary `e` (both sorted by x) so the total distance is smallest;
  // wider gaps are preferred (a letter gap of 1px costs like 24px of distance). Returns the chosen gaps or null.
  function pickGaps(cands, e) {
    var m = e.length, G = cands.length
    if (m === 0) return []
    if (G < m) return null
    var INF = 1e18, cost = [], from = []
    for (var j = 0; j < m; j++) { cost.push(new Array(G).fill(INF)); from.push(new Array(G).fill(-1)) }
    var local = function(j, g) { return Math.abs(cands[g].c - e[j]) + 6 * (5 - Math.min(cands[g].w, 5)) }
    for (var g0 = 0; g0 < G; g0++) cost[0][g0] = local(0, g0)
    for (var j1 = 1; j1 < m; j1++) {
      var bestPrev = INF, bestIdx = -1
      for (var g1 = 0; g1 < G; g1++) {
        if (g1 > 0 && cost[j1 - 1][g1 - 1] < bestPrev) { bestPrev = cost[j1 - 1][g1 - 1]; bestIdx = g1 - 1 }
        if (bestIdx >= 0) { cost[j1][g1] = bestPrev + local(j1, g1); from[j1][g1] = bestIdx }
      }
    }
    var bg = -1, bc = INF
    for (var g2 = 0; g2 < G; g2++) if (cost[m - 1][g2] < bc) { bc = cost[m - 1][g2]; bg = g2 }
    if (bg < 0) return null
    var res = new Array(m)
    for (var jj = m - 1; jj >= 0; jj--) { res[jj] = cands[bg]; bg = from[jj][bg] }
    return res
  }

  // Lay the text out with one candidate family: pick the size (width fit, or height fit when more text was copied than is
  // highlighted), break the lines at spaces so each line's measured width is closest to that line's ink width on screen,
  // and give every line a small letter spacing that makes it fill the ink width exactly. `err` says how well this family
  // fits (letter height and unstretched line widths) so the best family can be picked.
  function layout(i) {
    var fmx = fx.fmList[i], famName = fx.famList[i], t = fx.text
    var adv = fmx.advanceWidth(t), tight = Math.max(1, fmx.tightBoundingRect(t).height)
    if (!fx.hasSel || adv <= 0) return { lines: [], px: fx.lineH * 0.7, err: 1e9, fam: famName }
    var pxw = 20 * fx.sumInk / adv
    var fitOk = pxw >= fx.lineH * 0.5 && pxw <= fx.lineH * 1.25
    var px = fitOk ? pxw : Math.max(9, 20 * fx.measH / tight)
    var heightErr = Math.abs(tight * px / 20 / fx.measH - 1)
    var sc = px / 20, out = [], pos = 0, mism = 0, tot = 0
    var wd = function(str) { return fmx.advanceWidth(str) * sc }
    for (var n = 0; n < fx.rects.length && pos < t.length; n++) {
      var r = fx.rects[n], target = fx.inkW[n], end = t.length, cut = false, last = n === fx.rects.length - 1
      if (last) {
        if (wd(t.slice(pos)) > target * 1.06 + 2) {
          end = t.length
          while (end > pos + 1 && wd(t.slice(pos, end) + "…") > target) end--
          cut = true
        }
      } else {
        var bestK = -1, bestD = 1e9
        for (var k = pos + 1; k <= t.length; k++) {
          if (k < t.length && t.charAt(k) !== " ") continue
          var w = wd(t.slice(pos, k)), d = Math.abs(w - target)
          if (d < bestD) { bestD = d; bestK = k }
          if (w > target * 1.4) break
        }
        end = bestK > 0 ? bestK : Math.min(t.length, pos + 1)
      }
      var txt = t.slice(pos, end).replace(/\s+$/, "") + (cut ? "…" : "")
      var chars = Array.from(txt), nat = 0
      for (var c = 0; c < chars.length; c++) nat += fmx.advanceWidth(chars[c]) * sc
      if (!cut) { mism += Math.abs(nat - target); tot += target }
      var lpx = px
      if (chars.length > 1 && nat > target * 1.03) { lpx = px * target / nat; nat = target }       // too wide for its line: shrink this line
      var sp = chars.length > 1 ? (target - nat) / (chars.length - 1) : 0
      sp = Math.max(-0.18 * lpx, Math.min(0.4 * lpx, sp))
      var dy = Math.max(-4, Math.min(4, ((r.it || 0) - (r.ib || 0)) / 2))
      out.push({ text: txt, start: pos, x: r.x + (r.il || 0), y: r.y + dy, h: r.h, spacing: sp, px: lpx })
      pos = end
      while (pos < t.length && t.charAt(pos) === " ") pos++
    }
    // Exact word slots: measured gaps place every word in its own slot, whatever the font. Two ways to decide which gaps are the
    // word gaps are tried and the one whose words fit their slots better wins:
    //  A) the W-L widest gaps overall (fx.wordGaps: needs a clear width step between word gaps and letter gaps), and
    //  B) per line: as many words as the font-based line break put there, at the gaps that best match where that line's words
    //     would start (dynamic programming over the measured gaps, wider gaps preferred).
    // The font-based layout above is the fallback when neither fits.
    if (fx.hasSel && !cutLast(out, fx.rects.length)) {
      var spN = fmx.advanceWidth(" ") * sc
      var build = function(gls, counts) {
        var wi = 0, ex = [], exMism = 0, exTot = 0
        for (var li = 0; li < fx.rects.length; li++) {
          var rr = fx.rects[li], gl = gls[li], nw = counts[li]
          for (var j = 0; j < nw; j++) {
            var s0 = j === 0 ? (rr.il || 0) : gl[j - 1][1], s1 = j === nw - 1 ? rr.w - (rr.ir || 0) : gl[j][0]
            var word = fx.wordTokens[wi++], wch = Array.from(word), wn = 0
            for (var q = 0; q < wch.length; q++) wn += fmx.advanceWidth(wch[q]) * sc
            var slot = Math.max(2, s1 - s0)
            exMism += Math.abs(wn - slot); exTot += slot
            var wpx = px
            var wsp = wch.length > 1 ? (slot - wn) / (wch.length - 1) : 0
            if (wsp < -0.12 * px) { wpx = px * slot / wn; wsp = 0 }          // far too wide: shrink the font; slightly too wide: tighten the letters
            wsp = Math.max(-0.35 * wpx, Math.min(1.0 * wpx, wsp))
            var wdy = Math.max(-4, Math.min(4, ((rr.it || 0) - (rr.ib || 0)) / 2))
            ex.push({ text: word, start: 0, x: rr.x + s0, y: rr.y + wdy, h: rr.h, spacing: wsp, px: wpx })
          }
        }
        return { ex: ex, ratio: exTot > 0 ? exMism / exTot : 1e9 }
      }
      var cands = []
      if (fx.exactWords) cands.push(build(fx.wordGaps, fx.wordGaps.map(function(a) { return a.length + 1 })))
      // B: counts from the font-based breaks, gaps by dynamic programming
      var counts = out.map(function(o) { return o.text.split(" ").filter(function(w) { return w.length > 0 }).length })
      var wtot = counts.reduce(function(a, b) { return a + b }, 0)
      if (out.length === fx.rects.length && wtot === fx.wordTokens.length) {
        var gB = [], wb = 0, okB = true
        for (var lb = 0; lb < fx.rects.length && okB; lb++) {
          var rb = fx.rects[lb], nwb = counts[lb], words = fx.wordTokens.slice(wb, wb + nwb)
          wb += nwb
          var cs = (rb.gaps || []).map(function(g) { return { s: g[0], e: g[1], c: (g[0] + g[1]) / 2, w: g[1] - g[0] } })
          if (nwb <= 1) { gB.push([]); continue }
          var nat = words.map(function(w2) { return fmx.advanceWidth(w2) * sc }), tot2 = nat.reduce(function(a, b) { return a + b }, 0) + (nwb - 1) * spN
          var f = tot2 > 0 ? fx.inkW[lb] / tot2 : 1, acc2 = 0, ee = []
          for (var jb = 0; jb < nwb - 1; jb++) { acc2 += nat[jb]; ee.push((rb.il || 0) + f * (acc2 + jb * spN + spN / 2)) }
          var ch = fx.pickGaps(cs, ee)
          if (!ch) { okB = false; break }
          gB.push(ch.map(function(c) { return [c.s, c.e] }))
        }
        if (okB) cands.push(build(gB, counts))
      }
      var bestC = null
      cands.forEach(function(c) { if (c.ratio <= 0.3 && (!bestC || c.ratio < bestC.ratio)) bestC = c })
      if (bestC) {
        var acc = 0
        bestC.ex.forEach(function(o) { o.start = acc; acc += o.text.length + 1 })
        return { lines: bestC.ex, px: px, err: heightErr + 3 * bestC.ratio, fam: famName }
      }
    }
    // Score: letter height + (weighted higher, it decides where the words land) the stretch the lines need to fill their
    // width + a big penalty for every rect that ended up without text.
    var missing = fx.rects.length - out.length
    return { lines: out, px: px, err: heightErr + 3 * (tot > 0 ? mism / tot : 0) + missing, fam: famName }
  }

  readonly property var layouts: {
    var out = []
    for (var i = 0; i < fx.fmList.length; i++) out.push(fx.layout(i))
    return out
  }
  readonly property var chosen: {
    var best = 0
    for (var i = 1; i < fx.layouts.length; i++) if (fx.layouts[i].err < fx.layouts[best].err - 0.005) best = i   // near ties keep the earlier (theme) font
    return fx.layouts[best]
  }
  readonly property string family: fx.hasSel ? fx.chosen.fam : fx.fontFamily
  readonly property real px: fx.hasSel ? fx.chosen.px : Math.max(9, Math.round(fx.lineH * 0.7))
  readonly property var lines: fx.hasSel ? fx.chosen.lines : []
  readonly property var chars: Array.from(fx.text)
  readonly property int step: Math.max(3, Math.min(14, Math.floor(700 / Math.max(1, fx.chars.length))))
  property bool bleeding: false

  // The selection's own highlight, repainted so the copied text sits on the same background.
  Repeater {
    model: fx.rects
    delegate: Rectangle {
      required property var modelData
      x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
      radius: 2
      color: fx.srcBg
      id: hl
      SequentialAnimation {
        running: true
        PauseAnimation { duration: fx.holdMs + 250 }
        NumberAnimation { target: hl; property: "opacity"; to: 0; duration: 500 }
      }
    }
  }

  readonly property int holdMs: 8000          // test twin: nothing moves, the overlay just stays for a while

  Repeater {
    model: fx.lines
    delegate: Row {
      id: lineRow
      required property var modelData
      x: modelData.x
      y: modelData.y
      spacing: modelData.spacing
      Repeater {
        model: Array.from(lineRow.modelData.text)
        delegate: Text { textFormat: Text.PlainText;
          id: lch
          required property int index
          required property string modelData
          text: modelData
          height: lineRow.modelData.h
          verticalAlignment: Text.AlignVCenter
          color: fx.srcFg
          font.family: fx.family
          font.pixelSize: lineRow.modelData.px || fx.px
          transform: [ Translate { id: ldrop }, Rotation { id: ltilt; origin.x: 4; origin.y: lineRow.modelData.h / 2 } ]
          SequentialAnimation {
            running: fx.bleeding
            PauseAnimation { duration: (lineRow.modelData.start + lch.index) * fx.step }
            ColorAnimation { target: lch; property: "color"; to: fx.accent; duration: 120 }
            ParallelAnimation {
              NumberAnimation { target: ldrop; property: "y"; to: 30 + (lch.index * 37 % 60); duration: 650; easing.type: Easing.InQuad }
              NumberAnimation { target: ltilt; property: "angle"; to: (lch.index % 2 ? 1 : -1) * (10 + lch.index * 7 % 25); duration: 650 }
              NumberAnimation { target: lch; property: "opacity"; to: 0; duration: 650 }
            }
          }
        }
      }
    }
  }

  // No highlight found: wrap the text inside a small box at the mouse.
  Flow {
    id: flow
    visible: !fx.hasSel
    x: fx.box.x
    y: fx.box.y
    width: fx.box.w

    Repeater {
      model: fx.hasSel ? [] : fx.chars
      delegate: Text { textFormat: Text.PlainText;
        id: ch
        required property int index
        required property string modelData
        text: modelData
        height: fx.lineH
        verticalAlignment: Text.AlignVCenter
        color: fx.srcFg
        font.family: fx.family
        font.pixelSize: fx.px
        transform: [ Translate { id: drop }, Rotation { id: tilt; origin.x: 4; origin.y: fx.lineH / 2 } ]

        SequentialAnimation {
          running: fx.bleeding
          PauseAnimation { duration: ch.index * fx.step }
          ColorAnimation { target: ch; property: "color"; to: fx.accent; duration: 120 }
          ParallelAnimation {
            NumberAnimation { target: drop; property: "y"; to: 30 + (ch.index * 37 % 60); duration: 650; easing.type: Easing.InQuad }
            NumberAnimation { target: tilt; property: "angle"; to: (ch.index % 2 ? 1 : -1) * (10 + ch.index * 7 % 25); duration: 650 }
            NumberAnimation { target: ch; property: "opacity"; to: 0; duration: 650 }
          }
        }
      }
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: fx.holdMs }
    PauseAnimation { duration: fx.chars.length * fx.step + 1000 }
  }
}

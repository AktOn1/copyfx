import QtQuick

// Base for "by image" effects: the selected text is not re-typed, it is CUT OUT OF THE SCREENSHOT (find-selection `sprite`)
// and the pieces are animated. So the real font, size, weight, colours, emoji, syntax highlighting and mixed styles are
// reproduced exactly, on any website or app, without knowing the font. The selection's highlight is repainted flat, the
// ink (transparent where it was highlight) is drawn over it in units: one unit = the ink between two blank column runs of a
// line (a letter or a few touching letters). Tint rows of the atlas recolour the ink without shaders.
//
// Effects set any of these (all take the unit object u = {i, line, word, x, y, w, h, cx, cy}):
//   dxFn(u), dyFn(u)   offset in px          rotFn(u) degrees        scaleFn(u)
//   alphaFn(u)         0..1                  tintFn(u)  atlas row: 0 = real colours, 1..12 rainbow (red, orange, yellow, lime,
//                                            green, spring, cyan, azure, blue, violet, magenta, rose), 13 accent, 14 white,
//                                            15 matrix green, 16 amber, 17 C64 blue, 18 terminal green, 19 hologram cyan, 20 neon pink,
//                                            21 hex blue (big selections only get a few of these rows, see sprite.tints)
// and read t (ms, 0..total, squeezed into runMs), n, step, lh, tg (bounding box of the text), rects, units.
EffectBase {
  id: fx

  property var dxFn: null
  property var dyFn: null
  property var rotFn: null
  property var scaleFn: null
  property var alphaFn: null
  property var tintFn: null
  property color hlColor: fx.srcBg
  property real hlAlpha: 1
  property bool autoRun: true                                        // run t from 0 to total in runMs, then finish
  property real total: 1000
  property real t: 0                                                 // ms of the effect's own timeline
  readonly property bool hasSprite: !!(fx.selFound && fx.sprite && fx.selRects && fx.selRects.length > 0)
  readonly property var rects: fx.selRects
  readonly property real lh: fx.hasSprite ? fx.selRects[0].h : fx.fbSize * 1.3
  readonly property var tg: {
    if (!fx.hasSprite) return { x: fbPanel.x, y: fbPanel.y, w: fbPanel.width, h: fbPanel.height }
    var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
    fx.selRects.forEach(function(r) { x0 = Math.min(x0, r.x); y0 = Math.min(y0, r.y); x1 = Math.max(x1, r.x + r.w); y1 = Math.max(y1, r.y + r.h) })
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
  }
  readonly property real windSign: Math.sin((fx.weather.dir + 180) * Math.PI / 180) >= 0 ? 1 : -1      // +1 = the wind blows to the right
  readonly property real windAmt: Math.min(1, fx.weather.wind / 40)
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }

  // Cut every line at the middle of each blank column run: units.
  readonly property int maxUnits: 160                               // long text: pieces are merged so the effect stays fast
  readonly property var units: {
    if (!fx.hasSprite) return []
    var out = [], gi = 0, word = 0, sp = fx.sprite
    for (var li = 0; li < fx.selRects.length; li++) {
      var r = fx.selRects[li], gaps = r.gaps || [], wgap = Math.max(3, r.h * 0.22), a = 0
      var push = function(b) {
        if (b - a < 1) return
        out.push({ i: gi++, line: li, word: word, x: r.x + a, y: r.y, w: b - a, h: r.h, cx: r.x + (a + b) / 2, cy: r.y + r.h / 2, sx: r.x + a - sp.x, sy: r.y - sp.y })
      }
      for (var k = 0; k < gaps.length; k++) {
        var g = gaps[k]
        var mid = Math.floor((g[0] + g[1]) / 2)          // whole pixels only: a half pixel would blur the ink
        push(mid)
        a = mid
        if (g[1] - g[0] >= wgap) word++
      }
      push(r.w)
      word++
    }
    if (out.length > fx.maxUnits) {
      // merge neighbours on the same line into chunks of `per` pieces
      var per = Math.ceil(out.length / fx.maxUnits), merged = [], cur = null, cnt = 0
      out.forEach(function(u) {
        if (cur && cur.line === u.line && cnt < per) {
          cur.w = u.x + u.w - cur.x
          cur.cx = cur.x + cur.w / 2
          cnt++
        } else {
          cur = { i: merged.length, line: u.line, word: u.word, x: u.x, y: u.y, w: u.w, h: u.h, cx: u.cx, cy: u.cy, sx: u.sx, sy: u.sy }
          merged.push(cur)
          cnt = 1
        }
      })
      return merged
    }
    return out
  }
  readonly property int n: fx.units.length
  readonly property real step: Math.max(4, Math.min(50, 600 / Math.max(1, fx.n)))

  // the selection's highlight, repainted flat: the ink is drawn on top of it
  Repeater {
    model: fx.hasSprite ? fx.selRects : []
    delegate: Rectangle {
      required property var modelData
      x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
      color: fx.hlColor
      opacity: fx.hlAlpha
    }
  }

  Repeater {
    model: fx.units
    delegate: Item {
      id: piece
      required property var modelData
      // effects ask for a palette colour (1..16); the atlas of a big selection has only some of them: that row, or none
      readonly property int tint: {
        var k = fx.tintFn ? fx.tintFn(modelData) : 0
        if (k <= 0) return 0
        var at = fx.sprite.tints ? fx.sprite.tints.indexOf(k) : k - 1
        return at >= 0 ? at + 1 : 0
      }
      readonly property real dx: fx.dxFn ? fx.dxFn(modelData) : 0
      readonly property real dy: fx.dyFn ? fx.dyFn(modelData) : 0
      readonly property real rot: fx.rotFn ? fx.rotFn(modelData) : 0
      readonly property real sc: fx.scaleFn ? fx.scaleFn(modelData) : 1
      // a piece that is not moved, tinted or scaled shows the opaque last row: the original pixels exactly
      readonly property int row: dx === 0 && dy === 0 && rot === 0 && sc === 1 && tint === 0 ? fx.sprite.rows - 1 : tint
      x: modelData.x + dx
      y: modelData.y + dy
      width: modelData.w
      height: modelData.h
      rotation: rot
      scale: sc
      opacity: fx.alphaFn ? fx.alphaFn(modelData) : 1
      clip: true                     // a clipped window onto ONE shared atlas texture (Image.sourceClipRect would re-decode the file per piece)
      Image {
        width: fx.sprite.w; height: fx.sprite.h * fx.sprite.rows          // layout size (the file holds device pixels on a scaled monitor)
        x: -piece.modelData.sx
        y: -(piece.modelData.sy + piece.row * fx.sprite.h)
        source: fx.sprite.url
        cache: true                  // one shared decode of the atlas (file names are unique per detection)
        smooth: false
      }
    }
  }

  // no selection found (or no sprite): a plain panel with the text, so the effect still shows something
  Rectangle {
    id: fbPanel
    visible: !fx.hasSprite
    x: fx.boxX(width); y: fx.boxY(height)
    width: fbText.width + fx.fbSize; height: fbText.height + fx.fbSize * 0.6
    radius: 8
    color: Qt.rgba(fx.fbBg.r, fx.fbBg.g, fx.fbBg.b, 0.92)
    border.color: Qt.rgba(fx.fbFg.r, fx.fbFg.g, fx.fbFg.b, 0.4)
    FxText { textFormat: Text.PlainText; id: fbText; x: fx.fbSize / 2; y: fx.fbSize * 0.3; text: fx.text; color: fx.fbFg; font.family: fx.fontFamily; font.pixelSize: fx.fbSize; maxWidth: fx.width * 0.6; maxLines: 6 }
  }

  SequentialAnimation {
    running: fx.autoRun
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}

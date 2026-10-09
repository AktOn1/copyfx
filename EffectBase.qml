import QtQuick

// Contract for every effect (effects/<id>/Effect.qml has this as its root).
// The host fills the item over the overlay (or a gallery preview card) and sets the inputs below.
// Start animating on Component.onCompleted and emit finished() when done.
Item {
  property string text: ""
  property point origin: Qt.point(width / 2, height / 2)   // mouse position, in this item's coordinates
  property color fg: "white"                               // theme colours
  property color bg: "black"
  property color accent: "#f19d88"
  property string fontFamily: ""
  property real fontSize: 22
  property bool compact: false                             // true in gallery previews

  // Only filled for effects with "sample": true in effect.json: colours read from the screen around the
  // mouse when you copied, and whether the source window looks like a terminal/editor (monospace).
  property color srcBg: bg
  property color srcFg: fg
  property bool srcMono: false

  // Only filled for effects with "selection": true: where the copied text sits on screen, found by looking for the
  // selection highlight next to the mouse (see find-selection). selRects = one rect per text line, in this item's
  // coordinates. srcBg/srcFg then hold the highlight and text colours. selFound is false when nothing was found.
  property bool selFound: false
  property var selRects: []
  property real selLineH: 0
  // Only with a detected selection: the selected text cut out of the screenshot as a picture ("by image" effects): an atlas
  // {url,x,y,w,h,rows} - `rows` copies of the selection box stacked vertically: row 0 = real colours, rows 1.. = flat tints.
  property var sprite: null
  property var selDebug: ({})    // find-selection's debug info in local coordinates (region, block, window, mouse, reason...)

  // The plain panel drawn when no selection was found: the host sizes and colours it like the last selection seen in the same app
  // (0 / unset = the effect's own fontSize and theme colours, as in the gallery preview).
  property real fbPx: 0
  property color fbBg: bg
  property color fbFg: fg
  readonly property real fbSize: fbPx > 0 ? fbPx : fontSize

  // Set for notifications (notifyfx): where on the screen it goes, how long it stays, and what it says.
  property string posName: ""            // "", topleft|top|topright|left|center|right|bottomleft|bottom|bottomright
  property int durationMs: 0             // 0 = derive from the text length
  property string title: ""
  property string level: "info"          // info|success|warn|error
  property string icon: ""

  // How long the finished text should stay readable: grows with the length, capped; a notification sets its own.
  readonly property int readMs: durationMs > 0 ? durationMs : Math.min(6000, 1100 + text.length * 12)
  // The same for the small copy effects: short.
  readonly property int holdMs: durationMs > 0 ? durationMs : Math.min(1100, 500 + text.length * 10)

  // ---- THE start point every effect shares ----
  // Where the copied text was on screen: the union of the detected selection rects when the host found them,
  // otherwise just the mouse position (a zero-size rect). Effects place themselves ONLY through startRect / boxX / boxY,
  // so changing where effects begin (e.g. always at the cursor, or beside the text) is a change in this block alone.
  readonly property bool anchored: selFound && selRects.length > 0 && posName === ""
  readonly property rect startRect: {
    if (!anchored) return Qt.rect(origin.x, origin.y, 0, 0)
    var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
    for (var i = 0; i < selRects.length; i++) {
      var r = selRects[i]
      x0 = Math.min(x0, r.x); y0 = Math.min(y0, r.y); x1 = Math.max(x1, r.x + r.w); y1 = Math.max(y1, r.y + r.h)
    }
    return Qt.rect(x0, y0, x1 - x0, y1 - y0)
  }
  readonly property real startCX: startRect.x + startRect.width / 2
  readonly property real startCY: startRect.y + startRect.height / 2

  // Helpers for effects that draw a panel: near the mouse by default, or at a named screen position.
  readonly property real u: compact ? 0.6 : 1                       // size unit for decorations
  readonly property real edge: compact ? 8 : 24
  readonly property real barGap: compact ? 8 : 46                   // keep clear of the bar at the top
  function boxX(w) {
    switch (posName) {
      case "left": case "topleft": case "bottomleft": return edge
      case "right": case "topright": case "bottomright": return width - w - edge
      case "top": case "bottom": case "center": return (width - w) / 2
    }
    if (anchored) return Math.max(8, Math.min(startCX - w / 2, width - w - 8))
    // no selection (a click copy, a button): right next to the mouse - on its right, or on its left when there is no room
    var right = origin.x + 18
    return right + w <= width - 8 ? right : Math.max(8, origin.x - 18 - w)
  }
  function boxY(h) {
    switch (posName) {
      case "top": case "topleft": case "topright": return barGap
      case "bottom": case "bottomleft": case "bottomright": return height - h - edge
      case "left": case "right": case "center": return (height - h) / 2
    }
    if (anchored) return Math.max(8, Math.min(startCY - h / 2, height - h - 8))     // over the original text
    return Math.max(8, Math.min(origin.y - h / 2, height - h - 8))                    // level with the mouse
  }

  // Theme colours (the Omarchy theme's palette when config themeColors is on, else the classic ones): effects use these for red/green/cyan... things
  // so they follow the theme. See Logic.classicTheme / parseThemeColors.
  property var theme: ({ name: "", mode: "dark", red: "#ff5c57", orange: "#ff9f1c", yellow: "#ffd166", green: "#5af78e", cyan: "#00e5ff", blue: "#3aa0ff",
                         magenta: "#ff3dcb", accent: "#f19d88", fg: "#e6e6e6", bg: "#14161a", muted: "#8b949e" })

  // Weather state (see logic.js weatherState): {kind: clear|partly|cloudy|fog|drizzle|rain|snow|thunder, isDay, golden, temp (C), wind (km/h),
  // dir (deg, where it blows FROM), precip (mm), cloud (%)}. Weather effects read it.
  property var weather: ({ kind: "clear", isDay: true, golden: false, temp: 15, wind: 8, dir: 250, precip: 0, cloud: 20 })

  // Length of the short on-text / by-image effects in ms (config durationMs, the box in the gallery). Their timelines are squeezed into it;
  // k scales hard-coded durations of effects that are not driven by a single timeline.
  property int runMs: 200
  readonly property real k: runMs / 200

  signal finished()
}

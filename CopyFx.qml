import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "logic.js" as Logic

// CopyFX: plays an animated effect built from the copied text on every copy.
// Effects live in effects/<id>/ (effect.json + Effect.qml on top of EffectBase.qml).
// Overlay plugin: `omarchy-shell shell toggle io.github.akton1.copyfx` opens the effect gallery;
// `... toggle io.github.akton1.copyfx '{"test":"Hello","effect":"jump"}'` plays an effect directly.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool galleryOpen: false
  // The shell's toggle() decides open-vs-close from this; without it every second toggle call would
  // be routed to close() and dropped (test/copy-key calls included).
  readonly property bool opened: root.galleryOpen
  // The bar menu (BarWidget.qml) is open: its previews are tests like the gallery's, not copies (they play without a selection, no screenshot).
  property bool menuOpen: false
  readonly property bool testing: root.galleryOpen || root.menuOpen
  property var effects: []
  // Gallery filter: the smallest size present is always on, the others are chips in the header.
  readonly property var presentSizes: { var z = []; root.effects.forEach(function(e) { if (z.indexOf(e.size) < 0) z.push(e.size) }); return z }
  readonly property var shownSizes: Logic.visibleSizes(root.config.sizes, root.presentSizes)
  readonly property var chipSizes: Logic.chosenSizes(root.config.sizes, root.presentSizes)
  property string query: ""
  readonly property var shown: root.effects.filter(function(e) {
    return root.shownSizes.indexOf(e.size) >= 0 && Logic.matchesQuery(e, root.query)
  })
  property var config: Logic.parseConfig("")
  property int cursorIndex: 0
  property bool armed: false        // ignore the initial clipboard snapshot wl-paste --watch emits at start

  // Currently playing effect (for the overlay window).
  property bool playing: false
  property var fxScreen: null
  property string fxText: ""
  property string fxId: ""
  property point fxOrigin: Qt.point(0, 0)
  property string lastId: ""
  property string pendingText: ""
  property string pendingRaw: ""          // the copied text as it was (newlines kept): the info badge looks at this
  property string pendingForce: ""
  property string lastText: ""
  property double lastTextAt: 0
  property bool pendingViaKey: false
  property string pendingCls: ""
  property var pendingNotify: null       // {pos, dur, title, level, icon} while a notification waits for the cursor probe
  property string fxPos: ""
  property bool fxIsNotify: false
  property int fxDurationMs: 0
  property string fxTitle: ""
  property string fxLevel: "info"
  property string fxIcon: ""
  property var pendingWin: [0, 0, 0, 0]   // focused window x, y, w, h: the only place a selection can be
  property color fxSrcBg: "black"
  property color fxSrcFg: "white"
  property bool fxMono: false
  property bool fxSelFound: false
  property var fxSelRects: []
  property var fxSprite: null         // the selected text cut out of the screenshot (find-selection sprites=): {url,x,y,w,h,rows}
  readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || (root.dataDir + "/run")   // never a shared /tmp path: the shell loads QML from here
  readonly property string spriteDir: root.runDir + "/copyfx-sprites"
  property real fxSelLineH: 0
  property real fxFbPx: 0              // the plain panel shown when no selection was found: text size and colours (see fallbackLook)
  property color fxFbBg: "black"
  property color fxFbFg: "white"
  property var looks: ({})             // last detected selection look {bg, fg, lineH} per app ("cls:...") and per window ("win:x,y,w,h")
  property var fxSelDebug: ({})
  property double intentAt: 0       // last Ctrl+C/X keypress (ms since epoch)
  property var rcPos: null          // last right-click (non-consuming bind in bindings.lua): { x, y, win, at, used } - where "Copy link address" was chosen from
  property var deferred: ({ x: 0, y: 0 })

  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")
  readonly property string dataDir: dataHome + "/omarchy-shell/copyfx"
  readonly property string configPath: dataDir + "/config.json"
  readonly property string pluginDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")).replace(/\/$/, "")
  property string effectBase: Qt.resolvedUrl(".").toString()           // where effects/ and the effect base classes are loaded from
  // Dev reload: {"reload": "<dir>"} copies <dir> to a fresh runtime tree and effects load from there (see tests/dev-reload.sh).
  property string effectLocal: root.pluginDir                           // local path of the tree effects/ and posters/ are read from
  readonly property string liveRoot: root.runDir + "/copyfx-live"
  function materialise(src) {
    matProc.src = src
    matProc.target = root.liveRoot + "/v" + String(Date.now())
    matProc.command = ["python3", src + "/bin/copyfx", "materialise", src, matProc.target]
    matProc.running = false
    matProc.running = true
  }
  Process {
    id: matProc
    property string src: ""
    property string target: ""
    stdout: StdioCollector {
      onStreamFinished: {
        var r = null
        try { r = JSON.parse(this.text) } catch (e) {}
        if (!r) { console.log("copyfx: materialise failed"); return }
        if (r.built) { root.effectBase = "file://" + matProc.target + "/"; root.effectLocal = matProc.target }
        else { root.effectBase = "file://" + matProc.src + "/"; root.effectLocal = matProc.src }
        console.log("copyfx: effects from", root.effectLocal)
        scanProc.running = false
        scanProc.running = true
      }
    }
  }
  // Where the scripts and the effect list come from: the plugin dir, or a work copy outside the watched plugin dir while developing
  // (see the {"reload": "<dir>"} payload). Editing inside the plugin dir makes Omarchy reload all plugins on every write (bar widgets flicker).
  property string srcDir: root.pluginDir
  readonly property string sampleScript: root.srcDir + "/sample-colors"
  readonly property string selectionScript: root.srcDir + "/find-selection"
  readonly property string clipScript: root.pluginDir + "/bin/copyfx-clip"

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color accent: Color.menu.selectedText
  property string fontFamily: Style.font.menuFamily

  // ---------- open / close (gallery) ----------
  function open(payloadJson) {
    var p = {}
    try { p = JSON.parse(payloadJson || "{}") } catch (e) {}
    if (p.menuState !== undefined) { root.menuOpen = p.menuState === "open"; return }
    if (p.set) {      // the bar menu's choices: effect, mode, enabled (nothing else)
      var r = Logic.applySet(root.config, p.set, root.effects.map(function(e) { return e.id }))
      if (r.changed) { root.config = r.config; root.saveConfig() }
      return
    }
    if (p.stop) { root.playing = false; fxLoader.setSource("", {}); return }
    if (p.yank) { root.onYank(p.yank); return }
    if (p.weatherTest !== undefined) { root.weatherOverride = String(p.weatherTest); console.log("copyfx: weather override", root.weatherOverride || "(none)", "->", root.weatherEffectId); return }
    // Dev loop without restarting the whole shell (which flickers the bar): QML types are cached per URL for the life of the shell, so
    // {"reload":true} copies effects/, the effect base classes (EffectBase/SourceText/SpriteText/FxText...) and logic to a fresh
    // versioned directory under $XDG_RUNTIME_DIR/copyfx-dev and plays effects from THERE from now on (new URLs = no stale cache).
    // CopyFx.qml itself and PreviewCard.qml are the host and still need omarchy-restart-shell.
    if (p.reload) {
      if (!root.config.devReload) { console.log("copyfx: reload ignored (set \"devReload\": true in config.json to use the dev loop)"); return }
      var src = typeof p.reload === "string" && p.reload !== "" ? p.reload.replace(/\/$/, "") : root.pluginDir
      root.srcDir = src
      root.galleryOpen = false
      root.playing = false
      fxLoader.setSource("", {})
      root.materialise(src)
      return
    }
    if (p.notify) { root.notify(p.notify); return }
    if (p.rightClick) { rcProc.running = false; rcProc.running = true; return }
    if (p.copyKey) {   // sent by the non-consuming Ctrl+C / Ctrl+X binds in bindings.lua
      root.intentAt = Date.now()
      root.tKey = root.intentAt
      root.lap("copy key pressed")
      if (!root.selCache && !root.selDetecting && !selDetectTimer.running) root.prefetch()      // the selection is already detected / being detected: nothing to look for
      keyReadTimer.restart()
      return
    }
    if (p.test) {
      root.trigger(String(p.test), p.effect ? String(p.effect) : "")
      return
    }
    root.galleryOpen = true
    root.query = ""
    root.refreshWeather()
    // make sure the currently chosen effect is visible: switch on its size chip if it is hidden
    var ce = root.effects.find(function(e) { return e.id === root.config.effect })
    if (ce && root.chipSizes.length && root.shownSizes.indexOf(ce.size) < 0) root.setConfig("sizes", Logic.toggleSize(root.config.sizes, ce.size, root.presentSizes))
    root.cursorIndex = Math.max(0, root.shown.findIndex(function(e) { return e.id === root.config.effect }))
    Qt.callLater(function() { searchField.forceActiveFocus() })
  }
  function close() { root.galleryOpen = false }
  function toggle(payloadJson) {
    var p = {}
    try { p = JSON.parse(payloadJson || "{}") } catch (e) {}
    if (p.test || p.menuState !== undefined || p.set || p.copyKey || p.rightClick || p.notify || p.stop || p.reload || p.yank || p.weatherTest !== undefined) root.open(payloadJson)
    else if (root.galleryOpen) root.close()
    else root.open(payloadJson)
  }

  // ---------- notifications (notifyfx) ----------
  // {"notify": {"text","title","position","duration"(ms),"effect","level","icon"}} shows any effect as a notification at a named
  // screen position for a chosen time. The default effect is "toast". One notification at a time: a new one replaces the old.
  function notify(n) {
    var id = String(n.effect || "toast")
    if (!root.effects.some(function(e) { return e.id === id })) { console.log("copyfx: notify: unknown effect", id); id = "toast" }
    root.pendingNotify = { pos: String(n.position || ""), dur: Math.max(0, Number(n.duration) || 0), title: String(n.title || ""),
                           level: String(n.level || "info"), icon: String(n.icon || "") }
    root.trigger(String(n.text || n.title || ""), id)
  }
  // Anchor point for a named position (effects that use `origin` instead of boxX/boxY follow it too).
  function posOrigin(name, w, h, cx, cy) {
    var mx = 70, my = 80
    switch (name) {
      case "topleft": return Qt.point(mx, my)
      case "top": return Qt.point(w / 2, my)
      case "topright": return Qt.point(w - mx, my)
      case "left": return Qt.point(mx, h / 2)
      case "center": return Qt.point(w / 2, h / 2)
      case "right": return Qt.point(w - mx, h / 2)
      case "bottomleft": return Qt.point(mx, h - my)
      case "bottom": return Qt.point(w / 2, h - my)
      case "bottomright": return Qt.point(w - mx, h - my)
    }
    return Qt.point(cx, cy)
  }

  // ---------- copies that are not text (files, images, anything else) ----------
  // No highlighted text to anchor on, so they get a plain toast at the mouse. Cut counts as copy for now. Per-kind feedback comes later via settings.
  property string lastObjLabel: ""
  property double lastObjAt: 0
  function presentObject(e) {
    var d = Logic.describeObject(e)
    var key = d.title + "|" + d.text, now = Date.now()
    if (key === root.lastObjLabel && now - root.lastObjAt < 800) { console.log("copyfx: dropped duplicate object copy"); return }
    root.lastObjLabel = key
    root.lastObjAt = now
    console.log("copyfx: object copy", e.type, key)
    root.notify({ title: d.title, text: d.text || d.title, duration: 1800, level: "info" })
  }

  // ---------- config ----------
  function saveConfig() { configFile.setText(JSON.stringify(root.config, null, 2) + "\n") }
  function setConfig(key, value) {
    var c = Object.assign({}, root.config)
    c[key] = value
    root.config = c
    root.saveConfig()
  }
  function toggleSizeChip(size) {
    var cur = root.shown[root.cursorIndex]
    root.setConfig("sizes", Logic.toggleSize(root.config.sizes, size, root.presentSizes))
    var i = cur ? root.shown.findIndex(function(e) { return e.id === cur.id }) : -1
    root.cursorIndex = Math.max(0, i)
    flick.contentY = 0
  }
  function choose(idx) {
    if (idx < 0 || idx >= root.shown.length) return
    root.setConfig("effect", root.shown[idx].id)
    if (root.config.mode === "random") root.setConfig("mode", "selected")
  }

  // ---------- playing an effect ----------
  // Probe the cursor first so the effect can appear on that monitor / next to the mouse.
  function trigger(text, forceId, viaKey) {
    var t = Logic.sanitize(text, 0)   // the per-effect limit is applied in play()
    if (!t || root.effects.length === 0) { console.log("copyfx: skip (empty text or no effects)"); return }
    root.pendingText = t
    root.pendingRaw = String(text)
    root.pendingForce = forceId
    root.pendingViaKey = !!viaKey
    cursorProc.running = false
    cursorProc.running = true
  }

  // ---- prefetch: find the selection as soon as the copy KEY is pressed (the highlight is still on screen), so the
  // effect can start the moment the clipboard changes instead of waiting for the screenshot + detection.
  property var pref: null            // { at, x, y, forced, result } of the last finished prefetch
  property bool prefBusy: false
  property double prefStarted: 0
  property double tKey: 0            // copy key press time, for the latency log
  function lap(label) { console.log("copyfx t+" + (root.tKey ? Date.now() - root.tKey : -1) + "ms", label) }

  // Where the mouse was when text was last SELECTED (primary selection changed). Ctrl+C often comes after the mouse has moved on;
  // the selection is then searched at this position first.
  property var selPos: null          // { x, y, win, at }
  property var primaryHist: []       // the last primary selection changes { at, text }: a drag shows as several different texts in a row
  Process {
    id: primaryWatch
    running: true
    command: ["wl-paste", "--primary", "--type", "text", "--watch", root.pluginDir + "/bin/copyfx-selpos"]
    stdout: SplitParser {
      onRead: function(line) {
        if (!root.armed) return
        try {
          var p = JSON.parse(line); p.at = Date.now()
          // A copy button / the copy itself can re-assert the primary selection with the copied text (Chromium does): an event right AFTER a clipboard
          // event with the very same text is a side effect, not a selection.
          if (root.lastText && p.at - root.lastTextAt < 250 && Logic.sanitize(p.text, 0) === root.lastText) return
          root.primaryHist = root.primaryHist.concat([{ at: p.at, text: Logic.sanitize(p.text, 0) }]).slice(-8)
          var prev = root.selPos
          // The copy itself often re-asserts the primary selection (same text) a moment later, and the mouse may be somewhere else by then: that is not a
          // new selection - keep the cache and the remembered position.
          // Chromium re-asserts the primary selection when you press Ctrl+C - with the SAME text, often just before the clipboard event. Same text as the
          // selection we already know: not a new selection (its position, cache and time stay as they were).
          var dup = prev && Logic.sanitize(prev.text, 0) === Logic.sanitize(p.text, 0)
          console.log("copyfx: primary event", Logic.sanitize(p.text, 0).length, "chars", dup ? "(same text: ignored)" : "(new)", prev ? "prev " + Logic.sanitize(prev.text, 0).length : "")
          if (dup) return
          // A selection we detected before (another window's, or this one's a moment ago) that is now asserted again - e.g. Ctrl+C in a window you only
          // hovered, while another window holds the newest selection: its earlier detection is used until a fresh one replaces it.
          root.selPos = p; root.selCache = root.historyFor(p.text); selDetectTimer.restart()
        } catch (e) {}
      }
    }
  }

  // Detect the selection as soon as it is MADE (debounced while it is still being dragged): the highlight is on screen and the mouse is at
  // its end. When the copy comes with the same text, the effect starts from this cache at once - no screenshot after the copy, and the
  // mouse may be anywhere.
  property var selCache: null        // { at, text, x, y, result }
  property var selHistory: []        // the last few detections { at, text, x, y, result } of different selections (two windows side by side)
  function historyFor(text) {
    var t = Logic.sanitize(text, 0)
    var live = root.selHistory.filter(function(h) { return Date.now() - h.at < 600000 }).reverse()
    return live.find(function(h) { return h.text === t }) || live.find(function(h) { return Math.min(h.text.length, t.length) >= 0.97 * Math.max(h.text.length, t.length) && Logic.sameSelection(h.text, t) }) || null      // the exact text wins over a merely similar one; a LONGER/SHORTER selection that merely contains an earlier one (the same drag passing through it) is a different selection
  }
  property bool selDetecting: false
  property var cacheWaiter: null
  Timer { id: cacheWaitTimer; interval: 2200; onTriggered: { var w = root.cacheWaiter; root.cacheWaiter = null; if (w) w() } }      // never wait forever
  Timer { id: selDetectTimer; interval: 120; onTriggered: root.detectSelection() }
  function detectSelection() {
    var p = root.selPos
    if (!p || !root.config.enabled || root.config.anchor !== "selection") return
    if (root.playing || root.testing) { selDetectTimer.interval = 300; selDetectTimer.restart(); return }      // the screenshot must not show an effect / the gallery
    selDetectTimer.interval = 120
    root.selDetecting = true
    cacheSel.forPos = p
    cacheSel.command = [root.selectionScript, String(Math.round(p.x)), String(Math.round(p.y))]
      .concat((p.win || [0, 0, 0, 0]).map(function(v) { return String(Math.round(v)) }))
      .concat(root.spriteArgs())
    cacheSel.running = false
    cacheSel.running = true
  }
  Process {
    id: cacheSel
    property var forPos: null
    stdout: StdioCollector {
      onStreamFinished: {
        var r = null
        try { r = JSON.parse(this.text) } catch (e) {}
        if (!r) return                  // this run was killed because a newer selection event restarted the detection: that run reports
        var stale = root.selPos !== cacheSel.forPos            // the selection changed again while we were looking
        if (!stale) {
          if (r && r.found) root.rememberLook(r, "", cacheSel.forPos.win)
          root.selCache = r && r.found ? { at: Date.now(), text: Logic.sanitize(cacheSel.forPos.text, 0), x: cacheSel.forPos.x, y: cacheSel.forPos.y, result: r } : null
          if (root.selCache) root.selHistory = root.selHistory.filter(function(h) { return h.text !== root.selCache.text }).concat([root.selCache]).slice(-6)
          else {
            var known = root.historyFor(cacheSel.forPos.text)
            if (known) { root.selCache = known; console.log("copyfx: same text, kept the earlier detection") }
          }
          console.log("copyfx: selection " + (root.selCache ? "detected" : "not detected") + " when it was made" + (r && r.debug ? " (" + r.debug.ms + "ms" + (root.selCache ? "" : ", " + r.debug.reason + ", mouse " + JSON.stringify(cacheSel.forPos.x) + "," + JSON.stringify(cacheSel.forPos.y)) + ")" : " (no result)"))
        }
        root.selDetecting = false
        if (stale) return               // a newer selection event has its own detection coming (its timer is running): the waiting copy waits for THAT one
        var w = root.cacheWaiter
        root.cacheWaiter = null
        if (w) w()
      }
    }
  }

  function prefetch() {
    if (!root.config.enabled || root.config.anchor !== "selection") return
    root.pref = null
    root.prefBusy = true
    root.prefStarted = Date.now()
    if (root.playing) {              // the screenshot must not show the previous effect
      root.playing = false
      fxLoader.setSource("", {})
      prefDelay.restart()
    } else prefProbe.running = true
  }
  Timer { id: prefDelay; interval: 60; onTriggered: prefProbe.running = true }
  property var prefAttempts: []
  property int prefIdx: 0
  Process {
    id: prefProbe
    command: ["bash", "-c", "jq -cs '{x: .[0].x, y: .[0].y, win: [(.[1].at[0] // 0), (.[1].at[1] // 0), (.[1].size[0] // 0), (.[1].size[1] // 0)]}' <(hyprctl cursorpos -j) <(hyprctl activewindow -j)"]
    stdout: StdioCollector {
      onStreamFinished: {
        var p = null
        try { p = JSON.parse(this.text) } catch (e) {}
        root.lap("prefetch: mouse probed")
        if (!p) { root.prefBusy = false; root.prefDone(); return }
        // The mouse may have moved away from the selection since it was made: then look there first, and here second.
        var sp = root.selPos
        var far = sp && Date.now() - sp.at < 300000 && (Math.abs(sp.x - p.x) > 200 || Math.abs(sp.y - p.y) > 200)
        var here = { x: p.x, y: p.y, win: p.win || [0, 0, 0, 0], forced: false }
        root.prefAttempts = far ? [{ x: sp.x, y: sp.y, win: sp.win || [0, 0, 0, 0], forced: true }, here] : [here]
        root.prefIdx = 0
        root.prefRun()
      }
    }
  }
  function prefRun() {
    var a = root.prefAttempts[root.prefIdx]
    root.prefPos = a
    prefSel.command = [root.selectionScript, String(Math.round(a.x)), String(Math.round(a.y))]
      .concat(a.win.map(function(v) { return String(Math.round(v)) }))
      .concat(root.spriteArgs())
    prefSel.running = false
    prefSel.running = true
  }
  property var prefPos: ({ x: 0, y: 0 })
  Process {
    id: prefSel
    stdout: StdioCollector {
      onStreamFinished: {
        if (!this.text.trim()) return          // a killed run (a newer copy key press restarted the prefetch): the run that replaced it reports, this empty one must not count as "not found"
        var r = null
        try { r = JSON.parse(this.text) } catch (e) {}
        var found = !!(r && r.found)
        root.lap("prefetch: selection " + (found ? "found" : "not found") + (r && r.debug ? " (find-selection " + r.debug.ms + "ms)" : "") + (root.prefPos.forced ? " at the remembered selection position" : ""))
        if (!found && root.prefIdx + 1 < root.prefAttempts.length) { root.prefIdx++; root.prefRun(); return }
        root.pref = r ? { at: Date.now(), x: root.prefPos.x, y: root.prefPos.y, forced: !!(found && root.prefPos.forced), result: r } : null
        root.prefBusy = false
        root.prefDone()
      }
    }
  }
  property var prefWaiter: null      // play() waiting for the prefetch that is still running
  function prefDone() {
    var w = root.prefWaiter
    root.prefWaiter = null
    if (w) w()
  }
  // A usable prefetched result for a play at (x, y): recent, and either found at the remembered selection position or the mouse
  // has not moved much since.
  function prefFresh(x, y) {
    var p = root.pref
    return p && Date.now() - p.at < 2500 && (p.forced || (Math.abs(p.x - x) < 40 && Math.abs(p.y - y) < 40))
  }

  readonly property int intentWindowMs: 1500

  function recentIntent() { return Date.now() - root.intentAt < root.intentWindowMs }

  // ---- yank integration (Neovim, tmux, anything that can call `copyfx-yank`): a program that has just highlighted the copied text tells
  // us the highlight's EXACT colour: {"yank": {"hl": "#rrggbb", "text": "..."}}. Then no mouse position is needed: the colour is searched in the
  // whole focused window and the effect plays right over that highlight.
  property var yank: null                           // { hl, text (sanitized), at }
  function yankFresh(text) { var y = root.yank; return !!y && Date.now() - y.at < 700 && (text === undefined || y.text === text) }
  // The yanked text never travels in a process argument: the sender writes it to a private file in the runtime dir and the payload only says "file".
  Process {
    id: yankRead
    property string hl: ""
    command: ["sh", "-c", "f=\"$1\"; head -c 100000 \"$f\"; rm -f \"$f\"", "sh", root.runDir + "/copyfx-yank.txt"]
    stdout: StdioCollector {
      onStreamFinished: root.onYank({ hl: yankRead.hl, text: this.text })
    }
  }
  function onYank(y) {
    if (y.file) { yankRead.hl = String(y.hl || ""); yankRead.running = false; yankRead.running = true; return }
    root.tKey = Date.now()
    root.yank = { hl: String(y.hl || ""), text: Logic.sanitize(String(y.text || ""), 0), at: Date.now() }
    root.lap("yank notice (highlight " + root.yank.hl + ")")
    if (yankWaitTimer.running) { yankWaitTimer.stop(); root.play(root.deferred.x, root.deferred.y); return }
    yankOwnTimer.restart()                         // if no clipboard event plays this text soon (no system clipboard), play it ourselves
  }
  Timer { id: yankWaitTimer; interval: 70; onTriggered: root.play(root.deferred.x, root.deferred.y) }
  Timer {
    id: yankOwnTimer
    interval: 160
    onTriggered: if (root.yank && root.lastText !== root.yank.text) root.trigger(root.yank.text, "")
  }

  function cursorKnown(x, y, cls) {
    // Copy-on-select apps (terminals, Claude Code) also write the clipboard when you only select text.
    // For classes listed in `keyOnlyClasses` (config.json) the effect plays only if a copy key
    // (Ctrl+C/X, see bindings.lua) was pressed just before. The key signal can trail the clipboard
    // event by a few ms, so undecided copies wait briefly. Test effects (forced id) always play.
    console.log("copyfx copy from class:", cls || "(none)", root.pendingViaKey ? "(copy key)" : "")
    root.pendingCls = cls || ""
    var keyOnly = Logic.isIgnored(cls, root.config.keyOnlyClasses)
    // Copy-key path: apps that copy on select don't re-set the clipboard when the same text is copied
    // again, so no clipboard event arrives. For those apps the key press itself plays the effect.
    // Other apps are handled by the clipboard watcher.
    if (root.pendingViaKey && !keyOnly) { console.log("copyfx: skip key path (watcher handles this app)"); return }
    if (root.pendingViaKey) { root.play(x, y); return }
    if (!root.pendingForce && Logic.isIgnored(cls, root.config.keyOnlyClasses) && !root.recentIntent()) {
      console.log("copyfx: waiting for a copy key press (select-copy app)")
      root.deferred = { x: x, y: y }
      deferTimer.restart()
      return
    }
    // A terminal copy without a mouse selection may be a Neovim/tmux yank whose notice is a few ms behind the clipboard event: wait a moment.
    if (!root.pendingForce && Logic.isMonoClass(cls) && !root.yankFresh(root.pendingText) && !root.cacheMatches(root.pendingText)) {
      root.deferred = { x: x, y: y }
      yankWaitTimer.restart()
      return
    }
    root.play(x, y)
  }
  function cacheMatches(text) { var c = root.selCache; return !!c && Date.now() - c.at < 300000 && Logic.sameSelection(c.text, text) }

  // After a copy key press, give the app a moment to set the clipboard, then read it.
  Timer { id: keyReadTimer; interval: 70; onTriggered: keyProc.running = true }
  Process {
    id: keyProc
    command: ["sh", "-c", "wl-paste --list-types 2>/dev/null | grep -qx x-kde-passwordManagerHint && exit 0; wl-paste --no-newline --type text 2>/dev/null | head -c 1000000"]
    stdout: StdioCollector {
      onStreamFinished: if (root.config.enabled) root.trigger(this.text, "", true)
    }
  }

  Timer {
    id: deferTimer
    interval: 300
    onTriggered: {
      if (root.recentIntent()) root.play(root.deferred.x, root.deferred.y)
      else console.log("copyfx: dropped (select-copy app, no copy key)")
    }
  }

  function play(x, y) {
    root.rejHint = ""
    root.lap("play (clipboard text ready)")
    // Apps often set the clipboard twice for one copy; play once.
    var now = Date.now()
    if (!root.pendingForce && root.pendingText === root.lastText && now - root.lastTextAt < 800) { console.log("copyfx: dropped duplicate"); return }
    root.lastText = root.pendingText
    root.lastTextAt = now
    var scr = null
    var list = Quickshell.screens
    for (var i = 0; i < list.length; i++) {
      var s = list[i]
      if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) { scr = s; break }
    }
    if (!scr) scr = list.length ? list[0] : null
    if (!scr) return
    var id = root.pendingForce && root.effects.some(function(e) { return e.id === root.pendingForce })
      ? root.pendingForce
      : Logic.pickEffect(root.effects, root.config.mode, root.config.effect, root.lastId)
    if (!id) return
    id = root.resolveEffect(id)                  // the meta effect "img-weather" plays whatever matches the weather now
    var eff = root.effects.find(function(e) { return e.id === id })
    console.log("copyfx: play", id, "chars", root.pendingText.length, "class", root.pendingCls || "-")
    root.lastId = id
    root.fxScreen = scr
    var nt = root.pendingNotify
    root.pendingNotify = null
    root.infoData = (nt || root.testing || root.config.info === "off") ? null : Logic.classifyText(root.pendingRaw, root.config.info)
    root.fxPos = nt ? nt.pos : ""
    root.fxIsNotify = !!nt
    root.fxDurationMs = nt ? nt.dur : 0
    root.fxTitle = nt ? nt.title : ""
    root.fxLevel = nt ? nt.level : "info"
    root.fxIcon = nt ? nt.icon : ""
    root.fxOrigin = root.posOrigin(root.fxPos, scr.width, scr.height, x - scr.x, y - scr.y)
    root.fxText = Logic.sanitize(root.pendingText, Logic.textLimit(root.config.maxChars, eff ? eff.maxChars : 0))
    root.fxId = id
    root.fxMono = Logic.isMonoClass(root.pendingCls)
    root.fxSrcBg = root.background
    root.fxSrcFg = root.foreground
    root.fxSelFound = false
    root.fxSelRects = []
    root.fxSprite = null
    root.fxSelDebug = ({})
    // Every effect starts where the copied text was (config anchor "selection", the default; "cursor" skips the detection).
    var wantSel = eff && (eff.selection || (root.config.anchor === "selection" && !nt && !root.testing))
    var usePref = wantSel && eff && eff.selection !== false && root.config.anchor === "selection"
    var yk = wantSel && root.yankFresh(root.pendingText) ? root.yank : null
    // The copied text is not the text of the last selection we know (a copy button / menu, OR the selection is still being made with the mouse held
    // and the app has not updated its primary selection yet): look for a FRESH highlight right at the mouse (narrow search, no remembered position,
    // never the stale selection itself). Nothing new there = cursor mode: the effect plays right next to the mouse.
    // The primary selection changed only just before this clipboard event and was not being dragged out (no earlier, different text in the last second):
    // it is the side effect of a copy button, not a selection - nothing to anchor on, play at the mouse.
    var sideEffect = false
    if (wantSel && !yk && root.selPos && !root.recentIntent() && Date.now() - root.selPos.at < 250) {
      var st0 = Logic.sanitize(root.selPos.text, 0)
      sideEffect = !root.primaryHist.some(function(h) { return h.text !== st0 && root.selPos.at - h.at < 1000 && h.at < root.selPos.at })
    }
    // The same text as an earlier copy-button / menu copy (a link address copied again): still no selection on screen, unless the copy key was pressed.
    if (!sideEffect && wantSel && !yk && root.selPos && root.selPos.side && !root.recentIntent() && !root.cacheMatches(root.pendingText) && Logic.sameSelection(root.selPos.text, root.pendingText)) sideEffect = true
    // ...unless it re-asserts a selection we already knew (Ctrl+C in Chromium: same words, hidden bits like citation marks left out): then that
    // earlier selection and its detection are the ones to use.
    var knownSel = sideEffect ? root.historyFor(root.pendingText) : null
    if (sideEffect && knownSel) {
      root.lap("the primary event re-asserts an earlier selection: using its detection")
      sideEffect = false
      selDetectTimer.stop()
      cacheSel.running = false
      root.selDetecting = false
      root.selCache = knownSel
    }
    // A link copied from the right-click menu has no highlight: its text sits where the right-click was, so the effect is played on that.
    var rc = root.rcPos
    var linkCopy = wantSel && !yk && !!rc && !rc.used && Date.now() - rc.at < 20000 && !root.recentIntent() && Logic.looksLikeLink(root.pendingText) && !knownSel && !nt
                   && (sideEffect || (!root.cacheMatches(root.pendingText) && !(root.selPos && Logic.sameSelection(root.selPos.text, root.pendingText))))
    if (linkCopy) {
      rc.used = true
      if (root.selPos && sideEffect) root.selPos.side = true
      root.lap("link copy: looking for the link text where it was right-clicked")
      selDetectTimer.stop()
      root.selCache = null
      root.sampProbe = false
      root.sampWant = true
      root.sampIdx = 0
      root.sampAttempts = [{ x: rc.x, y: rc.y, win: rc.win, link: true }]
      if (root.playing) {
        root.playing = false
        fxLoader.setSource("", {})
        shotTimer.restart()
      } else {
        root.sampRun()
      }
      return
    }
    if (sideEffect) {
      if (root.selPos) root.selPos.side = true
      root.lap("cursor mode: the primary selection changed together with the clipboard (a copy button), not a selection")
      selDetectTimer.stop()
      root.selCache = null
      root.start()
      return
    }
    var probe = wantSel && !yk && !!root.selPos && !Logic.sameSelection(root.selPos.text, root.pendingText)
    root.sampProbe = probe
    root.sampStale = probe && root.selCache ? root.selCache.result.rects : []
    var rest = function() {
    if (wantSel && !yk && !probe) {
        // The selection was made just now and its detection has not finished (or not even started: it is debounced ~120 ms): wait for it instead of
        // detecting a second time from scratch after the copy.
        var pendingSel = (root.selDetecting || selDetectTimer.running) && root.selPos && Logic.sameSelection(root.selPos.text, root.pendingText)
        if (pendingSel && !root.playing && !root.testing) {
          root.lap("waiting for the selection detection that is under way")
          root.cacheWaiter = function() {
            cacheWaitTimer.stop()
            var c2 = root.selCache
            if (c2 && Logic.sameSelection(c2.text, root.pendingText)) { root.lap("selection detected (waited)"); root.applySample(c2.result) }
            root.start()
          }
          cacheWaitTimer.restart()
          if (!root.selDetecting) { selDetectTimer.stop(); root.detectSelection() }
          return
        }
      }
      if (usePref && !yk && !probe && (root.prefBusy && Date.now() - root.prefStarted < 1500)) {
        // the prefetch is still running: continue when it is done
        root.prefWaiter = function() {
          if (root.prefFresh(x, y)) { console.log("copyfx: selection from prefetch (waited)"); root.applySample(root.pref.result) }
          root.start()
        }
        return
      }
      if (usePref && !yk && !probe && root.prefFresh(x, y)) {
        console.log("copyfx: selection from prefetch,", Date.now() - root.pref.at, "ms old")
        root.applySample(root.pref.result)
        root.pref = null
        root.start()
        return
      }
      if (eff && (eff.sample || wantSel)) {
        // Effects that mimic the source read the screen around the mouse first (~0.1-0.3s).
        // The mouse may have moved away from the selection since it was made: look at the remembered selection position first.
        var sp = root.selPos
        var far = wantSel && sp && Date.now() - sp.at < 300000 && (Math.abs(sp.x - x) > 200 || Math.abs(sp.y - y) > 200)
        var here = { x: x, y: y, win: root.pendingWin }
        root.sampAttempts = yk ? [{ x: x, y: y, win: root.pendingWin, hint: yk.hl }] : probe ? [{ x: x, y: y, win: root.pendingWin, narrow: true }] : far ? [{ x: sp.x, y: sp.y, win: sp.win || [0, 0, 0, 0] }, here] : [here]
      if (root.rejHint && !yk && !probe) root.sampAttempts = [{ x: x, y: y, win: root.pendingWin, hint: root.rejHint }].concat(root.sampAttempts)
      root.rejHint = ""
        root.sampIdx = 0
        root.sampWant = !!wantSel
        if (root.playing) {
          // The screenshot must not show the previous effect (its box/highlight would be "found" as the selection):
          // take it down first and give the compositor a moment to drop the layer.
          root.playing = false
          fxLoader.setSource("", {})
          shotTimer.restart()
        } else {
          root.sampRun()
        }
      } else {
        root.start()
      }
      }
    if (wantSel && !yk && !probe) {
      var cc = root.selCache
      if (cc && Date.now() - cc.at < 300000 && Logic.sameSelection(cc.text, root.pendingText)) {
        // The cache is only a prediction: one small fresh capture confirms that the highlight is still exactly there (same colour under every cached
        // line, not continuing above/below). A stale or cut-off detection is dropped and the selection is looked for again.
        root.lap("selection from the cache: verifying it on screen")
        root.verifyCache(cc, function(ok, why) {
          if (ok) { root.lap("cache verified"); root.applySample(cc.result); root.start() }
          else { root.lap("cache rejected: " + why); console.log("copyfx: cache rejected: " + why); root.selCache = null; root.rejHint = cc.result.bg || ""; rest() }
        })
        return
      }
    }
    rest()
  }

  property var verifyCb: null
  property string rejHint: ""       // the highlight colour of a cache that was rejected: the selection is looked for by that exact colour first (it may have moved: scrolled)
  function verifyCache(cc, cb) {
    var rs = (cc.result.rects || []).map(function(r) { return [r.x, r.y, r.w, r.h].map(Math.round).join(",") }).join(";")
    root.verifyCb = cb
    verifyProc.command = [root.selectionScript, "--verify", cc.result.bg || "#000000", rs]
    verifyProc.running = false
    verifyProc.running = true
    verifyTimeout.restart()
  }
  function verifyDone(ok, why) {
    verifyTimeout.stop()
    var cb = root.verifyCb
    root.verifyCb = null
    if (cb) cb(ok, why)
  }
  Timer { id: verifyTimeout; interval: 1500; onTriggered: root.verifyDone(false, "verification timed out") }
  Process {
    id: verifyProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (!this.text.trim()) return          // a killed run
        var r = { ok: false, why: "no answer" }
        try { r = JSON.parse(this.text) } catch (e) {}
        root.verifyDone(!!r.ok, r.why || "")
      }
    }
  }

  function rememberLook(c, cls, win) {
    if (!c || !c.found || !(c.lineH > 0)) return
    var m = Object.assign({}, root.looks), look = { bg: c.bg || "", fg: c.fg || "", lineH: c.lineH }
    Logic.lookKeys(cls, win).forEach(function(k) { m[k] = look })
    root.looks = m
  }
  function start() {
    root.lap("start: loading the effect")
    var known = null
    if (root.fxSelFound) known = { bg: root.fxSrcBg, fg: root.fxSrcFg, lineH: root.fxSelLineH }
    else Logic.lookKeys(root.pendingCls, root.pendingWin).some(function(k) { known = root.looks[k] || null; return !!known })
    var fb = Logic.fallbackLook(known, root.background, root.foreground, 24)
    root.fxFbPx = fb.px; root.fxFbBg = fb.bg; root.fxFbFg = fb.fg
    if (!root.fxSelFound) root.lap("no selection found: plain panel " + fb.px + "px, " + (fb.matched ? "looks of the last selection in this app" : "shell colours"))
    if (Logic.skipPlay(root.config.fallback, root.config.anchor, root.fxSelFound, root.testing, root.fxIsNotify)) {
      root.lap("no selection found and fallback is off: no effect")
      if (root.infoData) root.showInfo()
      return
    }
    root.playing = true
    if (root.infoData) root.showInfo()
    fxLoader.play()
  }

  Timer {
    id: shotTimer
    interval: 60
    onTriggered: root.sampRun()
  }

  property var sampAttempts: []
  property bool sampProbe: false
  property var sampStale: []
  // does a found highlight (global rects) sit on the stale one (>50% of the smaller area)?
  function overlapsStale(rects) {
    var st = root.sampStale || []
    for (var i = 0; i < (rects || []).length; i++) for (var j = 0; j < st.length; j++) {
      var a = rects[i], b = st[j]
      var w = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x), h = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y)
      if (w > 0 && h > 0 && w * h > 0.5 * Math.min(a.w * a.h, b.w * b.h)) return true
    }
    return false
  }
  property int sampIdx: 0
  property bool sampWant: false
  function sampRun() {
    var a = root.sampAttempts[root.sampIdx]
    sampleProc.command = [root.sampWant ? root.selectionScript : root.sampleScript, String(Math.round(a.x)), String(Math.round(a.y))]
      .concat(a.win.map(function(v) { return String(Math.round(v)) }))
      .concat(root.sampWant ? root.spriteArgs() : [])
      .concat(a.hint ? ["hint=" + a.hint] : [])
      .concat(a.narrow ? ["narrow=1"] : [])
      .concat(a.link ? ["link=1"] : [])
    sampleProc.running = false
    sampleProc.running = true
  }
  function screenAt(x, y) {
    var list = Quickshell.screens
    for (var i = 0; i < list.length; i++) {
      var s = list[i]
      if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) return s
    }
    return null
  }

  // Apply a find-selection / sample-colors result to the effect that is about to play.
  function applySample(c) {
    if (c.bg) root.fxSrcBg = c.bg
    if (c.fg) root.fxSrcFg = c.fg
    if (c.debug && root.fxScreen) {
      var sx = root.fxScreen.x, sy = root.fxScreen.y
      var loc = function(b) { return b ? { x: b[0] - sx, y: b[1] - sy, w: b[2], h: b[3] } : null }
      var d = c.debug
      root.fxSelDebug = { reason: d.reason || "", pass: d.pass || 0, ms: d.ms || 0, hl: d.hl || "", cands: (d.cands || []).length,
                          seedDist: d.seed_dist, region: loc(d.region), block: loc(d.block), window: loc(d.window),
                          mouse: d.mouse ? { x: d.mouse[0] - sx, y: d.mouse[1] - sy } : null,
                          found: c.found === true, fg: c.fg || "" }
    }
    root.rememberLook(c, root.pendingCls, root.pendingWin)
    if (c.found && c.rects && !Logic.plausibleSelection(c.rects, root.pendingText)) {
      console.log("copyfx: rejected " + c.rects.length + " highlight boxes: far too many for " + root.pendingText.length + " copied characters")
      c = Object.assign({}, c, { found: false })
    }
    if (c.found && c.rects) console.log("copyfx: anchored " + JSON.stringify(c.rects.map(function(r) { return [r.x, r.y, r.w, r.h] })))
    if (c.found && c.rects && c.rects.length) {          // the selection can be on another monitor than the mouse now
      var scr = root.screenAt(c.rects[0].x + c.rects[0].w / 2, c.rects[0].y + c.rects[0].h / 2)
      if (scr) root.fxScreen = scr
    }
    if (c.found && c.rects && root.fxScreen) {
      // find-selection reports global layout coordinates; effects work in screen-local ones.
      root.fxSelRects = c.rects.map(function(r) { return { x: r.x - root.fxScreen.x, y: r.y - root.fxScreen.y, w: r.w, h: r.h, il: r.il || 0, ir: r.ir || 0, it: r.it || 0, ib: r.ib || 0, gaps: r.gaps || [] } })
      root.fxSelLineH = c.lineH || 0
      root.fxSelFound = true
      if (c.sprite) root.fxSprite = { url: "file://" + c.sprite.file, x: c.sprite.x - root.fxScreen.x, y: c.sprite.y - root.fxScreen.y, w: c.sprite.w, h: c.sprite.h, rows: c.sprite.rows }
    }
  }

  Process {
    id: sampleProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (!this.text.trim()) return          // a killed run (a newer copy restarted the detection): the run that replaced it reports
        var c = null
        try { c = JSON.parse(this.text) } catch (e) {}
        if (c && root.sampWant && !c.found && root.sampIdx + 1 < root.sampAttempts.length) { root.sampIdx++; root.sampRun(); return }
        if (c && root.sampProbe) {
          if (!c.found || root.overlapsStale(c.rects)) { root.lap("cursor mode: no fresh highlight at the mouse"); c = null }
          else root.lap("fresh highlight at the mouse (selection in progress)")
        }
        if (c) root.applySample(c)
        root.start()
      }
    }
  }

  Process {
    id: rcProc
    command: cursorProc.command
    stdout: StdioCollector {
      onStreamFinished: {
        var p = null
        try { p = JSON.parse(this.text) } catch (e) {}
        if (p) root.rcPos = { x: p.x, y: p.y, win: p.win || [0, 0, 0, 0], at: Date.now(), used: false }
      }
    }
  }

  Process {
    id: cursorProc
    command: ["bash", "-c", "jq -cs '{x: .[0].x, y: .[0].y, cls: (.[1].class // \"\"), win: [(.[1].at[0] // 0), (.[1].at[1] // 0), (.[1].size[0] // 0), (.[1].size[1] // 0)]}' <(hyprctl cursorpos -j) <(hyprctl activewindow -j)"]
    stdout: StdioCollector {
      onStreamFinished: {
        var p = { x: 0, y: 0, cls: "", win: [0, 0, 0, 0] }
        try { p = JSON.parse(this.text) } catch (e) {}
        root.pendingWin = p.win || [0, 0, 0, 0]
        root.cursorKnown(p.x, p.y, p.cls)
      }
    }
  }

  // ---------- Omarchy theme ----------
  // Effects get the current theme's palette (~/.local/state/omarchy/current/theme/colors.toml) so red/green/cyan things follow the theme, and the
  // sprite tint rows are built from it too (find-selection palette=). With config themeColors false they get the classic colours.
  // With config followTheme every theme can have its own effect (shipped defaults in theme-effects.json, yours in <data>/theme-effects.json).
  readonly property string themeStateDir: Quickshell.env("HOME") + "/.local/state/omarchy/current"
  property string themeName: ""
  property var themeParsed: null
  property var themeEffectsDefault: ({})
  property var themeEffectsUser: ({})
  readonly property var effectTheme: root.config.themeColors && root.themeParsed ? root.themeParsed : Logic.classicTheme()
  function spriteArgs() {
    return ["sprites=" + root.spriteDir, "accent=" + root.accent, "palette=" + Logic.paletteArg(root.effectTheme)]
  }
  FileView {
    id: themeNameFile
    path: root.themeStateDir + "/theme.name"
    printErrors: false
    onLoaded: {
      var n = text().replace(/\s+$/, "")
      if (n !== root.themeName) { root.themeName = n; themeColorsFile.reload() }
    }
  }
  FileView {
    id: themeColorsFile
    path: root.themeStateDir + "/theme/colors.toml"
    printErrors: false
    onLoaded: { root.themeParsed = Logic.parseThemeColors(text(), root.themeName); console.log("copyfx: theme colours loaded:", root.themeName, root.themeParsed.red, root.themeParsed.green, root.themeParsed.accent) }
    onLoadFailed: root.themeParsed = null
  }
  Timer { interval: 3000; repeat: true; running: true; onTriggered: themeNameFile.reload() }        // a theme switch replaces the files: poll the tiny name file
  FileView {
    path: root.pluginDir + "/theme-effects.json"
    printErrors: false
    onLoaded: { try { root.themeEffectsDefault = JSON.parse(text()) } catch (e) {} }
  }
  FileView {
    id: themeEffectsUserFile
    path: root.dataDir + "/theme-effects.json"
    atomicWrites: true
    printErrors: false
    onLoaded: { try { root.themeEffectsUser = JSON.parse(text()) } catch (e) {} }
  }
  function themeEffectId() { return Logic.themeEffect(root.themeName, root.themeEffectsUser, root.themeEffectsDefault) }
  // the theme changed (or follow was switched on): use the effect this theme wants
  function applyThemeEffect() {
    if (!root.config.followTheme) return
    var id = root.themeEffectId()
    if (id && root.effects.some(function(e) { return e.id === id }) && root.config.effect !== id) {
      console.log("copyfx: theme", root.themeName, "-> effect", id)
      root.setConfig("effect", id)
      if (root.config.mode === "random") root.setConfig("mode", "selected")
    }
  }
  onThemeNameChanged: root.applyThemeEffect()
  function bindThemeEffect(id) {                       // gallery: Ctrl+T = "this theme uses this effect"
    if (!root.themeName || !id) return
    var m = Object.assign({}, root.themeEffectsUser)
    m[root.themeName] = id
    root.themeEffectsUser = m
    themeEffectsUserFile.setText(JSON.stringify(m, null, 2) + "\n")
    if (!root.config.followTheme) root.setConfig("followTheme", true)
  }
  readonly property string themeText: root.themeName ? ("🎨 " + root.themeName + (root.config.followTheme && root.themeEffectId() ? " → " + root.themeEffectId().replace(/^img-/, "") : "")) : ""

  // ---------- weather ----------
  // The location is the one Omarchy's weather widget already uses (~/.local/state/omarchy/settings/weather.json). The current conditions come
  // from Open-Meteo (no key) every 25 minutes and are cached in the data dir, so effects start with the last known weather at once.
  property var weatherLoc: null
  property var weatherReport: null
  property string weatherOverride: ""          // test/preview: force a situation by name (see Logic.weatherOverrideState)
  property string weatherEffectId: "img-sunrise"
  property string weatherText: ""
  function weatherState() {
    return Logic.weatherOverrideState(Logic.weatherState(root.weatherReport, Date.now(), new Date().getHours()), root.weatherOverride)
  }
  function refreshWeather() {
    var s = root.weatherState()
    root.weatherEffectId = Logic.weatherEffect(s)
    root.weatherText = Logic.weatherLabel(s)
  }
  function resolveEffect(id) { return id === "img-weather" ? Logic.weatherEffect(root.weatherState()) : id }
  onWeatherReportChanged: root.refreshWeather()
  onWeatherOverrideChanged: root.refreshWeather()
  // Open-Meteo is only asked (with the coordinates of Omarchy's weather widget) while a weather effect can actually be played:
  // the gallery is open, random mode is on, or a weather effect is the chosen one.
  readonly property bool weatherWanted: root.testing || root.config.mode === "random" || Logic.isWeatherEffect(root.config.effect)
  onWeatherWantedChanged: if (root.weatherWanted) root.fetchWeather()
  function fetchWeather() {
    var l = root.weatherLoc
    if (!l || !root.weatherWanted) return
    weatherProc.command = ["curl", "-s", "-m", "10", "--max-filesize", "200000", "https://api.open-meteo.com/v1/forecast?latitude=" + l.latitude + "&longitude=" + l.longitude
      + "&current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m,precipitation,cloud_cover&daily=sunrise,sunset&timezone=auto&forecast_days=1"]
    weatherProc.running = false
    weatherProc.running = true
  }
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    printErrors: false
    onLoaded: { root.weatherLoc = Logic.parseWeatherLocation(text()); root.fetchWeather() }
    onLoadFailed: root.weatherLoc = null
  }
  FileView {
    id: weatherCache
    path: root.dataDir + "/weather.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try { var c = JSON.parse(text()); var w = Logic.parseWeather(c.raw, c.at); if (w && !root.weatherReport) root.weatherReport = w } catch (e) {}
    }
  }
  Process {
    id: weatherProc
    stdout: StdioCollector {
      onStreamFinished: {
        var w = Logic.parseWeather(this.text, Date.now())
        if (!w) { console.log("copyfx: weather fetch failed"); return }
        root.weatherReport = w
        weatherCache.setText(JSON.stringify({ at: w.at, raw: this.text }))
        console.log("copyfx: weather", w.kind, w.temp + "°C", "wind", w.wind, "km/h")
      }
    }
  }
  Timer { interval: 1500000; repeat: true; running: true; onTriggered: root.fetchWeather() }

  // ---------- copy watcher ----------
  Process {
    id: watcher
    running: true
    command: ["wl-paste", "--watch", root.clipScript]
    stdout: SplitParser {
      onRead: function(line) {
        if (!root.armed || !root.config.enabled) { console.log("copyfx: ignored copy (" + (root.armed ? "disabled" : "starting up") + ")"); return }
        try {
          var e = JSON.parse(line)
          if (e.type === "text") root.trigger(e.text, "")
          else root.presentObject(e)
        } catch (err) {}
      }
    }
    onRunningChanged: if (running) { root.armed = false; armTimer.restart() }
    onExited: restartTimer.start()
  }
  Timer { id: restartTimer; interval: 2000; onTriggered: watcher.running = true }
  // wl-paste --watch emits the current clipboard once at start; give that (and capture.sh) time to pass.
  Timer { id: armTimer; interval: 3000; onTriggered: root.armed = true }

  // ---------- effect discovery ----------
  Process {
    id: scanProc
    command: ["sh", "-c", "cd \"$1/effects\" 2>/dev/null && for f in */effect.json; do [ -f \"$f\" ] && jq -c --arg id \"${f%%/*}\" '. + {id: $id}' \"$f\"; done; true", "sh", root.effectLocal]
    stdout: StdioCollector {
      onStreamFinished: {
        root.effects = Logic.parseEffects(this.text)
        effectIndexFile.setText(JSON.stringify(root.effects))      // the bar menu reads the effect list from here
      }
    }
  }

  FileView {
    id: effectIndexFile
    path: root.runDir + "/copyfx-effects.json"
    atomicWrites: true
    printErrors: false
  }

  FileView {
    id: configFile
    path: root.configPath
    atomicWrites: true
    printErrors: false
    onLoaded: root.config = Logic.parseConfig(text())
    onLoadFailed: root.config = Logic.parseConfig("")
  }

  // Missing helper programs, found once at start (package names, one per line) and shown in the gallery header.
  property var missingDeps: []
  Process {
    id: depsProc
    command: ["sh", "-c", "for c in wl-paste:wl-clipboard jq:jq hyprctl:hyprland grim:grim curl:curl python3:python; do command -v \"${c%%:*}\" >/dev/null 2>&1 || echo \"${c#*:}\"; done; "
      + "command -v python3 >/dev/null 2>&1 && { python3 -c 'import PIL' 2>/dev/null || echo python-pillow; python3 -c 'import numpy' 2>/dev/null || echo python-numpy; }; "
      + "[ -x \"$1\" ] || echo 'omarchy (clipboard capture.sh)'", "sh", root.clipCaptureScript]
    stdout: StdioCollector {
      onStreamFinished: {
        var m = this.text.split("\n").filter(function(x) { return x !== "" })
        root.missingDeps = m
        if (m.length) console.log("copyfx: missing " + m.join(", ") + "  (install with: omarchy pkg add " + m.filter(function(x) { return x.indexOf(" ") < 0 }).join(" ") + ")")
      }
    }
  }
  readonly property string clipCaptureScript: Quickshell.env("OMARCHY_PATH") ? Quickshell.env("OMARCHY_PATH") + "/shell/plugins/clipboard/capture.sh" : "/usr/share/omarchy/shell/plugins/clipboard/capture.sh"

  Component.onCompleted: {
    depsProc.running = true
    root.refreshWeather()
    Quickshell.execDetached(["mkdir", "-p", root.dataDir])
    scanProc.running = true
  }

  // ---------- info badge ----------
  // A small chip next to the copied text says what it was: a colour (with its swatch), a link, JSON, a number/timestamp, the size of a long copy - or
  // warns when it looks like a secret (API key, token, private key, password). config info: "smart" (default: only when there is something to say),
  // "always" (also counts for plain text), "off". It outlives the effect (which lasts a fraction of a second).
  property var infoData: null
  property bool infoShown: false
  property var infoScreen: null
  property rect infoBox: Qt.rect(0, 0, 0, 0)
  function showInfo() {
    var d = root.infoData
    if (!d || !root.fxScreen) return
    var b = null
    if (root.fxSelFound && root.fxSelRects.length) {
      var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
      root.fxSelRects.forEach(function(r) { x0 = Math.min(x0, r.x); y0 = Math.min(y0, r.y); x1 = Math.max(x1, r.x + r.w); y1 = Math.max(y1, r.y + r.h) })
      b = Qt.rect(x0, y0, x1 - x0, y1 - y0)
    } else b = Qt.rect(root.fxOrigin.x - 20, root.fxOrigin.y - 12, 40, 24)
    root.infoBox = b
    root.infoScreen = root.fxScreen
    root.infoShown = true
    infoTimer.interval = d.level === "warn" ? 2600 : 1800
    infoTimer.restart()
  }
  Timer { id: infoTimer; onTriggered: root.infoShown = false }
  PanelWindow {
    id: infoWindow
    visible: root.infoShown && root.infoScreen !== null
    screen: root.infoScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-copyfx-info"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Rectangle {
      id: badge
      readonly property var d: root.infoData || ({ label: "", level: "info", swatch: "" })
      readonly property bool warn: d.level === "warn"
      readonly property color accentCol: warn ? root.effectTheme.red : root.effectTheme.accent
      readonly property real above: root.infoBox.y - height - 8
      height: 30
      width: row.width + 24
      radius: 15
      x: Math.max(8, Math.min(root.infoBox.x, infoWindow.width - width - 8))
      y: above >= 8 ? above : Math.min(infoWindow.height - height - 8, root.infoBox.y + root.infoBox.height + 8)
      color: Util.alpha(root.background, 0.96)
      border.width: 1.5
      border.color: accentCol
      opacity: root.infoShown ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 220 } }
      Row {
        id: row
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Rectangle {
          visible: !!badge.d.swatch
          width: 16; height: 16; radius: 4; color: badge.d.swatch || "transparent"
          border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.5)
          anchors.verticalCenter: parent.verticalCenter
        }
        Text { textFormat: Text.PlainText;
          visible: badge.warn
          text: "⚠"
          color: badge.accentCol
          font.pixelSize: 15
          anchors.verticalCenter: parent.verticalCenter
        }
        Text { textFormat: Text.PlainText;
          text: badge.d.label
          color: badge.warn ? badge.accentCol : root.effectTheme.fg
          font.family: root.fontFamily
          font.pixelSize: 13
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  // ---------- overlay: plays the effect, click-through ----------
  PanelWindow {
    id: fxWindow
    visible: root.playing && root.fxScreen !== null
    screen: root.fxScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-copyfx"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Loader {
      id: fxLoader
      anchors.fill: parent

      function play() {
        fxLoader.setSource("", {})
        fxLoader.setSource(root.effectBase + "effects/" + root.fxId + "/Effect.qml", {
          text: root.fxText, fg: root.foreground, bg: root.background, accent: root.accent,
          fontFamily: root.fontFamily, fontSize: 24, compact: false,
          srcBg: root.fxSrcBg, srcFg: root.fxSrcFg, srcMono: root.fxMono,
          selFound: root.fxSelFound, selRects: root.fxSelRects, sprite: root.fxSprite, runMs: root.config.durationMs, weather: root.weatherState(), theme: root.effectTheme, selLineH: root.fxSelLineH, selDebug: root.fxSelDebug,
          fbPx: root.fxFbPx, fbBg: root.fxFbBg, fbFg: root.fxFbFg,
          posName: root.fxPos, durationMs: root.fxDurationMs, title: root.fxTitle, level: root.fxLevel, icon: root.fxIcon
        })
      }
      onLoaded: {
        item.origin = root.fxOrigin
        root.lap("effect loaded")
        Qt.callLater(function() { root.lap("effect first frame") })
        item.finished.connect(function() { root.playing = false; fxLoader.setSource("", {}) })
      }
    }
  }

  // ---------- gallery ----------
  PanelWindow {
    id: gallery
    visible: root.galleryOpen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-copyfx-gallery"
    WlrLayershell.layer: WlrLayer.Overlay
    // No scrim and no full-screen grab: only the card takes input, everything else stays usable, so an effect can be
    // tried right away (copy something elsewhere). The card gets the keyboard once clicked.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { x: card.x; y: card.y; width: card.width; height: card.height }
    exclusionMode: ExclusionMode.Ignore


    BorderSurface {
      id: card
      width: Math.min(Style.space(1000), gallery.width - Style.gapsOut * 2)
      height: Math.min(Style.space(720), gallery.height - Style.gapsOut * 2)
      radius: Style.cornerRadius
      // Dragged by the header (offset from the centre, clamped to the screen, remembered in config.json as galleryPos).
      property var dragPos: null
      readonly property var offset: Logic.clampGalleryPos(card.dragPos || root.config.galleryPos, gallery.width, gallery.height, card.width, card.height)
      x: Math.round((gallery.width - width) / 2 + offset.x)
      y: Math.round((gallery.height - height) / 2 + offset.y)
      color: root.background
      borderSpec: root.borderSpec
      padding: Style.spacing.panelPadding

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        anchors.margins: Style.spacing.md
        focus: true

        Connections { target: root; function onQueryChanged() { root.cursorIndex = 0; flick.contentY = 0 } }
        // Shared by the card area and the search box: navigation keys, Enter, Tab; Esc clears the search first.
        function handleKey(event) {
          var n = root.shown.length, cols = Math.max(1, grid.columns)
          if (false) return false
          else if (event.key === Qt.Key_Escape) { if (root.query !== "") root.query = ""; else root.close() }
          else if (event.key === Qt.Key_Left) root.cursorIndex = Math.max(0, root.cursorIndex - 1)
          else if (event.key === Qt.Key_Right) root.cursorIndex = Math.min(n - 1, root.cursorIndex + 1)
          else if (event.key === Qt.Key_Up) root.cursorIndex = Math.max(0, root.cursorIndex - cols)
          else if (event.key === Qt.Key_Down) root.cursorIndex = Math.min(n - 1, root.cursorIndex + cols)
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.choose(root.cursorIndex)
            root.trigger("Copied to clipboard", root.shown[root.cursorIndex] ? root.shown[root.cursorIndex].id : "")
          } else if (event.key === Qt.Key_Tab) {
            var order = ["M", "IMG", "S", "L", "XL"].filter(function(z) { return root.presentSizes.indexOf(z) >= 0 })
            var cur = root.chipSizes.length ? order.indexOf(root.chipSizes[0]) : -1
            var nxt = order[(cur + 1) % order.length]
            root.setConfig("sizes", [nxt])   // Tab cycles through the groups one at a time
            root.cursorIndex = 0
            flick.contentY = 0
          } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_R) root.setConfig("mode", root.config.mode === "random" ? "selected" : "random")
          else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_T) root.bindThemeEffect(root.shown[root.cursorIndex] ? root.shown[root.cursorIndex].id : "")
          else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) { root.setConfig("followTheme", !root.config.followTheme); root.applyThemeEffect() }
          else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_I) root.setConfig("info", root.config.info === "smart" ? "always" : root.config.info === "always" ? "off" : "smart")
          else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) root.setConfig("enabled", !root.config.enabled)
          else return false
          event.accepted = true
          return true
        }
        Keys.onPressed: function(event) { if (!handleKey(event) && event.text.length === 1 && event.text >= " ") { searchField.forceActiveFocus(); root.query += event.text; event.accepted = true } }

        // Drag the gallery by its header (the empty parts and the title); double-click puts it back in the centre.
        MouseArea {
          id: dragArea
          x: 0; y: 0
          width: parent.width
          height: galleryHeader.height
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeAllCursor
          property point grab: Qt.point(0, 0)
          property point startOffset: Qt.point(0, 0)
          onPressed: function(m) {
            var g = dragArea.mapToItem(gallery.contentItem, m.x, m.y)
            grab = Qt.point(g.x, g.y)
            startOffset = Qt.point(card.offset.x, card.offset.y)
          }
          onPositionChanged: function(m) {
            if (!pressed) return
            var g = dragArea.mapToItem(gallery.contentItem, m.x, m.y)
            card.dragPos = Logic.clampGalleryPos({ x: startOffset.x + g.x - grab.x, y: startOffset.y + g.y - grab.y }, gallery.width, gallery.height, card.width, card.height)
          }
          onReleased: { if (card.dragPos) { root.setConfig("galleryPos", card.dragPos); card.dragPos = null } }
          onDoubleClicked: { card.dragPos = null; root.setConfig("galleryPos", { x: 0, y: 0 }) }
        }

        Column {
          anchors.fill: parent
          spacing: Style.spacing.md

          Row {
            id: galleryHeader
            width: parent.width
            spacing: Style.spacing.md
            Text { textFormat: Text.PlainText;
              text: "CopyFX"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Item { width: 1; height: 1 }
            Text { textFormat: Text.PlainText;
              anchors.verticalCenter: parent.verticalCenter
              text: root.missingDeps.length ? "missing: " + root.missingDeps.join(", ") + "  (omarchy pkg add ...)"
                : (root.config.enabled ? "on" : "OFF") + "  ·  " + (root.config.mode === "random" ? "random effect" : "selected effect") + "  ·  " + root.weatherText + (root.themeText ? "  ·  " + root.themeText : "")
              color: root.missingDeps.length ? "#ff6b6b" : Util.alpha(root.foreground, 0.7)
              font.family: root.fontFamily
              font.pixelSize: 13
            }
            Item { width: Style.spacing.md; height: 1 }
            Text { textFormat: Text.PlainText;
              anchors.verticalCenter: parent.verticalCenter
              text: "Animation"
              color: Util.alpha(root.foreground, 0.7)
              font.family: root.fontFamily
              font.pixelSize: 13
            }
            Rectangle {
              width: 64; height: 26; radius: 13
              color: "transparent"
              border.width: 1
              border.color: durField.activeFocus ? root.accent : Util.alpha(root.foreground, 0.3)
              TextInput {
                id: durField
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 1; top: 5000 }
                color: root.foreground
                selectionColor: root.accent
                font.family: root.fontFamily
                font.pixelSize: 13
                text: String(root.config.durationMs)
                Connections { target: root; function onConfigChanged() { if (!durField.activeFocus) durField.text = String(root.config.durationMs) } }
                function commit() {
                  var v = parseInt(text)
                  if (isNaN(v)) { text = String(root.config.durationMs); return false }
                  v = Math.max(30, Math.min(5000, v))
                  text = String(v)
                  if (v !== root.config.durationMs) root.setConfig("durationMs", v)
                  return true
                }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (commit()) root.trigger("Copied to clipboard", root.shown[root.cursorIndex] ? root.shown[root.cursorIndex].id : "")   // play it once with the new length
                    searchField.forceActiveFocus()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Escape) {
                    text = String(root.config.durationMs)
                    searchField.forceActiveFocus()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Tab) {
                    commit()
                    searchField.forceActiveFocus()
                    event.accepted = true
                  }
                }
                onEditingFinished: commit()
              }
            }
            Text { textFormat: Text.PlainText;
              anchors.verticalCenter: parent.verticalCenter
              text: "ms"
              color: Util.alpha(root.foreground, 0.7)
              font.family: root.fontFamily
              font.pixelSize: 13
            }
          }

          Row {
            id: filterRow
            spacing: Style.spacing.sm
            Rectangle {
              width: 240; height: 26; radius: 13
              color: "transparent"
              border.width: 1
              border.color: searchField.activeFocus ? root.accent : Util.alpha(root.foreground, 0.3)
              TextInput {
                id: searchField
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 26
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: root.foreground
                selectionColor: root.accent
                font.family: root.fontFamily
                font.pixelSize: 13
                onTextChanged: if (text !== root.query) root.query = text
                Connections { target: root; function onQueryChanged() { if (searchField.text !== root.query) searchField.text = root.query } }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) { keyCatcher.handleKey(event) }
                Text { textFormat: Text.PlainText;
                  visible: searchField.text === ""
                  anchors.verticalCenter: parent.verticalCenter
                  text: "search by name…"
                  color: Util.alpha(root.foreground, 0.4)
                  font: searchField.font
                }
              }
              Text { textFormat: Text.PlainText;
                visible: root.query !== ""
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: Util.alpha(root.foreground, 0.6)
                font.pixelSize: 12
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: { root.query = ""; searchField.forceActiveFocus() } }
              }
            }
            Text { textFormat: Text.PlainText;
              anchors.verticalCenter: parent.verticalCenter
              text: "Size"
              color: Util.alpha(root.foreground, 0.7)
              font.family: root.fontFamily
              font.pixelSize: 13
            }
            Repeater {
              model: ["M", "IMG", "S", "L", "XL"].filter(function(z) { return root.presentSizes.indexOf(z) >= 0 })
              delegate: Rectangle {
                id: chip
                required property string modelData
                readonly property bool on: root.chipSizes.indexOf(modelData) >= 0
                readonly property bool locked: false
                readonly property int count: root.effects.filter(function(e) { return e.size === modelData }).length
                width: chipText.width + 22
                height: 26
                radius: 13
                color: on ? Util.alpha(root.accent, 0.28) : "transparent"
                border.width: 1
                border.color: on ? root.accent : Util.alpha(root.foreground, 0.3)
                Text { textFormat: Text.PlainText;
                  id: chipText
                  anchors.centerIn: parent
                  text: ({ "S": "S", "M": "On text", "IMG": "By image", "L": "L", "XL": "XXL" })[chip.modelData] + "  " + chip.count
                  color: chip.on ? root.accent : Util.alpha(root.foreground, 0.75)
                  font.family: root.fontFamily
                  font.pixelSize: 12
                  font.bold: chip.on
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: chip.locked ? Qt.ArrowCursor : Qt.PointingHandCursor
                  onClicked: root.toggleSizeChip(chip.modelData)
                }
              }
            }
          }

          Flickable {
            id: flick
            width: parent.width
            height: keyCatcher.height - galleryHeader.height - filterRow.height - hints.height - Style.spacing.md * 3
            contentWidth: width
            contentHeight: grid.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            // A visible themed scrollbar (Omarchy's own panels use the plain Qt one).
            ScrollBar.vertical: ScrollBar {
              id: vbar
              policy: flick.contentHeight > flick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
              interactive: true
              width: 10
              contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Util.alpha(root.foreground, vbar.pressed ? 0.75 : vbar.hovered ? 0.55 : 0.35)
              }
              background: Rectangle { radius: 3; color: Util.alpha(root.foreground, 0.07) }
            }
            // Qt's default wheel step is small (the same in every Omarchy panel): 1 notch = ~150px here.
            WheelHandler {
              acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
              onWheel: function(event) {
                var d = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 1.25
                flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY - d))
              }
            }

            // keep the card under the keyboard cursor in view
            function ensureVisible(idx) {
              var cols = Math.max(1, grid.columns), row = Math.floor(idx / cols)
              var top = row * (210 + grid.spacing), bottom = top + 210
              if (top < contentY) contentY = top
              else if (bottom > contentY + height) contentY = bottom - height
            }
            Connections { target: root; function onCursorIndexChanged() { flick.ensureVisible(root.cursorIndex) } }
            Connections { target: root; function onGalleryOpenChanged() { if (root.galleryOpen) flick.ensureVisible(root.cursorIndex) } }

          Flow {
            id: grid
            width: flick.width - 12
            spacing: Style.spacing.md
            readonly property int columns: Math.max(1, Math.floor((width + spacing) / (280 + spacing)))

            Repeater {
              model: root.shown
              delegate: PreviewCard {
                required property int index
                required property var modelData
                effect: modelData
                base: root.effectBase
                theme: root.effectTheme
                resolved: modelData.id === "img-weather" ? root.weatherEffectId : modelData.id
                current: root.cursorIndex === index
                chosen: root.config.mode === "selected" && root.config.effect === modelData.id
                fg: root.foreground
                bg: root.background
                accent: root.accent
                fontFamily: root.fontFamily
                galleryOpen: root.galleryOpen
                // click: choose this effect and play it right now, gallery stays open
                onClicked: {
                  root.cursorIndex = index
                  root.choose(index)
                  root.trigger("Copied to clipboard", modelData.id)
                }
                // double-click: keep this effect and close the gallery
                onDoubleClicked: {
                  root.cursorIndex = index
                  root.choose(index)
                  root.close()
                }
              }
            }
          }
          }

          Text { textFormat: Text.PlainText;
            id: hints
            width: parent.width
            wrapMode: Text.WordWrap
            text: "←→↑↓ move   Enter/click choose + play   double-click choose + close   type to search   Tab next group   click the ms box to set the animation length   Ctrl+R random on/off   Ctrl+E enable/disable   Ctrl+T use this effect for the theme   Ctrl+F follow theme   Ctrl+I info badge (smart/always/off)   wheel scrolls   drag the title bar to move the gallery (double-click it to re-centre)   Esc close"
            color: Util.alpha(root.foreground, 0.55)
            font.family: root.fontFamily
            font.pixelSize: 12
          }
        }
      }
    }
  }

  Timer {
    id: playTest
    interval: 300
    onTriggered: root.trigger("Copied to clipboard", "")
  }
}

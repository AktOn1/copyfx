.pragma library

// Pure CopyFX logic (no Qt imports, so it runs under node too).

// Collapse whitespace and cap the length so long copies stay readable.
function sanitize(text, maxChars) {
  var s = String(text === undefined || text === null ? "" : text).replace(/\s+/g, " ").trim()
  var max = maxChars > 1 ? maxChars : 0     // 0 = no limit
  if (max && s.length > max) s = s.slice(0, max - 1).replace(/\s+$/, "") + "…"
  return s
}

// One JSON object per line (jq -c output) -> sorted effect list; bad lines are skipped.
function parseEffects(raw) {
  var out = []
  String(raw || "").split(/\r?\n/).forEach(function(line) {
    line = line.trim()
    if (!line) return
    try {
      var e = JSON.parse(line)
      if (e && e.id) out.push({
        id: String(e.id),
        name: String(e.name || e.id),
        description: String(e.description || ""),
        anchor: String(e.anchor || "bottom"),
        duration: Number(e.duration) || 2000,
        maxChars: Number(e.maxChars) > 1 ? Math.floor(Number(e.maxChars)) : 0,   // 0 = unlimited
        sample: e.sample === true,                                                // needs source colours
        selection: e.selection === true,                                          // needs the selection's screen rects
        debug: e.debug === true,                                                  // dev tool: never picked in random mode
        xxl: e.xxl === true || String(e.size) === "XL",                        // big showpiece: not picked in random mode
        size: ["S", "M", "IMG", "L", "XL"].indexOf(String(e.size)) >= 0 ? String(e.size) : (e.xxl ? "XL" : "S"),
        tags: Array.isArray(e.tags) ? e.tags.map(String) : []
      })
    } catch (err) {}
  })
  out.sort(function(a, b) { return a.id < b.id ? -1 : a.id > b.id ? 1 : 0 })
  return out
}

// mode "random": any effect except the last one (when there is a choice); otherwise the selected one.
function pickEffect(effects, mode, selected, last, rnd) {
  if (!effects.length) return ""
  var ids = effects.map(function(e) { return e.id })
  if (mode === "random") {
    var real = effects.filter(function(e) { return !e.debug && !e.xxl }).map(function(e) { return e.id })
    if (real.length) ids = real
    var pool = ids.length > 1 ? ids.filter(function(id) { return id !== last }) : ids
    return pool[Math.floor((rnd === undefined ? Math.random() : rnd) * pool.length) % pool.length]
  }
  return ids.indexOf(selected) >= 0 ? selected : ids[0]
}

// True when the app that was focused at copy time is on the ignore list (case-insensitive exact class).
function isIgnored(cls, keyOnlyClasses) {
  var c = String(cls || "").toLowerCase()
  return !!c && (keyOnlyClasses || []).some(function(x) { return String(x).toLowerCase() === c })
}

// Text limit for one play: the lower of the config limit and the effect's own limit (0 = none).
function textLimit(configMax, effectMax) {
  var a = configMax > 1 ? configMax : 0, b = effectMax > 1 ? effectMax : 0
  return a && b ? Math.min(a, b) : (a || b)
}

// Windows whose text is monospace (terminals, editors, the agent) - used to pick a font for the source look.
function isMonoClass(cls) {
  return /(terminal|ghostty|alacritty|kitty|foot|wezterm|konsole|xterm|tilix|agent|nvim|vim|code|zed)/i.test(String(cls || ""))
}

function parseConfig(raw) {
  var c = { enabled: true, mode: "selected", effect: "frame", maxChars: 0, keyOnlyClasses: [], sizes: ["M"], anchor: "selection", durationMs: 200, themeColors: true, followTheme: false, info: "off", fallback: "off", devReload: false }
  try {
    var j = JSON.parse(raw)
    if (Array.isArray(j.keyOnlyClasses)) c.keyOnlyClasses = j.keyOnlyClasses.map(String)
    if (Array.isArray(j.sizes) && j.sizes.length) c.sizes = j.sizes.map(String)
    if (j.anchor === "cursor" || j.anchor === "selection") c.anchor = j.anchor
    if (typeof j.themeColors === "boolean") c.themeColors = j.themeColors
    if (typeof j.followTheme === "boolean") c.followTheme = j.followTheme
    if (typeof j.devReload === "boolean") c.devReload = j.devReload
    if (j.fallback === "panel" || j.fallback === "off") c.fallback = j.fallback
    if (j.info === "smart" || j.info === "always" || j.info === "off") c.info = j.info
    if (Number(j.durationMs) > 0) c.durationMs = Math.max(30, Math.min(5000, Math.round(Number(j.durationMs))))
    if (typeof j.enabled === "boolean") c.enabled = j.enabled
    if (j.mode === "random" || j.mode === "selected") c.mode = j.mode
    if (typeof j.effect === "string") c.effect = j.effect
    if (j.maxChars >= 0) c.maxChars = Math.floor(j.maxChars)
    if (j.galleryPos && isFinite(Number(j.galleryPos.x)) && isFinite(Number(j.galleryPos.y))) c.galleryPos = { x: Math.round(Number(j.galleryPos.x)), y: Math.round(Number(j.galleryPos.y)) }
  } catch (err) {}
  return c
}

// Gallery position as an offset from the screen centre, clamped so the whole card stays on screen (screen or card size changes, other monitor).
function clampGalleryPos(pos, screenW, screenH, cardW, cardH) {
  var mx = Math.max(0, (screenW - cardW) / 2), my = Math.max(0, (screenH - cardH) / 2)
  var x = pos && isFinite(Number(pos.x)) ? Number(pos.x) : 0, y = pos && isFinite(Number(pos.y)) ? Number(pos.y) : 0
  return { x: Math.round(Math.max(-mx, Math.min(mx, x))), y: Math.round(Math.max(-my, Math.min(my, y))) }
}

// Sizes shown in the gallery: the chosen ones that exist; nothing chosen = everything.
function visibleSizes(chosen, present) {
  var order = ["M", "IMG", "S", "L", "XL"], pres = order.filter(function(z) { return present.indexOf(z) >= 0 })
  var sel = pres.filter(function(z) { return (chosen || []).indexOf(z) >= 0 })
  return sel.length ? sel : pres
}
// Chips that are switched on (explicitly chosen).
function chosenSizes(chosen, present) {
  return (chosen || []).filter(function(z) { return present.indexOf(z) >= 0 })
}
function toggleSize(chosen, size, present) {
  var cur = chosenSizes(chosen, present), i = cur.indexOf(size)
  if (i >= 0) cur.splice(i, 1); else cur.push(size)
  return cur
}

// Gallery search: every word of the query must appear in the effect's name or id (case-insensitive); words starting with # match its tags.
function matchesQuery(e, q) {
  var words = String(q || "").toLowerCase().split(/\s+/).filter(function(w) { return w })
  if (!words.length) return true
  var hay = (e.name + " " + e.id).toLowerCase(), tags = (e.tags || []).map(function(t) { return String(t).toLowerCase() })
  // "#nerdy" matches the effect's style/kind tags, anything else its name or id
  return words.every(function(w) {
    if (w.charAt(0) === "#") return w.length === 1 || tags.some(function(t) { return t.indexOf(w.slice(1)) >= 0 })
    return hay.indexOf(w) >= 0
  })
}


// ---------- weather ----------
// Omarchy's weather widget keeps the location in ~/.local/state/omarchy/settings/weather.json: {"name","latitude","longitude"}.
function parseWeatherLocation(raw) {
  try {
    var d = JSON.parse(String(raw || ""))
    var lat = parseFloat(d.latitude), lon = parseFloat(d.longitude)
    if (isNaN(lat) || isNaN(lon)) return null
    return { name: typeof d.name === "string" ? d.name : "", latitude: lat, longitude: lon }
  } catch (e) { return null }
}

// WMO weather code (Open-Meteo) -> a kind the effects understand.
function weatherKind(code) {
  var c = Number(code)
  if (c === 0 || c === 1) return "clear"
  if (c === 2) return "partly"
  if (c === 3) return "cloudy"
  if (c === 45 || c === 48) return "fog"
  if (c >= 51 && c <= 57) return "drizzle"
  if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return "rain"
  if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow"
  if (c >= 95) return "thunder"
  return "clear"
}

function minutesOf(s) {          // "2026-09-25T06:52" -> 412
  var m = /T(\d\d):(\d\d)/.exec(String(s || ""))
  return m ? Number(m[1]) * 60 + Number(m[2]) : -1
}

// Open-Meteo forecast response (current + daily sunrise/sunset, timezone=auto) -> a compact report; null when unusable.
function parseWeather(raw, at) {
  try {
    var d = JSON.parse(String(raw || ""))
    var c = d.current
    if (!c || c.weather_code === undefined) return null
    return {
      at: at || 0, code: Number(c.weather_code), kind: weatherKind(c.weather_code),
      temp: Number(c.temperature_2m), wind: Number(c.wind_speed_10m) || 0, dir: Number(c.wind_direction_10m) || 0,
      precip: Number(c.precipitation) || 0, cloud: Number(c.cloud_cover) || 0,
      nowMin: minutesOf(c.time), sunrise: minutesOf(d.daily && d.daily.sunrise && d.daily.sunrise[0]), sunset: minutesOf(d.daily && d.daily.sunset && d.daily.sunset[0])
    }
  } catch (e) { return null }
}

// What effects see: the report brought forward to `nowMs`, with day/night and golden hour (within 40 min of sunrise/sunset) worked out.
// No report (offline / no location yet): clear weather, day between 07:00 and 19:00 local time.
function weatherState(w, nowMs, localHour) {
  var base = { kind: "clear", isDay: true, golden: false, temp: 15, wind: 8, dir: 250, precip: 0, cloud: 20 }
  if (!w) { var h = localHour === undefined ? 12 : localHour; base.isDay = h >= 7 && h < 19; return base }
  var min = w.nowMin >= 0 ? ((w.nowMin + Math.floor((nowMs - w.at) / 60000)) % 1440 + 1440) % 1440 : -1
  var haveSun = min >= 0 && w.sunrise >= 0 && w.sunset >= 0
  return {
    kind: w.kind, isDay: haveSun ? (min >= w.sunrise && min < w.sunset) : true,
    golden: haveSun && (Math.abs(min - w.sunrise) <= 40 || Math.abs(min - w.sunset) <= 40),
    temp: w.temp, wind: w.wind, dir: w.dir, precip: w.precip, cloud: w.cloud
  }
}

// The concrete effect the meta effect "img-weather" plays for a weather state.
var WEATHER_EFFECTS = ["img-weather", "img-wind", "img-thunder", "img-snow", "img-rain", "img-fog", "img-night", "img-sunrise", "img-clouds", "img-heat", "img-frost"]
function isWeatherEffect(id) { return WEATHER_EFFECTS.indexOf(String(id || "")) >= 0 }

function weatherEffect(s) {
  if (s.wind >= 38) return "img-wind"
  if (s.kind === "thunder") return "img-thunder"
  if (s.kind === "snow") return "img-snow"
  if (s.kind === "rain" || s.kind === "drizzle") return "img-rain"
  if (s.kind === "fog") return "img-fog"
  if (!s.isDay) return "img-night"
  if (s.golden) return "img-sunrise"
  if (s.kind === "cloudy" || s.kind === "partly") return "img-clouds"
  if (s.temp >= 28) return "img-heat"
  if (s.temp <= -2) return "img-frost"
  return "img-sunrise"
}

// Test/preview override: force a weather situation by name on top of the real one.
function weatherOverrideState(base, name) {
  var s = JSON.parse(JSON.stringify(base)), n = String(name || "")
  if (!n) return s
  s.golden = false
  switch (n) {
    case "rain": s.kind = "rain"; s.precip = 2; break
    case "drizzle": s.kind = "drizzle"; s.precip = 0.4; break
    case "snow": s.kind = "snow"; s.temp = -2; break
    case "fog": s.kind = "fog"; break
    case "thunder": s.kind = "thunder"; s.precip = 4; break
    case "wind": s.kind = "clear"; s.wind = 48; break
    case "night": s.kind = "clear"; s.isDay = false; break
    case "heat": s.kind = "clear"; s.isDay = true; s.temp = 34; break
    case "frost": s.kind = "clear"; s.isDay = true; s.temp = -9; break
    case "clouds": s.kind = "cloudy"; s.isDay = true; s.cloud = 90; break
    case "sun": s.kind = "clear"; s.isDay = true; s.temp = 18; break
    case "golden": s.kind = "clear"; s.isDay = true; s.golden = true; break
  }
  return s
}

// One-line summary for the gallery header.
function weatherLabel(s) {
  var icon = { clear: s.isDay ? "☀" : "☾", partly: "⛅", cloudy: "☁", fog: "〰", drizzle: "☂", rain: "☂", snow: "❄", thunder: "⚡" }[s.kind] || "☀"
  return icon + " " + s.kind + " " + Math.round(s.temp) + "°"
}


// ---------- Omarchy theme ----------
// The colours effects use for named things (red flash, green terminal, cyan hologram ...). Used when the theme colours are off or unreadable.
function classicTheme() {
  return { name: "", mode: "dark", red: "#ff5c57", orange: "#ff9f1c", yellow: "#ffd166", green: "#5af78e", cyan: "#00e5ff", blue: "#3aa0ff",
           magenta: "#ff3dcb", accent: "#f19d88", fg: "#e6e6e6", bg: "#14161a", muted: "#8b949e" }
}

// ~/.local/state/omarchy/current/theme/colors.toml -> the same shape as classicTheme (missing keys keep the classic colour).
function parseThemeColors(raw, name) {
  var t = classicTheme(), map = { foreground: "fg", background: "bg" }
  String(raw || "").split(/\r?\n/).forEach(function(line) {
    var m = /^\s*([A-Za-z0-9_-]+)\s*=\s*["']([^"']+)["']/.exec(line)
    if (!m) return
    var k = map[m[1]] || m[1], v = m[2]
    if (k === "mode") t.mode = v
    else if (/^#[0-9a-fA-F]{6}$/.test(v) && ["red", "orange", "yellow", "green", "cyan", "blue", "magenta", "accent", "fg", "bg", "muted"].indexOf(k) >= 0) t[k] = v
  })
  t.name = String(name || "")
  return t
}

// Effect the theme wants (user mapping first, then the shipped defaults); "" = none.
function themeEffect(name, userMap, defaultMap) {
  var n = String(name || "")
  return (userMap && userMap[n]) || (defaultMap && defaultMap[n]) || ""
}

// The comma list handed to find-selection (palette=): the named colours the sprite's tint rows are built from.
function paletteArg(t) {
  return [t.red, t.orange, t.yellow, t.green, t.cyan, t.blue, t.magenta, t.fg].join(",")
}


// ---------- what was copied: the info badge ----------
function shannon(s) {
  var f = {}, n = s.length, h = 0
  for (var i = 0; i < n; i++) f[s.charAt(i)] = (f[s.charAt(i)] || 0) + 1
  for (var k in f) { var p = f[k] / n; h -= p * Math.log(p) / Math.LN2 }
  return h
}

function hslToHex(h, s, l) {
  s /= 100; l /= 100
  var a = s * Math.min(l, 1 - l)
  var f = function(n) { var k = (n + h / 30) % 12, c = l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)); return ("0" + Math.round(255 * c).toString(16)).slice(-2) }
  return "#" + f(0) + f(8) + f(4)
}

var SECRET_PATTERNS = [
  [/^gh[pousr]_[A-Za-z0-9]{30,}$/, "GitHub token"], [/^github_pat_[A-Za-z0-9_]{40,}$/, "GitHub token"],
  [/AKIA[0-9A-Z]{16}/, "AWS access key"], [/xox[abprs]-[A-Za-z0-9-]{10,}/, "Slack token"],
  [/^sk-ant-[A-Za-z0-9_-]{20,}$/, "Anthropic API key"], [/^sk-(proj-)?[A-Za-z0-9_-]{32,}$/, "API key"],
  [/^[sr]k_(live|test)_[A-Za-z0-9]{16,}$/, "Stripe key"], [/^AIza[0-9A-Za-z_-]{35}$/, "Google API key"],
  [/^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*$/, "JWT"], [/-----BEGIN [A-Z ]*PRIVATE KEY-----/, "private key"]
]

// Looks at the RAW copied text and says what it is: { kind, label, level: "info"|"warn", swatch? } or null when it is plain text.
// mode "smart" (default) and "always" now behave the same: the line/word/char count chip was removed in v5.
function classifyText(raw, mode) {
  var text = String(raw === undefined || raw === null ? "" : raw)
  var t = text.replace(/^\s+|\s+$/g, ""), m
  if (!t) return null
  var lines = t.split(/\r?\n/).length, single = lines === 1
  for (var i = 0; i < SECRET_PATTERNS.length; i++)
    if (SECRET_PATTERNS[i][0].test(t)) return { kind: "secret", level: "warn", label: "Looks like a secret: " + SECRET_PATTERNS[i][1] + " (" + t.length + " chars)" }
  if (single && t.length >= 20 && !/\s/.test(t) && shannon(t) >= 3.9 && /[a-z]/.test(t) && /[A-Z0-9]/.test(t) && /[0-9_\-+\/=]/.test(t) && !/^[a-z]+:\/\//i.test(t))
    return { kind: "secret", level: "warn", label: "Looks like a secret or password (" + t.length + " chars)" }
  if (single && (m = /^#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.exec(t))) {
    var h = m[1].length <= 4 ? m[1].split("").map(function(c) { return c + c }).join("") : m[1]
    var r = parseInt(h.slice(0, 2), 16), g = parseInt(h.slice(2, 4), 16), b = parseInt(h.slice(4, 6), 16)
    return { kind: "color", level: "info", swatch: "#" + h.slice(0, 6), label: "#" + h + "   rgb(" + r + ", " + g + ", " + b + ")" }
  }
  if (single && (m = /^rgba?\(\s*(\d{1,3})\s*[, ]\s*(\d{1,3})\s*[, ]\s*(\d{1,3})/i.exec(t))) {
    var hx = [m[1], m[2], m[3]].map(function(v) { return ("0" + Math.min(255, Number(v)).toString(16)).slice(-2) }).join("")
    return { kind: "color", level: "info", swatch: "#" + hx, label: "#" + hx + "   " + t }
  }
  if (single && (m = /^hsla?\(\s*(\d{1,3})(?:deg)?\s*[, ]\s*(\d{1,3})%\s*[, ]\s*(\d{1,3})%/i.exec(t)))
    return { kind: "color", level: "info", swatch: hslToHex(Number(m[1]), Number(m[2]), Number(m[3])), label: hslToHex(Number(m[1]), Number(m[2]), Number(m[3])) + "   " + t }
  if (single && /^https?:\/\/\S+$/i.test(t)) {
    var u = /^https?:\/\/([^\/?#]+)([^?#]*)/i.exec(t), path = u[2] && u[2] !== "/" ? u[2] : ""
    if (path.length > 26) path = path.slice(0, 12) + "…" + path.slice(-12)
    return { kind: "url", level: "info", label: "link  " + u[1].replace(/^www\./, "") + path }
  }
  if (single && /^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$/.test(t)) return { kind: "email", level: "info", label: "email address" }
  if (single && /^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})$/i.test(t)) return { kind: "uuid", level: "info", label: "UUID" }
  if (single && (m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(t)) && [m[1], m[2], m[3], m[4]].every(function(v) { return Number(v) < 256 }))
    return { kind: "ip", level: "info", label: "IPv4 address" }
  if (single && /^-?\d+(\.\d+)?$/.test(t)) {
    var num = Number(t)
    if (/^\d{10}$/.test(t) && num > 946684800 && num < 4102444800) return { kind: "time", level: "info", label: "Unix time  " + new Date(num * 1000).toISOString().replace("T", " ").slice(0, 16) + " UTC" }
    if (/^\d{13}$/.test(t) && num > 946684800000) return { kind: "time", level: "info", label: "Unix time (ms)  " + new Date(num).toISOString().replace("T", " ").slice(0, 16) + " UTC" }
    if (/^-?\d{4,}$/.test(t) && Math.abs(num) < 9007199254740991)
      return { kind: "number", level: "info", label: String(num).replace(/\B(?=(\d{3})+(?!\d))/g, ",") + (num >= 0 ? "   0x" + num.toString(16) : "") }
  }
  if (/^[\[{]/.test(t) && /[\]}]$/.test(t)) {
    try {
      var j = JSON.parse(t)
      var cnt = Array.isArray(j) ? j.length + " items" : Object.keys(j).length + " keys"
      return { kind: "json", level: "info", label: "JSON  " + cnt + (lines > 1 ? "  " + lines + " lines" : "") }
    } catch (e) {}
  }
  if (single && /^(~|\/)[\w\-.\/~+@]+$/.test(t) && t.indexOf("/") >= 0) return { kind: "path", level: "info", label: "path" }
  // No word/line/char count chip any more (v5): plain text, however long, gets no badge.
  return null
}


// Was the copied text the selected text? Both are compared sanitised; one containing the other counts too (a copy button that takes part of the
// selection, or an app that trims / adds a newline). Very short strings must match exactly.
function sameSelection(selection, copied) {
  var a = sanitize(selection, 0), b = sanitize(copied, 0)
  if (!a || !b) return false
  if (a === b) return true
  var shortest = Math.min(a.length, b.length)
  if (shortest >= 4 && (a.indexOf(b) >= 0 || b.indexOf(a) >= 0)) return true
  return similarText(a, b)
}

// Can these highlight boxes be the copied text at all? A short text cannot fill dozens of boxes or several screens of width: that is a
// colour match on other parts of the page, not the selection.
function plausibleSelection(rects, copied) {
  var chars = sanitize(copied, 0).replace(/\s/g, "").length
  if (!rects || !rects.length || chars <= 0) return true
  if (rects.length > chars + 1) return false
  var w = 0, h = 0
  rects.forEach(function(r) { w += r.w; h += r.h })
  return w / Math.max(1, h / rects.length) <= 20 * chars + 200
}

// Could the copied text be a link / address from a right-click menu ("Copy link address", "Copy email address")? One word, with a scheme, a slash or an @.
function looksLikeLink(text) {
  var t = String(text || "")
  return t.length >= 3 && t.length <= 2000 && !/\s/.test(t) && /[:@\/]/.test(t)
}

// Nearly the same words (a web page's copy leaves out hidden bits such as "[1]" citation marks or edit links that its selection text had):
// >= 85% of the words of the shorter text are in the other one, at least 5 words.
function similarText(a, b) {
  var wa = String(a).toLowerCase().split(/[\s.,;:!?()\[\]{}"'“”‘’<>\/\\|@#$%^&*+=~`_-]+/).filter(function(w) { return w }), wb = String(b).toLowerCase().split(/[\s.,;:!?()\[\]{}"'“”‘’<>\/\\|@#$%^&*+=~`_-]+/).filter(function(w) { return w })
  var small = wa.length <= wb.length ? wa : wb, big = wa.length <= wb.length ? wb : wa
  if (small.length < 5) return false
  var set = {}
  big.forEach(function(w) { set[w] = true })
  var hit = small.filter(function(w) { return set[w] }).length
  return hit >= 0.85 * small.length
}

// Toast wording for a copy that is not text: e = one line of bin/copyfx-clip ({type: files|image|other, ...}).
function describeObject(e) {
  if (e.type === "files") {
    var n = e.count || 0, names = e.names || [], dirs = e.dirs || 0
    var what = n === dirs ? (n === 1 ? "Folder" : "Folders") : (dirs > 0 ? "Items" : (n === 1 ? "File" : "Files"))
    return { title: what + (e.verb === "cut" ? " cut" : " copied"), text: names.join(", ") + (n > names.length ? " +" + (n - names.length) : "") }
  }
  if (e.type === "image") return { title: "Image copied", text: e.w && e.h ? e.w + " x " + e.h : String(e.mime || "").replace("image/", "").toUpperCase() }
  return { title: "Copied", text: String(e.mime || "") }
}

// Look of the plain panel an effect draws when no selection was found: the text size and colours of the last selection seen in the same app
// (known = {bg, fg, lineH}), otherwise a small neutral size in the shell colours (never the big overlay font).
function fallbackLook(known, menuBg, menuFg, fontSize) {
  var neutral = Math.max(10, Math.round(fontSize * 0.62))
  if (!known || !(known.lineH > 0)) return { px: neutral, bg: menuBg, fg: menuFg, matched: false }
  return { px: Math.max(10, Math.min(24, Math.round(known.lineH * 0.7))), bg: known.bg || menuBg, fg: known.fg || menuFg, matched: true }
}

// fallback "off": a copy whose selection could not be located plays no effect (the info chip still shows). Gallery tests, notifications and
// anchor "cursor" (no detection at all) are not fallbacks and always play.
function skipPlay(fallback, anchor, selFound, galleryOpen, isNotify) {
  return fallback === "off" && anchor === "selection" && !selFound && !galleryOpen && !isNotify
}

// Keys under which a detected selection's look is remembered: the app (window class) and the exact window (position + size).
function lookKeys(cls, win) {
  var keys = []
  if (cls) keys.push("cls:" + cls)
  if (win && win.length === 4 && win[2] > 0) keys.push("win:" + win.map(Math.round).join(","))
  return keys
}

// ---------- bar menu (BarWidget.qml) ----------
// Tag groups shown as categories, in this order; a tag needs at least 3 effects to get its own row. Effects that are in none of them go to "More".
var MENU_GROUPS = [["playful", "Playful"], ["clean", "Clean"], ["simple", "Simple"], ["cozy", "Cozy"], ["wholesome", "Wholesome"], ["nature", "Nature"],
  ["weather", "Weather"], ["party", "Party"], ["retro", "Retro"], ["arcade", "Arcade"], ["neon", "Neon"], ["cyber", "Cyber"], ["hacker", "Hacker"],
  ["dev", "Dev"], ["nerdy", "Nerdy"], ["physics", "Physics"], ["glitch", "Glitch"]]
function menuKind(size) {
  return size === "IMG" ? "on the text" : size === "XL" ? "big" : size === "S" ? "small" : "letters"
}
// Menu rows for the effect list: Favorites, All, one row per tag group, More. Debug effects are left out (dev tools).
function menuCategories(effects, favs) {
  var list = (effects || []).filter(function(e) { return !e.debug })
  var item = function(e) { return { id: e.id, label: e.name, hint: menuKind(e.size), desc: e.description } }
  var byName = function(a, b) { return a.name < b.name ? -1 : a.name > b.name ? 1 : 0 }
  list = list.slice().sort(byName)
  var cats = [], used = {}
  var fav = (favs || []).map(function(id) { return list.filter(function(e) { return e.id === id })[0] }).filter(function(e) { return !!e })
  cats.push({ id: "fav", label: "★ Favorites", items: fav.map(item), note: "Press f on an effect to add it here." })
  cats.push({ id: "all", label: "All", items: list.map(item) })
  MENU_GROUPS.forEach(function(g) {
    var m = list.filter(function(e) { return e.tags.indexOf(g[0]) >= 0 })
    if (m.length < 3) return
    m.forEach(function(e) { used[e.id] = true })
    cats.push({ id: "tag:" + g[0], label: g[1], items: m.map(item) })
  })
  var rest = list.filter(function(e) { return !used[e.id] })
  if (rest.length) cats.push({ id: "more", label: "More", items: rest.map(item) })
  return cats
}
// Toggle an id in a favourites list (keeps order, no duplicates).
function toggleFav(favs, id) {
  var cur = (favs || []).filter(function(f) { return f !== id })
  if (cur.length === (favs || []).length) cur.push(id)
  return cur
}
// What the bar menu may change in config.json (through {"set": {...}} from BarWidget.qml): only these, only valid values.
function applySet(config, set, effectIds) {
  var c = Object.assign({}, config), changed = false
  if (!set) return { config: c, changed: false }
  if (typeof set.effect === "string" && (effectIds || []).indexOf(set.effect) >= 0 && c.effect !== set.effect) { c.effect = set.effect; changed = true }
  if ((set.mode === "random" || set.mode === "selected") && c.mode !== set.mode) { c.mode = set.mode; changed = true }
  if (typeof set.enabled === "boolean" && c.enabled !== set.enabled) { c.enabled = set.enabled; changed = true }
  return { config: c, changed: changed }
}

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "logic.js" as Logic

// EXPERIMENTAL. The bar icon and its menu for CopyFX (the copy-effects overlay in CopyFx.qml).
// Categories on the left, effects on the right (the same menu as OmaShaders: SectionMenu.qml). Moving onto an effect or hovering it plays it
// once as a preview, Enter keeps it and closes, Space keeps it and stays open. Everything the menu changes goes through the overlay
// ({"set": ...}); this file only reads config.json and the effect list the overlay writes, and writes the favourites file.
BarWidget {
  id: root
  moduleName: "io.github.akton1.copyfx"

  readonly property string pluginId: "io.github.akton1.copyfx"
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")
  readonly property string dataDir: dataHome + "/omarchy-shell/copyfx"
  readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || (dataDir + "/run")
  readonly property string previewText: "Copied to clipboard"

  readonly property color fg: root.bar.barForeground
  readonly property string boxOn: "󰄲"
  readonly property string boxOff: "󰄱"

  property var effects: []
  property var config: Logic.parseConfig("")
  property var favs: []
  readonly property var cats: Logic.menuCategories(root.effects, root.favs)
  readonly property var current: root.effects.find(function(e) { return e.id === root.config.effect }) || null
  property string flash: ""

  function send(payload) {
    Quickshell.execDetached(["omarchy-shell", "-q", "shell", "toggle", root.pluginId, JSON.stringify(payload)])
  }
  function say(t) { root.flash = t; flashTimer.restart() }
  Timer { id: flashTimer; interval: 2500; onTriggered: root.flash = "" }

  // ---------------------------------------------------------------- state files
  FileView {
    path: root.runDir + "/copyfx-effects.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.effects = JSON.parse(text()) } catch (e) { root.effects = [] }
    }
  }
  FileView {
    path: root.dataDir + "/config.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.config = Logic.parseConfig(text())
    onLoadFailed: root.config = Logic.parseConfig("")
  }
  FileView {
    id: favFile
    path: root.dataDir + "/favorites"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.favs = String(text() || "").split("\n").map(function(l) { return l.trim() }).filter(function(l) { return l !== "" })
  }

  // ---------------------------------------------------------------- actions
  function play(id) { root.send({ test: root.previewText, effect: id }) }
  function keep(id, replay) {
    root.send({ set: { effect: id, mode: "selected" } })
    root.config = Object.assign({}, root.config, { effect: id, mode: "selected" })
    if (replay) root.play(id)
  }
  function toggleEnabled() {
    var on = !root.config.enabled
    root.send({ set: { enabled: on } })
    root.config = Object.assign({}, root.config, { enabled: on })
    root.say(on ? "CopyFX on" : "CopyFX off")
  }
  function setEnabled(on) {
    if (root.config.enabled === on) return
    root.toggleEnabled()
  }
  function toggleRandom() {
    var m = root.config.mode === "random" ? "selected" : "random"
    root.send({ set: { mode: m } })
    root.config = Object.assign({}, root.config, { mode: m })
    root.say(m === "random" ? "A different effect on every copy" : "Always the chosen effect")
  }
  function surprise() {
    var pool = root.effects.filter(function(e) { return !e.debug && !e.xxl && e.id !== root.config.effect })
    if (pool.length === 0) return
    var e = pool[Math.floor(Math.random() * pool.length)]
    root.keep(e.id, true)
    root.say("Surprise: " + e.name)
  }
  function step(dir) {
    var list = root.cats[1].items
    if (list.length === 0) return
    var i = list.findIndex(function(it) { return it.id === root.config.effect })
    var n = (i + dir + list.length) % list.length
    root.keep(list[n].id, true)
    root.say(list[n].label)
  }
  function openGallery() {
    root.close()
    Quickshell.execDetached(["omarchy-shell", "-q", "shell", "toggle", root.pluginId])
  }
  function toggleFav() {
    var it = sec.selected
    if (!it) return
    var next = Logic.toggleFav(root.favs, it.id)
    root.favs = next
    favFile.setText(next.join("\n") + "\n")
    if (sec.curItems.length === 0) sec.col = 0
    else sec.itemIdx = Math.max(0, Math.min(sec.itemIdx, sec.curItems.length - 1))
  }
  function handleText(t) {
    if (t === "q") root.close()
    else if (t === "e") root.toggleEnabled()
    else if (t === "o") root.setEnabled(false)
    else if (t === "m") root.toggleRandom()
    else if (t === "r") root.surprise()
    else if (t === "v") root.openGallery()
    else if (t === "f") root.toggleFav()
    else if (t === "g") sec.jump(false)
    else if (t === "G") sec.jump(true)
    else if (t >= "1" && t <= "9") sec.gotoCat(parseInt(t) - 1)
  }

  // A preview is a test play of the effect under the pointer; it waits until the pointer rests, so sweeping over the list does not start 20 effects.
  property string previewId: ""
  Timer {
    id: previewTimer
    interval: 350
    onTriggered: if (root.popupOpen && root.previewId !== "") root.play(root.previewId)
  }

  // ---------------------------------------------------------------- open / close
  property bool popupOpen: false
  property bool viaEnter: false
  readonly property bool opened: popupOpen
  property bool popoutSwitchClosing: false
  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    popupOpen = false
    Qt.callLater(function() { popoutSwitchClosing = false })
  }
  onPopupOpenChanged: {
    root.send({ menuState: popupOpen ? "open" : "closed" })
    if (popupOpen) {
      root.previewId = ""
      sec.sync()
    } else {
      previewTimer.stop()
    }
  }

  IpcHandler {
    target: "io.github.akton1.copyfx.menu"
    function toggle(): void { root.toggle() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function surprise(): void { root.surprise() }
    function next(): void { root.step(1) }
    function prev(): void { root.step(-1) }
  }

  // ---------------------------------------------------------------- the bar icon
  property real wheelAccum: 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.config.enabled
    tooltipText: "CopyFX (experimental)\n" + (root.config.enabled ? "on" : "off")
                 + " · effect: " + (root.current ? root.current.name : root.config.effect)
                 + (root.config.mode === "random" ? " · random on every copy" : "")
                 + "\nclick: menu · right-click: on/off · middle-click: surprise me · scroll: step through the effects"
    iconComponent: Component {
      Item {
        CopyFxIcon {
          anchors.centerIn: parent
          iconSize: Style.bar.iconCanvas
          color: root.fg
          opacity: root.config.enabled ? 1 : 0.4
        }
      }
    }
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleEnabled()
      else if (b === Qt.MiddleButton) root.surprise()
      else root.toggle()
    }
    onWheelMoved: function(delta) {
      root.wheelAccum += delta
      if (Math.abs(root.wheelAccum) < 120) return
      root.step(root.wheelAccum > 0 ? -1 : 1)
      root.wheelAccum = 0
    }
  }

  // ---------------------------------------------------------------- the menu
  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    focusTarget: keys
    contentWidth: popup.fittedContentWidth(Style.space(580))
    contentHeight: popup.fittedContentHeight(body.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        var r = sec.move(dx, dy)
        if (r === 1) sec.activate(false)
      }
      onTabRequested: function(dir) { sec.gotoCat((sec.catIdx + dir + sec.cats.length) % sec.cats.length) }
      onReturnRequested: root.viaEnter = true
      onActivateRequested: { sec.activate(!root.viaEnter); root.viaEnter = false }
      onCloseRequested: root.close()
      onTextKey: function(t) { root.handleText(t) }

      Column {
        id: body
        width: parent.width
        spacing: Style.space(4)

        Row {
          id: header
          width: body.width
          height: Style.space(28)
          spacing: Style.space(6)
          readonly property real cell: (width - spacing * 3) / 4

          MenuRow {
            width: header.cell
            fg: root.fg
            fontFamily: root.bar.fontFamily
            label: (root.config.enabled ? root.boxOn : root.boxOff) + "  On  (e)"
            onClicked: root.toggleEnabled()
          }
          MenuRow {
            width: header.cell
            fg: root.fg
            fontFamily: root.bar.fontFamily
            label: (root.config.mode === "random" ? root.boxOn : root.boxOff) + "  Random  (m)"
            onClicked: root.toggleRandom()
          }
          MenuRow {
            width: header.cell
            fg: root.fg
            fontFamily: root.bar.fontFamily
            label: "Surprise me  (r)"
            onClicked: root.surprise()
          }
          MenuRow {
            width: header.cell
            fg: root.fg
            fontFamily: root.bar.fontFamily
            label: "Gallery  (v)"
            onClicked: root.openGallery()
          }
        }

        Rectangle { width: body.width; height: 1; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2) }

        SectionMenu {
          id: sec
          width: body.width
          title: "Effects · experimental"
          fg: root.fg
          fontFamily: root.bar.fontFamily
          cats: root.cats
          saved: root.config.effect
          favs: root.favs
          focused: true
          defaultCat: 1
          onPointed: function(item) { root.previewId = item.id; previewTimer.restart() }
          onChosen: function(item, keepOpen) { root.keep(item.id, keepOpen); if (!keepOpen) root.close() }
          onActed: function(id) {}
        }

        Rectangle { width: body.width; height: 1; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2) }

        Text {
          width: body.width
          height: Style.space(24)
          verticalAlignment: Text.AlignVCenter
          leftPadding: Style.space(10)
          elide: Text.ElideRight
          textFormat: Text.PlainText
          text: {
            if (root.flash !== "") return root.flash
            if (root.effects.length === 0) return "Loading the effect list…"
            var it = sec.selected
            if (it) return it.label + (it.desc ? ": " + it.desc : "")
            return (root.config.enabled ? "On" : "Off") + " · effect: " + (root.current ? root.current.name : root.config.effect) + (root.config.mode === "random" ? " · random on every copy" : "")
          }
          color: root.fg
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
        }
        Text {
          width: body.width
          topPadding: Style.space(2)
          leftPadding: Style.space(10)
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: "hjkl move · ⏎ keep · space try · tab group · f favorite · r surprise · m random · e on/off · v gallery · esc close"
          opacity: 0.6
          color: root.fg
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body * 0.85
        }
        Text {
          width: body.width
          topPadding: Style.space(2)
          leftPadding: Style.space(10)
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: "Experimental: still being worked on, expect rough edges. Previews play on the copy overlay."
          opacity: 0.6
          color: root.fg
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body * 0.85
        }
      }
    }
  }
}

import QtQuick
import qs.Commons
import "sample-sprite.js" as Sample

// One gallery card: a looping live preview of an effect plus its name and description.
Rectangle {
  id: card

  property var effect: ({ id: "", name: "", description: "" })
  property string sampleText: "Copied!"
  property bool current: false      // keyboard cursor is on this card
  property bool chosen: false       // this is the configured effect
  property color fg: "white"
  property color bg: "black"
  property color accent: "#f19d88"
  property string fontFamily: ""
  property bool galleryOpen: true
  readonly property bool hovered: hoverArea.containsMouse
  // Only the card under the mouse (or under the keyboard cursor) runs its preview: 20+ animated cards at once lagged.
  readonly property bool live: card.galleryOpen && (card.hovered || card.current)
  signal clicked()
  signal doubleClicked()

  implicitWidth: 280
  implicitHeight: 210
  radius: 10
  color: Util.alpha(card.fg, card.current ? 0.10 : 0.04)
  border.width: card.current || card.chosen ? 2 : 1
  border.color: card.current ? card.accent : card.chosen ? Util.alpha(card.accent, 0.6) : Util.alpha(card.fg, 0.15)

  property string base: Qt.resolvedUrl(".").toString()          // the host passes its effect base (see the {"reload":true} dev payload)
  property var theme: null                                        // the effects' theme colours (host passes them)
  property string resolved: card.effect.id                       // the effect that really plays (the weather effect resolves to the current one)
  readonly property url source: card.base + "effects/" + card.resolved + "/Effect.qml"

  function load() {
    // "On text" effects need a selection to play on: fake one on the stage (a highlighted line in the middle).
    var onText = card.effect.size === "M", byImage = card.effect.size === "IMG"
    var props = {
      text: onText || byImage ? "Copied to clipboard" : card.sampleText, fg: card.fg, bg: card.bg, accent: card.accent,
      fontFamily: card.fontFamily, fontSize: 15, compact: true,
      selFound: onText || byImage,
      selRects: byImage ? Sample.rects : onText ? [{ x: 32, y: 56, w: 200, h: 18, il: 2, ir: 2, it: 3, ib: 3, gaps: [] }] : [],
      sprite: byImage ? Sample.sprite : null,
      srcBg: onText || byImage ? "#3465a4" : card.bg, srcFg: onText || byImage ? "#ffffff" : card.fg, srcMono: onText
    }
    if (card.theme) props.theme = card.theme
    loader.setSource(card.source, props)
  }

  Rectangle {
    id: stage
    x: 8; y: 8
    width: parent.width - 16
    height: 130
    radius: 6
    clip: true
    color: Qt.darker(card.bg, 1.3)

    Loader {
      id: loader
      active: card.live
      anchors.fill: parent
      onLoaded: {
        item.origin = Qt.point(stage.width * 0.3, stage.height * 0.35)
        item.finished.connect(function() { replay.restart() })
      }
    }
  }

  Timer { id: replay; interval: 700; onTriggered: card.load() }
  Component.onCompleted: card.load()

  Column {
    x: 12; y: stage.y + stage.height + 8
    width: parent.width - 24
    spacing: 2
    Text { textFormat: Text.PlainText;
      text: card.effect.name + (card.chosen ? "  ✓" : "")
      color: card.chosen ? card.accent : card.fg
      font.family: card.fontFamily
      font.pixelSize: 15
      font.bold: true
    }
    Text { textFormat: Text.PlainText;
      width: parent.width
      text: card.effect.description
      color: Util.alpha(card.fg, 0.7)
      font.family: card.fontFamily
      font.pixelSize: 11
      wrapMode: Text.WordWrap
      maximumLineCount: 2
      elide: Text.ElideRight
    }
    Text { textFormat: Text.PlainText;                                                    // the style / kind tags (search them with #tag)
      width: parent.width
      visible: !!card.effect.tags && card.effect.tags.length > 0
      text: (card.effect.tags || []).filter(function(t) { return t !== "by-image" && t !== "on-text" }).map(function(t) { return "#" + t }).join("  ")
      color: Util.alpha(card.accent, 0.85)
      font.family: card.fontFamily
      font.pixelSize: 10
      elide: Text.ElideRight
    }
  }

  MouseArea { id: hoverArea; anchors.fill: parent; hoverEnabled: true; onClicked: card.clicked(); onDoubleClicked: card.doubleClicked() }

  // A frozen mid-animation frame (posters/<id>.png, made by tests/make-posters.sh) while the preview is not running.
  Image {
    id: poster
    visible: !card.live && status === Image.Ready
    x: 8; y: 8; width: parent.width - 16; height: 130
    source: card.base + "posters/" + card.resolved + ".png"
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: true
  }
  Text { textFormat: Text.PlainText;
    visible: !card.live && poster.status !== Image.Ready
    x: 8; y: 8; width: parent.width - 16; height: 130
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: "▶  hover to preview"
    color: Util.alpha(card.fg, 0.35)
    font.family: card.fontFamily
    font.pixelSize: 12
  }
}

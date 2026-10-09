#!/bin/bash
# Run one effect standalone (offscreen, no shell restart needed) and save a screenshot after N ms.
#   tests/run-effect.sh <effect-id> [text] [shot-ms] [out.png] [compact]
# Prints every QML warning/error the effect produces.
dir=$(cd "$(dirname "$0")/.." && pwd)
id=${1:?effect id}; text=${2:-Hello Omarchy - 80s nerd copy effects rock! 0xDEADBEEF}; ms=${3:-1200}
out=${4:-${XDG_RUNTIME_DIR:-.}/effect-$id.png}; compact=${5:-false}; W=${6:-1920}; H=${7:-1080}; OX=${8:-960}; OY=${9:-640}
SELFOUND=false; [ -n "$RECTS" ] && SELFOUND=true
h=$(mktemp --suffix=.qml)
cat > "$h" <<QML
import QtQuick
import QtQuick.Window
Window {
  id: w
  property double t0: Date.now()
  visible: true; width: $W; height: $H; color: "#20232a"
  Item { id: stage; anchors.fill: parent
    Rectangle { anchors.fill: parent; color: "#20232a" }
    Loader { id: ld; anchors.fill: parent } }
  Component.onCompleted: ld.setSource("file://$dir/effects/$id/Effect.qml", {
    text: "$text", fg: "#e6e6e6", bg: "#14161a", accent: "#f19d88", fontFamily: "${FONT:-sans-serif}", fontSize: $compact ? 15 : 24,
    compact: $compact, srcBg: "#3465a4", srcFg: "#ffffff", srcMono: ${SRCMONO:-false}, selFound: $SELFOUND, selRects: ${RECTS:-[]}, sprite: ${SPRITE:-null}, runMs: ${RUNMS:-200}${THEME:+, theme: $THEME} })
  Timer { interval: 1; running: true; onTriggered: console.log("first tick after " + (Date.now() - w.t0) + " ms") }
  Connections { target: ld.item; ignoreUnknownSignals: true; function onFinished() { console.log("finished after " + (Date.now() - w.t0) + " ms") } }
  Timer { interval: 40; running: true; onTriggered: if (ld.item) ld.item.origin = Qt.point($OX, $OY) }
  Timer { interval: 200; running: true; onTriggered: if (ld.item && ld.item.layouts) console.log("LAYOUTS " + JSON.stringify(ld.item.layouts.map(function(l) { return { fam: l.fam, px: Math.round(l.px * 10) / 10, err: Math.round(l.err * 1000) / 1000, lines: l.lines.map(function(x) { return x.text }) } }))) }
  Timer { interval: $ms; running: true; onTriggered: stage.grabToImage(function(r) { console.log("saved", r.saveToFile("$out")); Qt.quit() }) }
}
QML
QT_FORCE_STDERR_LOGGING=1 QT_QUICK_BACKEND=software QT_QPA_PLATFORM=offscreen timeout 30 qml6 "$h" 2>&1 | grep -v -E "^(QStandardPaths|qt\.|Could not|libEGL|MESA)" | head -${LINES_MAX:-12}
rm -f "$h"

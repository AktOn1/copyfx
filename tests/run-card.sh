#!/bin/bash
# Run the real gallery PreviewCard for one effect (offscreen) and save shots at several times.
#   tests/run-card.sh <effect-id> <out-prefix> [ms ms ms ...]
dir=$(cd "$(dirname "$0")/.." && pwd); id=${1:?effect id}; prefix=${2:-${XDG_RUNTIME_DIR:-.}/card-$id}; shift 2
times=${*:-500 1000 1500 2000 2500 3000 3500 4000 4500 5000}
h=$(mktemp --suffix=.qml)
timers=""; i=0
for t in $times; do i=$((i+1)); timers="$timers
  Timer { interval: $t; running: true; onTriggered: stage.grabToImage(function(r) { r.saveToFile(\"${prefix}-$i.png\") }) }"; done
last=$(echo $times | awk '{print $NF}')
cat > "$h" <<QML
import QtQuick
import QtQuick.Window
import "file://$dir" as Fx
Window {
  visible: true; width: 300; height: 220; color: "#0b1414"
  Item { id: stage; anchors.fill: parent
    Fx.PreviewCard { anchors.centerIn: parent; effect: ({ id: "$id", name: "$id", description: "preview" }); fg: "#dddddd"; bg: "#101a1a"; accent: "#f19d88"; fontFamily: "sans-serif" } }
  $timers
  Timer { interval: $((last + 400)); running: true; onTriggered: Qt.quit() }
}
QML
QT_FORCE_STDERR_LOGGING=1 QT_QUICK_BACKEND=software QT_QPA_PLATFORM=offscreen timeout 40 qml6 "$h" 2>&1 | grep -v -E "^(QStandardPaths|qt\.|Could not|libEGL|MESA)" | head -${LINES_MAX:-8}
rm -f "$h"

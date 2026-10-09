import QtQuick
import "../.."

// STILL TEST TWIN of every on-text effect: the shared SourceText layout with no animation, held for 8 s, so a screenshot at any
// moment shows exactly where the letters sit relative to the original text (used by tests/sandbox/run.py).
SourceText {
  id: fx
  Component.onCompleted: console.log("text-still: hasSel", fx.hasSel, "exact", fx.exactWords, "srcMono", fx.srcMono, "font", fx.fontFamily, "layouts", JSON.stringify(fx.layouts.map(function(l) { return { fam: l.fam, px: Math.round(l.px * 10) / 10, err: Math.round(l.err * 1000) / 1000, n: l.lines.length } })), "chosen", fx.chosen.fam)
  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 8000 }
  }
}

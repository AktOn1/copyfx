import QtQuick
import "../.."

// The real text is blacked out by a kernel-panic screen that types itself out, then reboots the text.
SpriteText {
  id: fx
  total: 1500
  readonly property var lines: ["Kernel panic - not syncing:", "  copied: " + fx.text.slice(0, 34), "CPU: 0 PID: 1 Comm: copyfx", "Call Trace: ctrl_c+0x42/0x99", "---[ end Kernel panic ]---"]
  readonly property real shown: Math.min(1, fx.t / (fx.total * 0.6)) * 130
  readonly property bool flash: fx.t > fx.total * 0.82 && fx.t < fx.total * 0.9
  alphaFn: function() { return fx.t > fx.total * 0.85 ? 1 : 0.06 }
  Rectangle {
    id: scr
    x: fx.tg.x - fx.lh * 0.5; y: fx.tg.y - fx.lh * 0.3; width: Math.max(fx.tg.w + fx.lh, fx.lh * 24); height: Math.max(fx.tg.h + fx.lh * 0.6, fx.lh * 5.6)
    color: fx.flash ? "#ffffff" : "#000000"; opacity: (fx.t < fx.total * 0.85 || fx.flash ? 0.94 : 0) * fx.hlAlpha
    Text { textFormat: Text.PlainText;
      x: fx.lh * 0.5; y: fx.lh * 0.4; color: fx.theme.red; font.family: "monospace"; font.pixelSize: fx.lh * 0.72; lineHeight: 1.1
      text: { var s = fx.lines.join("\n"); return s.slice(0, Math.floor(fx.shown)) + (Math.floor(fx.t / 200) % 2 ? "_" : "") }
    }
  }
}

import QtQuick
import "../.."

// The real letters scramble into katakana and decode back, first to last.
SpriteText {
  id: fx
  total: fx.n * fx.step + 900
  readonly property string film: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789"
  function done(i) { return fx.t > 250 + i * fx.step }
  hlColor: "#000a03"
  alphaFn: function(u) { return fx.done(u.i) ? 1 : 0 }
  tintFn: function(u) { return fx.done(u.i) ? (fx.t < 250 + u.i * fx.step + 200 ? 14 : 15) : 0 }
  Repeater {
    model: fx.units
    delegate: Text { textFormat: Text.PlainText;
      required property var modelData
      visible: !fx.done(modelData.i)
      x: modelData.cx - width / 2; y: modelData.cy - height / 2
      text: fx.film.charAt(Math.floor(fx.hash(modelData.i, Math.floor(fx.t / 60)) * fx.film.length))
      color: "#008f22"; font.family: "monospace"; font.pixelSize: Math.max(8, modelData.h * 0.75)
    }
  }
}

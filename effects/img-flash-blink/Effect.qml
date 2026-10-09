import QtQuick
import "../.."

// The whole real text blinks red, green, blue.
SpriteText {
  id: fx
  total: 430
  tintFn: function() { var ph = Math.floor(fx.t / 130); return ph < 3 ? [1, 5, 9][ph] : 0 }

}

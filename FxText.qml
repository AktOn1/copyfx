import QtQuick

// Text that wraps once it reaches maxWidth (and elides after maxLines) but stays as narrow as its content.
Text { textFormat: Text.PlainText;
  id: t
  property real maxWidth: 600
  property int maxLines: 8

  TextMetrics { id: tm; text: t.text; font: t.font }

  width: Math.min(Math.ceil(tm.width) + 8, t.maxWidth)
  wrapMode: Text.Wrap
  maximumLineCount: t.maxLines
  elide: Text.ElideRight
}

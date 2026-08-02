import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadPdfOnWeb(Uint8List bytes, String filename) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.window.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

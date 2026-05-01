import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> saveTextFile({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  final blob = web.Blob(
    [contents.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  _downloadBlob(blob, fileName);
  return '$fileName téléchargé.';
}

Future<String> saveBinaryFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  _downloadBlob(blob, fileName);
  return '$fileName téléchargé.';
}

void _downloadBlob(web.Blob blob, String fileName) {
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

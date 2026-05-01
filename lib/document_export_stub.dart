import 'dart:typed_data';

Future<String> saveTextFile({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  return '$fileName prêt à exporter.';
}

Future<String> saveBinaryFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  return '$fileName prêt à exporter.';
}

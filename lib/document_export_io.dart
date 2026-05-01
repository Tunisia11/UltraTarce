import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveTextFile({
  required String fileName,
  required String contents,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  final file = await _targetFile(fileName);
  await file.writeAsString(contents, flush: true);
  return '${file.path} enregistré.';
}

Future<String> saveBinaryFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final file = await _targetFile(fileName);
  await file.writeAsBytes(bytes, flush: true);
  return '${file.path} enregistré.';
}

Future<File> _targetFile(String fileName) async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return File('${directory.path}${Platform.pathSeparator}$safeName');
}

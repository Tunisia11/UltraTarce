import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

class PickedLogo {
  const PickedLogo({
    required this.dataUrl,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String dataUrl;
  final String name;
  final String mimeType;
  final int size;
}

bool get supportsLogoImagePicker => true;

Future<PickedLogo?> pickLogoImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;

  // Prefer in-memory bytes; fall back to reading from path on platforms
  // where withData is not guaranteed (e.g. some Linux configurations).
  final bytes =
      file.bytes ??
      (file.path != null ? File(file.path!).readAsBytesSync() : null);

  if (bytes == null) return null;

  final mimeType = _mimeTypeForLogo(file.name);
  final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

  return PickedLogo(
    dataUrl: dataUrl,
    name: file.name,
    mimeType: mimeType,
    size: bytes.length,
  );
}

String _mimeTypeForLogo(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/png';
}

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class PickedLogo {
  const PickedLogo({
    required this.dataUrl,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.bytes,
  });

  final String dataUrl;
  final String name;
  final String mimeType;
  final int size;
  final Uint8List bytes;
}

bool get supportsLogoImagePicker => true;

Future<PickedLogo?> pickLogoImage() {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/webp'
    ..style.display = 'none';
  final completer = Completer<PickedLogo?>();

  void finish(PickedLogo? logo) {
    if (!completer.isCompleted) {
      completer.complete(logo);
    }
    input.remove();
  }

  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      finish(null);
      return;
    }

    final reader = web.FileReader();
    reader.onloadend = ((web.ProgressEvent _) {
      final result = reader.result;
      if (result == null) {
        finish(null);
        return;
      }
      final dataUrl = (result as JSString).toDart;
      final commaIndex = dataUrl.indexOf(',');
      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));

      finish(
        PickedLogo(
          dataUrl: dataUrl,
          name: file.name,
          mimeType: file.type.isEmpty ? _mimeTypeForLogo(file.name) : file.type,
          size: file.size,
          bytes: bytes,
        ),
      );
    }).toJS;
    reader.onerror = ((web.Event _) => finish(null)).toJS;
    reader.readAsDataURL(file);
  }).toJS;

  input.oncancel = ((web.Event _) => finish(null)).toJS;
  web.document.body?.append(input);
  input.click();

  return completer.future;
}

String _mimeTypeForLogo(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/png';
}

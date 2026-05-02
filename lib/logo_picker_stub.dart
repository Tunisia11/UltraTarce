import 'dart:typed_data';

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

bool get supportsLogoImagePicker => false;

Future<PickedLogo?> pickLogoImage() async => null;

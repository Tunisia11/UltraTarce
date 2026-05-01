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

bool get supportsLogoImagePicker => false;

Future<PickedLogo?> pickLogoImage() async => null;

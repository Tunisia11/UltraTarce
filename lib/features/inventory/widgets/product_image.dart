import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url.trim());
    final canLoadRemoteImage =
        uri != null && uri.scheme == 'https' && uri.hasAuthority;
    if (!canLoadRemoteImage) {
      return _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        uri.toString(),
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      color: AppColors.background,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}

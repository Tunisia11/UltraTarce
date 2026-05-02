import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.width = 54,
    this.height = 54,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return _fallback();

    if (cleanUrl.startsWith('data:image/')) {
      final bytes = _decodeDataUrl(cleanUrl);
      if (bytes != null) {
        return _clip(
          Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          ),
        );
      }
      return _fallback();
    }

    final uri = Uri.tryParse(cleanUrl);
    final canLoadRemoteImage =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.hasAuthority;

    if (!canLoadRemoteImage) {
      return _fallback();
    }

    return _clip(
      Image.network(
        uri.toString(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    try {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) return null;
      final payload = value.substring(commaIndex + 1);
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Widget _clip(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: (width * 0.45).clamp(16, 32),
        color: AppColors.muted,
      ),
    );
  }
}

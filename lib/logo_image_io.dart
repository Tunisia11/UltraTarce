import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

const int _maxInlineImageBytes = 1600 * 1024;

class LogoImage extends StatelessWidget {
  const LogoImage({
    super.key,
    required this.source,
    required this.fallbackText,
    this.size = 64,
  });

  final String? source;
  final String fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = source?.trim() ?? '';
    if (value.startsWith('data:image/')) {
      final bytes = _decodeDataImage(value);
      if (bytes != null) {
        return _frame(Image.memory(bytes, fit: BoxFit.contain));
      }
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'https' && uri.hasAuthority) {
      return _frame(
        Image.network(
          uri.toString(),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    final assetPath = _logoAssetPath(value);
    if (assetPath != null) {
      return _frame(
        Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _frame(Widget child) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE5E2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _fallback() {
    final initial = fallbackText.trim().isEmpty
        ? 'TN'
        : fallbackText.trim().characters.take(2).toString().toUpperCase();
    return _frame(
      Center(
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

String? _logoAssetPath(String source) {
  final value = source.trim();
  if (value.startsWith('asset:')) {
    final path = value.substring('asset:'.length).trim();
    return _isSafeAssetPath(path) ? path : null;
  }
  if (_isSafeAssetPath(value)) return value;
  return null;
}

bool _isSafeAssetPath(String value) {
  return value.startsWith('assets/') &&
      !value.contains('..') &&
      !value.contains('\\');
}

Uint8List? _decodeDataImage(String source) {
  final commaIndex = source.indexOf(',');
  if (commaIndex < 0) return null;
  try {
    final bytes = base64Decode(source.substring(commaIndex + 1));
    if (bytes.length > _maxInlineImageBytes) return null;
    return Uint8List.fromList(bytes);
  } catch (_) {
    return null;
  }
}

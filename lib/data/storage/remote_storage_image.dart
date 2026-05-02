import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/app_colors.dart';

class RemoteStorageImage extends StatefulWidget {
  const RemoteStorageImage({
    super.key,
    required this.bucket,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    required this.fallback,
  });

  final String bucket;
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget fallback;

  @override
  State<RemoteStorageImage> createState() => _RemoteStorageImageState();
}

class _RemoteStorageImageState extends State<RemoteStorageImage> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RemoteStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket != widget.bucket || oldWidget.path != widget.path) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final bytes = await supabase.storage
          .from(widget.bucket)
          .download(widget.path);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _bytes == null) {
      return widget.fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}

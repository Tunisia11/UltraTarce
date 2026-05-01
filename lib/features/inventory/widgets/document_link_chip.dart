import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'small_chip.dart';

class DocumentLinkChip extends StatelessWidget {
  const DocumentLinkChip({
    super.key,
    required this.label,
    this.muted = false,
    this.onTap,
  });

  final String label;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SmallChip(
        label: label,
        muted: muted,
        color: muted ? AppColors.muted : AppColors.primary,
      ),
    );
  }
}

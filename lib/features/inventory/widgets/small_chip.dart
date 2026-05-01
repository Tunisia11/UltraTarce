import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class SmallChip extends StatelessWidget {
  const SmallChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.muted = false,
  });

  final String label;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final chipColor = muted ? AppColors.muted : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: muted ? .08 : .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? AppColors.muted : chipColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

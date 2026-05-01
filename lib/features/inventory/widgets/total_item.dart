import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class TotalItem extends StatelessWidget {
  const TotalItem({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              fontSize: strong ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

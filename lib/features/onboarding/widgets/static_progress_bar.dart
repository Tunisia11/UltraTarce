import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class StaticProgressBar extends StatelessWidget {
  const StaticProgressBar({super.key, this.progress = .72});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final widthFactor = progress.clamp(0.0, 1.0).toDouble();
    return Container(
      height: 20,
      width: 190,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF5FAF67),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

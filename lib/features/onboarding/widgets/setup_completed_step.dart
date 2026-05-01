import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Compact summary for a setup step that is already done.
///
/// Keep this unframed so completed answers feel lighter than the active step.
/// The struck-through value makes it clear the answer is no longer the current
/// thing Tarek is asking for.
class SetupCompletedStep extends StatelessWidget {
  const SetupCompletedStep({
    super.key,
    required this.step,
    required this.title,
    required this.value,
  });

  final String step;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.emeraldDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$step  $title',
                  style: const TextStyle(
                    color: AppColors.subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.emeraldDark,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Fait',
            style: TextStyle(
              color: AppColors.emeraldDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'blinking_continue_button.dart';

/// Bottom navigation for onboarding.
///
/// `canGoNext` is used by page 2 to disable Continue until required setup
/// fields are completed.
class OnboardingControls extends StatelessWidget {
  const OnboardingControls({
    super.key,
    required this.index,
    required this.total,
    this.canGoNext = true,
    required this.onBack,
    required this.onNext,
  });

  final int index;
  final int total;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: OutlinedButton(
            onPressed: index == 0 ? null : onBack,
            child: const Text('Retour'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: i == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.emerald : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 148,
          child: canGoNext
              ? BlinkingContinueButton(
                  onPressed: onNext,
                  label: isLast ? 'Démarrer' : 'Continuer',
                )
              : ElevatedButton(
                  onPressed: null,
                  child: Text(isLast ? 'Démarrer' : 'Continuer'),
                ),
        ),
      ],
    );
  }
}

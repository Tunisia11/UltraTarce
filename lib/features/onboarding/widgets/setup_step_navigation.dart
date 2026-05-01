import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Local navigation for page-2 setup steps.
///
/// These controls move inside the setup questions. They do not replace the
/// global onboarding Back/Continue buttons at the bottom of the screen.
class SetupStepNavigation extends StatelessWidget {
  const SetupStepNavigation({
    super.key,
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Précédent'),
            style: _buttonStyle,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: canGoNext ? onNext : null,
            label: const Text('Suivant'),
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            style: _buttonStyle,
          ),
        ],
      ),
    );
  }

  static final _buttonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.emeraldDark,
    disabledForegroundColor: AppColors.subtle.withValues(alpha: .45),
    minimumSize: const Size(44, 44),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
  );
}

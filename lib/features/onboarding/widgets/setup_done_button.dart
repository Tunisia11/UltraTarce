import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Small confirmation button used by setup steps that need an explicit Done.
///
/// The selection widgets only update the local choice. Pressing this button is
/// what confirms the choice and unlocks the next setup question.
class SetupDoneButton extends StatelessWidget {
  const SetupDoneButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.label = 'Valider',
  });

  final VoidCallback onPressed;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emeraldDark,
          disabledForegroundColor: AppColors.subtle.withValues(alpha: .48),
          minimumSize: const Size(76, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

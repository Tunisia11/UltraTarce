import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// One selectable commerce-type button.
///
/// Used by `SetupCommerceTypeButtons`; edit selected/unselected colors here.
class SetupChoiceButton extends StatelessWidget {
  const SetupChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AppColors.emerald.withValues(alpha: .1)
            : AppColors.surfaceLowest,
        foregroundColor: selected ? AppColors.emeraldDark : AppColors.ink,
        side: BorderSide(
          color: selected
              ? AppColors.emerald.withValues(alpha: .45)
              : AppColors.border.withValues(alpha: .4),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

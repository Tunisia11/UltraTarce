import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Final fiscal option on page 2.
///
/// The switch starts ON from `StoreSetupPage`; change the label here if needed.
class SetupFiscalToggle extends StatelessWidget {
  const SetupFiscalToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.emerald.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ajouter timbre fiscal (1 TND)',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.emeraldDark,
            activeTrackColor: AppColors.emerald.withValues(alpha: .25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

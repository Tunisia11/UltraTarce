import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Price mode choices for page 2.
///
/// These are styled like radio buttons, but drawn manually so the code avoids
/// deprecated Flutter radio APIs.
class SetupPriceModeRadios extends StatelessWidget {
  const SetupPriceModeRadios({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final String selectedMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PriceRadioTile(
          title: 'Prix TTC',
          subtitle: 'Recommandé',
          value: 'Prix TTC',
          selectedMode: selectedMode,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _PriceRadioTile(
          title: 'Prix HT',
          subtitle: 'Pour gestion avancée des marges',
          value: 'Prix HT',
          selectedMode: selectedMode,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// One radio-style row inside the price mode section.
class _PriceRadioTile extends StatelessWidget {
  const _PriceRadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selectedMode,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final String selectedMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMode == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emerald.withValues(alpha: .09)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.emerald.withValues(alpha: .45)
                : AppColors.border.withValues(alpha: .25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.emeraldDark : AppColors.subtle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

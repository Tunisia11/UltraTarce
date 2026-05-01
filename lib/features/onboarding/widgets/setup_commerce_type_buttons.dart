import 'package:flutter/material.dart';

import 'setup_choice_button.dart';

/// Button group for "Type de commerce".
///
/// To add or remove commerce types, edit the `types` list below.
class SetupCommerceTypeButtons extends StatelessWidget {
  const SetupCommerceTypeButtons({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  static const types = ['Électronique', 'Général', 'Grossiste', 'Autre'];

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in types)
          SetupChoiceButton(
            label: type,
            selected: selectedType == type,
            onPressed: () => onChanged(type),
          ),
      ],
    );
  }
}

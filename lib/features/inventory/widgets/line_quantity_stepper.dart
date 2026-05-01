import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class LineQuantityStepper extends StatelessWidget {
  const LineQuantityStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    required this.onSubmitted,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<int> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuer',
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 17),
          ),
          SizedBox(
            width: 48,
            child: TextFormField(
              key: ValueKey('line-qty-$quantity'),
              initialValue: '$quantity',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onFieldSubmitted: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null) onSubmitted(parsed);
              },
            ),
          ),
          IconButton(
            tooltip: 'Augmenter',
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 17),
          ),
        ],
      ),
    );
  }
}

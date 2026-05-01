import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../core/formatters.dart';
import '../../../domain/app_enums.dart';
import 'small_chip.dart';

class PriceInsight extends StatelessWidget {
  const PriceInsight({
    super.key,
    required this.saleHt,
    required this.purchaseHt,
    required this.tvaRate,
  });

  final double saleHt;
  final double purchaseHt;
  final TvaRate tvaRate;

  @override
  Widget build(BuildContext context) {
    final saleTtc = saleHt * (1 + tvaRate.multiplier);
    final margin = saleHt - purchaseHt;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          SmallChip(label: 'TTC ${formatMoney(saleTtc)}'),
          SmallChip(
            label: 'Marge ${formatMoney(margin)}',
            color: margin >= 0 ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}

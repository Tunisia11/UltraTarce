import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../core/formatters.dart';
import '../../../domain/app_models.dart';
import 'empty_state.dart';
import 'table_cell_text.dart';

class PreviewLines extends StatelessWidget {
  const PreviewLines({super.key, required this.lines});

  final List<DocumentLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const EmptyState(text: 'Aucune ligne dans le document.');
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(.8),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(.9),
        4: FlexColumnWidth(.9),
        5: FlexColumnWidth(1.4),
      },
      border: TableBorder.all(color: AppColors.border),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.background),
          children: [
            TableCellText('Désignation', strong: true),
            TableCellText('Qté', strong: true),
            TableCellText('PU HT', strong: true),
            TableCellText('Remise', strong: true),
            TableCellText('TVA', strong: true),
            TableCellText('Total TTC', strong: true),
          ],
        ),
        for (final line in lines)
          TableRow(
            children: [
              TableCellText('${line.sku}\n${line.label}'),
              TableCellText('${line.quantity}'),
              TableCellText(formatMoney(line.unitHt)),
              TableCellText('${line.discountRate.toStringAsFixed(1)}%'),
              TableCellText(line.tvaRate.label),
              TableCellText(formatMoney(line.totalTtc)),
            ],
          ),
      ],
    );
  }
}

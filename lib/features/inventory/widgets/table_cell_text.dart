import 'package:flutter/material.dart';

class TableCellText extends StatelessWidget {
  const TableCellText(this.text, {super.key, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

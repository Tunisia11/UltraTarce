import 'package:flutter/material.dart';

class TypingCaret extends StatelessWidget {
  const TypingCaret({
    super.key,
    required this.color,
    required this.height,
    required this.visible,
  });

  final Color color;
  final double height;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : .16,
      child: Container(
        width: 7,
        height: height,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .34),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ResponsiveTable extends StatelessWidget {
  const ResponsiveTable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}

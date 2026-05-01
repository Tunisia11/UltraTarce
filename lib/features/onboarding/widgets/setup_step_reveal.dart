import 'package:flutter/material.dart';

/// Reveals one setup step only after the previous step is complete.
///
/// This keeps the "step by step" behavior reusable and easy to tune. Change the
/// animation duration/curves here if you want every setup step to appear faster
/// or slower.
class SetupStepReveal extends StatelessWidget {
  const SetupStepReveal({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: visible
          ? Padding(
              key: ValueKey(child.runtimeType),
              padding: const EdgeInsets.only(top: 14),
              child: child,
            )
          : const SizedBox.shrink(),
    );
  }
}

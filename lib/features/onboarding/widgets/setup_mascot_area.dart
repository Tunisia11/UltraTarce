import 'package:flutter/material.dart';

import 'welcome_mascot_image.dart';

/// Places the mascot on page 2.
///
/// Edit the `mascotHeight`, `mascotWidth`, and `Positioned` values below when
/// you want to move or resize Tarek without touching the setup form.
class SetupMascotArea extends StatelessWidget {
  const SetupMascotArea({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotHeight = compact
            ? constraints.maxWidth * .72
            : constraints.maxHeight * .92;
        final mascotWidth = compact
            ? constraints.maxWidth * .62
            : constraints.maxWidth * 1.02;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: compact ? -24 : -42,
              bottom: compact ? -16 : -4,
              child: WelcomeMascotImage(
                height: mascotHeight,
                width: mascotWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}

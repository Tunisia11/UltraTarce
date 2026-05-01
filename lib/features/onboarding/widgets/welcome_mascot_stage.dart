import 'package:flutter/material.dart';

import 'welcome_intro_text.dart';
import 'welcome_mascot_image.dart';

class WelcomeMascotStage extends StatelessWidget {
  const WelcomeMascotStage({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final mascotHeight = constraints.maxHeight * (isWide ? .76 : .45);
        final mascotWidth = constraints.maxWidth * (isWide ? .28 : .60);
        final sidePadding = isWide ? 310.0 : 24.0;
        final mascotRightOffset = isWide ? -16.0 : -28.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: sidePadding,
              right: isWide ? constraints.maxWidth * .38 : sidePadding,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: WelcomeIntroText(onNext: onNext),
              ),
            ),
            Positioned(
              right: mascotRightOffset,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: WelcomeMascotImage(
                  height: mascotHeight,
                  width: mascotWidth,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

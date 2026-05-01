import 'package:flutter/material.dart';

import 'celebration_mascot_gif.dart';
import 'completion_caption.dart';

/// Final onboarding page shown after store setup is complete.
///
/// Keep layout edits here, GIF edits in `CelebrationMascotGif`, and text edits
/// in `CompletionCaption`.
class OnboardingCompletionStage extends StatelessWidget {
  const OnboardingCompletionStage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        final maxGifWidth = isWide ? 560.0 : constraints.maxWidth * .86;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : 24,
              vertical: isWide ? 12 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: const CompletionCaption(),
                          ),
                        ),
                        const SizedBox(width: 42),
                        SizedBox(
                          width: maxGifWidth,
                          child: const CelebrationMascotGif(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: maxGifWidth,
                          child: const CelebrationMascotGif(),
                        ),
                        const SizedBox(height: 24),
                        const CompletionCaption(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

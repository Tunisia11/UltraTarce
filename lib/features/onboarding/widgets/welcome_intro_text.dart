import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'animated_typing_rich_text.dart';
import 'blinking_continue_button.dart';

class WelcomeIntroText extends StatelessWidget {
  const WelcomeIntroText({super.key, required this.onNext});

  final VoidCallback onNext;

  static const _darkLogoGreen = Color(0xFF0B2F21);
  static const _lightLogoGreen = Color(0xFF6DAE35);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final heightScale = (constraints.maxHeight / 920).clamp(.68, 1.0);
        final headlineSize = (isWide ? 64.0 : 42.0) * heightScale;
        final bodySize = 20.0 * heightScale;
        final firstGap = 24.0 * heightScale;
        final buttonGap = 48.0 * heightScale;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedTypingRichText(
                caretColor: _lightLogoGreen,
                duration: const Duration(milliseconds: 6000),
                segments: const [
                  TypingTextSegment('Salut, ', _lightLogoGreen),
                  TypingTextSegment('je suis ', _darkLogoGreen),
                  TypingTextSegment('Tarek', _lightLogoGreen),
                  TypingTextSegment('.\nJe vais t’aider\n', _darkLogoGreen),
                  TypingTextSegment('à préparer ', _lightLogoGreen),
                  TypingTextSegment('ton\nmagasin en\n', _darkLogoGreen),
                  TypingTextSegment('quelques minutes.', _lightLogoGreen),
                ],
                style: TextStyle(
                  fontSize: headlineSize,
                  fontWeight: FontWeight.w900,
                  height: .94,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: _lightLogoGreen.withValues(alpha: .1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              SizedBox(height: firstGap),
              Text(
                'On va configurer ta société, ton dépôt, tes prix, puis créer ta première vente.',
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtle,
                  height: 1.4,
                ),
              ),
              SizedBox(height: buttonGap),
              Center(
                child: SizedBox(
                  width: 200,
                  child: BlinkingContinueButton(
                    onPressed: onNext,
                    label: 'Commencer',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

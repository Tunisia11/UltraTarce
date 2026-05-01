import 'package:flutter/material.dart';

import 'animated_typing_rich_text.dart';

/// Big typed question for the current onboarding setup step.
///
/// Edit the text segments below to change what Tarek asks at each stage. The
/// `questionKey` lets the typing animation restart whenever the active step
/// changes.
class SetupIntroQuestionText extends StatelessWidget {
  const SetupIntroQuestionText({
    super.key,
    required this.active,
    required this.questionKey,
    required this.segments,
    required this.onFinished,
  });

  static const _darkLogoGreen = Color(0xFF0B2F21);
  static const _lightLogoGreen = Color(0xFF6DAE35);

  final bool active;
  final String questionKey;
  final List<TypingTextSegment> segments;
  final VoidCallback onFinished;

  static const companyIdentitySegments = [
    TypingTextSegment('Commençons par\n', _lightLogoGreen),
    TypingTextSegment('l’identité de\n', _darkLogoGreen),
    TypingTextSegment('ta société.', _lightLogoGreen),
  ];

  static const commerceTypeSegments = [
    TypingTextSegment('Quel type\n', _lightLogoGreen),
    TypingTextSegment('de commerce\n', _darkLogoGreen),
    TypingTextSegment('fais-tu ?', _lightLogoGreen),
  ];

  static const warehouseSegments = [
    TypingTextSegment('Préparons aussi\n', _lightLogoGreen),
    TypingTextSegment('ton premier\n', _darkLogoGreen),
    TypingTextSegment('dépôt.', _lightLogoGreen),
  ];

  static const priceModeSegments = [
    TypingTextSegment('Tu travailles\n', _lightLogoGreen),
    TypingTextSegment('en TTC\n', _darkLogoGreen),
    TypingTextSegment('ou en HT ?', _lightLogoGreen),
  ];

  static const timbreFiscalSegments = [
    TypingTextSegment('On ajoute\n', _lightLogoGreen),
    TypingTextSegment('le timbre\n', _darkLogoGreen),
    TypingTextSegment('fiscal ?', _lightLogoGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth < 520 ? 42.0 : 74.0;

        return Padding(
          // A small top padding keeps the question higher on the page, while
          // the bottom gap leaves room for the first field to appear below it.
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: AnimatedTypingRichText(
                key: ValueKey(questionKey),
                autoStart: active,
                caretColor: _lightLogoGreen,
                duration: const Duration(milliseconds: 1900),
                onFinished: onFinished,
                segments: segments,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: .96,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

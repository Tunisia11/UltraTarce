import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Text shown on the final onboarding page.
///
/// Edit this file when you want to change the final congratulations copy.
class CompletionCaption extends StatelessWidget {
  const CompletionCaption({super.key});

  static const _darkLogoGreen = Color(0xFF0B2F21);
  static const _lightLogoGreen = Color(0xFF6DAE35);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth < 520 ? 46.0 : 76.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: const [
                  TextSpan(
                    text: 'Félicitations,\n',
                    style: TextStyle(color: _lightLogoGreen),
                  ),
                  TextSpan(
                    text: 'tu peux\n',
                    style: TextStyle(color: _darkLogoGreen),
                  ),
                  TextSpan(
                    text: 'démarrer.',
                    style: TextStyle(color: _lightLogoGreen),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: .95,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ta base locale est prête. Appuie sur Démarrer pour ouvrir Trace Ultra sans perdre tes réglages de départ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        );
      },
    );
  }
}

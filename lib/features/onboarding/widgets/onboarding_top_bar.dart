import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.onSkip,
    this.allowSkip = false,
  });

  final VoidCallback onSkip;
  final bool allowSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppAssets.systemLogo,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        ),
        if (allowSkip)
          TextButton(onPressed: onSkip, child: const Text('Ignorer')),
      ],
    );
  }
}

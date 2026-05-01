import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';

/// Final onboarding mascot animation.
///
/// The GIF path lives in `AppAssets.celebrationMascot`, so you only need to
/// update one place if the file name changes later.
class CelebrationMascotGif extends StatelessWidget {
  const CelebrationMascotGif({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mascotte Trace Ultra qui célèbre la configuration terminée',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          AppAssets.celebrationMascot,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

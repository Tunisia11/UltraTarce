import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';

class WelcomeMascotImage extends StatelessWidget {
  const WelcomeMascotImage({
    super.key,
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mascotte de bienvenue Trace Ultra',
      image: true,
      child: Image.asset(
        AppAssets.welcomeMascot,
        height: height,
        width: width,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

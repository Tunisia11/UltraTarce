import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'animated_splash_shapes.dart';
import 'splash_loading_status.dart';
import 'splash_wordmark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: AnimatedSplashShapes()),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: SplashWordmark(),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 610,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [SplashLoadingStatus()],
                ),
              ),
            ),

            Positioned(
              left: 650,
              bottom: 50,
              child: Text(
                'Developed by Virex',
                style: TextStyle(
                  color: AppColors.subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

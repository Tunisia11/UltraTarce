import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'static_progress_bar.dart';

class SplashLoadingStatus extends StatefulWidget {
  const SplashLoadingStatus({super.key});

  @override
  State<SplashLoadingStatus> createState() => _SplashLoadingStatusState();
}

class _SplashLoadingStatusState extends State<SplashLoadingStatus>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Préparation de votre espace local',
    'Chargement du logo système',
    'Initialisation de votre espace...',
    'Synchronisation de la base locale',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final messageIndex = (progress * _messages.length).floor().clamp(
          0,
          _messages.length - 1,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StaticProgressBar(progress: progress),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Text(
                _messages[messageIndex],
                key: ValueKey(_messages[messageIndex]),
                style: const TextStyle(
                  color: AppColors.subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Progress page shown during cloud data checking / downloading.
class CloudBootstrapProgressPage extends StatelessWidget {
  const CloudBootstrapProgressPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 32),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez patienter, vos produits, clients et documents '
                'sont en cours de préparation.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/app_colors.dart';
import '../../auth/application/auth_cubit.dart';
import '../application/subscription_gate_cubit.dart';
import '../data/subscription_status_repository.dart';

class SubscriptionBlockedPage extends StatelessWidget {
  const SubscriptionBlockedPage({super.key, required this.statusModel});

  final SubscriptionStatusModel statusModel;

  @override
  Widget build(BuildContext context) {
    final isCancelled = statusModel.status == 'cancelled';
    final title = isCancelled ? 'Compte annulé' : 'Compte suspendu';
    final message = isCancelled
        ? 'Ce compte n’est plus actif. Contactez Virex.'
        : 'Votre accès Trace Ultra est suspendu. Contactez Virex pour réactiver votre compte.';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Trace Ultra'),
        backgroundColor: AppColors.surfaceHighest,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCancelled ? Icons.cancel_outlined : Icons.block,
                size: 64,
                color: isCancelled ? Colors.grey : AppColors.danger,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<SubscriptionGateCubit>().checkSubscription(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/app_colors.dart';
import '../data/subscription_status_repository.dart';
import '../application/subscription_gate_cubit.dart';
import '../application/subscription_gate_state.dart';
import 'subscription_blocked_page.dart';
import 'subscription_warning_banner.dart';

class SubscriptionGate extends StatelessWidget {
  const SubscriptionGate({
    super.key,
    required this.tenantId,
    required this.child,
    this.repository,
  });

  final String tenantId;
  final Widget child;
  final SubscriptionStatusRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionGateCubit(
        tenantId: tenantId,
        repository: repository ?? SubscriptionStatusRepository(),
      )..checkSubscription(),
      child: BlocBuilder<SubscriptionGateCubit, SubscriptionGateState>(
        builder: (context, state) {
          if (state is SubscriptionGateLoading) {
            return const Scaffold(
              backgroundColor: AppColors.surface,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is SubscriptionGateBlocked) {
            return SubscriptionBlockedPage(statusModel: state.status);
          }

          if (state is SubscriptionGateAllowed) {
            Widget content = child;

            if (state.isOfflineFallback) {
              content = Column(
                children: [
                  const SubscriptionWarningBanner(
                    message:
                        'Impossible de vérifier l’abonnement. Mode local temporaire.',
                    isError: true,
                  ),
                  Expanded(child: child),
                ],
              );
            } else if (state.showOverdueBanner) {
              content = Column(
                children: [
                  const SubscriptionWarningBanner(
                    message:
                        'Paiement en attente. Contactez Virex pour éviter la suspension.',
                    isError: true,
                  ),
                  Expanded(child: child),
                ],
              );
            } else if (state.showTrialBanner) {
              final dateStr = state.status.trialEndsAt != null
                  ? state.status.trialEndsAt.toString().split(' ')[0]
                  : 'bientôt';
              content = Column(
                children: [
                  SubscriptionWarningBanner(
                    message:
                        'Mode essai: votre période d’essai se termine le $dateStr.',
                  ),
                  Expanded(child: child),
                ],
              );
            }

            return content;
          }

          // Fallback allow
          return child;
        },
      ),
    );
  }
}

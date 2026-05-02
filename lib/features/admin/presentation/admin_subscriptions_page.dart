import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/admin_subscription_cubit.dart';
import '../application/admin_subscription_state.dart';
import 'widgets/admin_subscription_card.dart';
import 'widgets/admin_subscription_editor_dialog.dart';

class AdminSubscriptionsPage extends StatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AdminSubscriptionCubit>().loadSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSubscriptionCubit, AdminSubscriptionState>(
      builder: (context, state) {
        if (state is AdminSubscriptionLoading ||
            state is AdminSubscriptionInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminSubscriptionError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<AdminSubscriptionCubit>()
                      .loadSubscriptions(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state is AdminSubscriptionLoaded) {
          final subs = state.subscriptions.where((s) {
            final matchesSearch =
                s.tenantName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (s.ownerEmail != null &&
                    s.ownerEmail!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ));
            final matchesStatus =
                _filterStatus == 'all' || s.status == _filterStatus;
            return matchesSearch && matchesStatus;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Abonnements',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher par société ou email...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'trial',
                            child: Text('Essai'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Actifs'),
                          ),
                          DropdownMenuItem(
                            value: 'overdue',
                            child: Text('En retard'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspendus'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Annulés'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filterStatus = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: subs.isEmpty
                      ? const Center(child: Text('Aucun abonnement trouvé.'))
                      : ListView.builder(
                          itemCount: subs.length,
                          itemBuilder: (context, index) {
                            final s = subs[index];
                            return AdminSubscriptionCard(
                              subscription: s,
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AdminSubscriptionEditorDialog(
                                    subscription: s,
                                    onSave:
                                        ({
                                          required plan,
                                          required status,
                                          required billingCycle,
                                          priceTnd,
                                          seatsLimit,
                                          currentPeriodEndsAt,
                                          adminNotes,
                                        }) async {
                                          await context
                                              .read<AdminSubscriptionCubit>()
                                              .updateSubscription(
                                                tenantId: s.tenantId,
                                                plan: plan,
                                                status: status,
                                                billingCycle: billingCycle,
                                                priceTnd: priceTnd,
                                                seatsLimit: seatsLimit,
                                                currentPeriodEndsAt:
                                                    currentPeriodEndsAt,
                                                adminNotes: adminNotes,
                                              );
                                        },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

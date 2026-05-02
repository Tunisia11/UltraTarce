import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../application/admin_trial_requests_cubit.dart';
import '../data/admin_trial_request_repository.dart';

class AdminTrialRequestsPage extends StatelessWidget {
  const AdminTrialRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminTrialRequestsCubit, AdminTrialRequestsState>(
      builder: (context, state) {
        if (state is AdminTrialRequestsLoading ||
            state is AdminTrialRequestsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminTrialRequestsError) {
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }

        if (state is AdminTrialRequestsLoaded) {
          final requests = state.requests;

          if (requests.isEmpty) {
            return const Center(
              child: Text('Aucune demande d\'essai trouvée.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${request.companyName} - ${request.fullName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(request.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${request.email}'),
                      if (request.phone != null) Text('Tél: ${request.phone}'),
                      Text(
                        'Créé le: ${request.createdAt.toLocal().toString().split('.')[0]}',
                      ),
                      if (request.message != null &&
                          request.message!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Message:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(request.message!),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: request.status,
                            items: const [
                              DropdownMenuItem(
                                value: 'new',
                                child: Text('Nouveau'),
                              ),
                              DropdownMenuItem(
                                value: 'contacted',
                                child: Text('Contacté'),
                              ),
                              DropdownMenuItem(
                                value: 'approved',
                                child: Text('Approuvé'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejeté'),
                              ),
                              DropdownMenuItem(
                                value: 'converted',
                                child: Text('Converti'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                context
                                    .read<AdminTrialRequestsCubit>()
                                    .updateStatus(request.id, val);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Notes internes',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              controller: TextEditingController(
                                text: request.internalNotes,
                              ),
                              onSubmitted: (val) {
                                context
                                    .read<AdminTrialRequestsCubit>()
                                    .updateNotes(request.id, val);
                              },
                            ),
                          ),
                          if (request.status == 'approved') ...[
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showConversionInstructions(context, request);
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Convertir'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'new':
        color = Colors.blue;
        label = 'Nouveau';
        break;
      case 'contacted':
        color = Colors.orange;
        label = 'Contacté';
        break;
      case 'approved':
        color = AppColors.success;
        label = 'Approuvé';
        break;
      case 'rejected':
        color = AppColors.danger;
        label = 'Rejeté';
        break;
      case 'converted':
        color = Colors.purple;
        label = 'Converti';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showConversionInstructions(BuildContext context, TrialRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertir en utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pour le MVP, créez l\'utilisateur manuellement via le dashboard Supabase :',
            ),
            const SizedBox(height: 16),
            const Text('1. Allez dans Supabase > Authentication > Users'),
            const Text('2. Ajoutez un utilisateur avec l\'email :'),
            SelectableText(
              request.email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '3. Le locataire sera créé automatiquement lors de sa première connexion s\'il a été invité, ou vous pouvez l\'ajouter manuellement dans la table team_members.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Plus tard, une automatisation Cloud Function pourra le faire.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

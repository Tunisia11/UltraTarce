import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';

class ClientsState {
  const ClientsState({
    required this.clients,
    required this.filteredClients,
    this.query = '',
  });

  factory ClientsState.initial() =>
      const ClientsState(clients: [], filteredClients: []);

  final List<Partner> clients;
  final List<Partner> filteredClients;
  final String query;
}

class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit(this._clientRepository, this._auditRepository)
    : super(ClientsState.initial());

  final ClientRepository _clientRepository;
  final AuditRepository _auditRepository;

  void loadClients() {
    final clients = _clientRepository.getAll();
    emit(ClientsState(clients: clients, filteredClients: clients));
  }

  void searchClients(String query) {
    emit(
      ClientsState(
        clients: _clientRepository.getAll(),
        filteredClients: _clientRepository.search(query),
        query: query,
      ),
    );
  }

  AppSnapshot createClient(Partner client) {
    _clientRepository.upsert(
      client.copyWith(type: PartnerType.client),
      status: 'Client sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Création tiers',
      target: client.name,
      detail: PartnerType.client.label,
    );
    loadClients();
    return snapshot;
  }

  AppSnapshot updateClient(Partner client) {
    _clientRepository.upsert(
      client.copyWith(type: PartnerType.client),
      status: 'Client sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Modification tiers',
      target: client.name,
      detail: PartnerType.client.label,
    );
    loadClients();
    return snapshot;
  }

  AppSnapshot archiveClient(Partner client) {
    _clientRepository.archive(client, status: 'Tiers sauvegardés.');
    final snapshot = _appendAudit(
      action: 'Désactivation tiers',
      target: client.name,
      detail: PartnerType.client.label,
    );
    loadClients();
    return snapshot;
  }

  AppSnapshot deleteOrArchiveClient(Partner client) {
    final used = _clientRepository.isUsed(client.id);
    if (used) {
      _clientRepository.archive(client, status: 'Tiers sauvegardés.');
    } else {
      _clientRepository.delete(client, status: 'Tiers sauvegardés.');
    }
    final snapshot = _appendAudit(
      action: used ? 'Désactivation tiers' : 'Suppression tiers',
      target: client.name,
      detail: PartnerType.client.label,
    );
    loadClients();
    return snapshot;
  }

  Partner createComptoirClientIfNeeded({String id = 'client-comptoir'}) {
    for (final client in _clientRepository.getAll()) {
      if (client.name.toLowerCase() == 'client comptoir') return client;
    }
    final client = Partner(
      id: id,
      type: PartnerType.client,
      name: 'Client comptoir',
      taxId: '',
      address: '',
      phone: '',
      email: '',
    );
    createClient(client);
    return client;
  }

  AppSnapshot _appendAudit({
    required String action,
    required String target,
    required String detail,
  }) {
    return _auditRepository.saveAll(
      AuditService.append(
        events: _auditRepository.getAll(),
        action: action,
        target: target,
        detail: detail,
      ),
      status: 'Audit sauvegardé.',
    );
  }
}

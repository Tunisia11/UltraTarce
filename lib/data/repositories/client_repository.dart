import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import '../local/database/app_database.dart';
import '../local/database/mappers/partner_mapper.dart';
import 'app_repository.dart';

class ClientRepository {
  ClientRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Partner> getAll() => _appRepository.snapshot.partners
      .where((partner) => partner.type == PartnerType.client)
      .toList();

  List<Partner> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();
    return getAll()
        .where(
          (client) =>
              client.name.toLowerCase().contains(normalized) ||
              client.phone.toLowerCase().contains(normalized) ||
              client.taxId.toLowerCase().contains(normalized),
        )
        .toList();
  }

  bool isUsed(String clientId) {
    return _appRepository.snapshot.documents.any(
      (document) => document.partnerId == clientId,
    );
  }

  AppSnapshot upsert(Partner client, {required String status}) {
    return _savePartner(client.copyWith(type: PartnerType.client), status);
  }

  AppSnapshot archive(Partner client, {required String status}) {
    return upsert(client.copyWith(active: false), status: status);
  }

  AppSnapshot delete(Partner client, {required String status}) {
    final partners = List<Partner>.from(_appRepository.snapshot.partners)
      ..removeWhere((item) => item.id == client.id);
    return _commitPartners(
      partners,
      status: status,
      write: (database) => database.partnerDao.deletePartner(
        client.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot _savePartner(Partner partner, String status) {
    final partners = List<Partner>.from(_appRepository.snapshot.partners);
    final index = partners.indexWhere((item) => item.id == partner.id);
    if (index >= 0) {
      partners[index] = partner;
    } else {
      partners.insert(0, partner);
    }
    return _commitPartners(
      partners,
      status: status,
      write: (database) => database.partnerDao.upsertPartner(
        PartnerMapper.toCompanion(partner, tenantId: _appRepository.tenantId),
      ),
    );
  }

  AppSnapshot _commitPartners(
    List<Partner> partners, {
    required String status,
    required Future<void> Function(AppDatabase database) write,
  }) {
    return _appRepository.commitDaoMutation(
      _snapshotWithPartners(_appRepository.snapshot, partners),
      status: status,
      write: (database) => write(database),
    );
  }

  AppSnapshot _snapshotWithPartners(
    AppSnapshot snapshot,
    List<Partner> partners,
  ) {
    return AppSnapshot(
      company: snapshot.company,
      warehouses: snapshot.warehouses,
      categories: snapshot.categories,
      products: snapshot.products,
      partners: partners,
      documents: snapshot.documents,
      movements: snapshot.movements,
      sequences: snapshot.sequences,
      auditEvents: snapshot.auditEvents,
    );
  }
}

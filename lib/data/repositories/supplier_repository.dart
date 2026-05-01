import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import '../local/database/app_database.dart';
import '../local/database/mappers/partner_mapper.dart';
import 'app_repository.dart';

class SupplierRepository {
  SupplierRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Partner> getAll() => _appRepository.snapshot.partners
      .where((partner) => partner.type == PartnerType.supplier)
      .toList();

  List<Partner> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();
    return getAll()
        .where(
          (supplier) =>
              supplier.name.toLowerCase().contains(normalized) ||
              supplier.phone.toLowerCase().contains(normalized) ||
              supplier.taxId.toLowerCase().contains(normalized),
        )
        .toList();
  }

  bool isUsed(String supplierId) {
    return _appRepository.snapshot.documents.any(
      (document) => document.partnerId == supplierId,
    );
  }

  AppSnapshot upsert(Partner supplier, {required String status}) {
    return _savePartner(supplier.copyWith(type: PartnerType.supplier), status);
  }

  AppSnapshot archive(Partner supplier, {required String status}) {
    return upsert(supplier.copyWith(active: false), status: status);
  }

  AppSnapshot delete(Partner supplier, {required String status}) {
    final partners = List<Partner>.from(_appRepository.snapshot.partners)
      ..removeWhere((item) => item.id == supplier.id);
    return _commitPartners(
      partners,
      status: status,
      write: (database) => database.partnerDao.deletePartner(
        supplier.id,
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

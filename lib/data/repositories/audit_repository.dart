import '../../domain/app_models.dart';
import '../local/database/mappers/audit_mapper.dart';
import 'app_repository.dart';

class AuditRepository {
  AuditRepository(this._appRepository);

  final AppRepository _appRepository;

  List<AuditEvent> getAll() =>
      List<AuditEvent>.from(_appRepository.snapshot.auditEvents);

  AppSnapshot saveAll(List<AuditEvent> auditEvents, {required String status}) {
    final snapshot = _appRepository.snapshot;
    final previousIds = snapshot.auditEvents.map((event) => event.id).toSet();
    final nextIds = auditEvents.map((event) => event.id).toSet();
    final inserted = auditEvents
        .where((event) => !previousIds.contains(event.id))
        .toList();
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: snapshot.company,
        warehouses: snapshot.warehouses,
        categories: snapshot.categories,
        products: snapshot.products,
        partners: snapshot.partners,
        documents: snapshot.documents,
        movements: snapshot.movements,
        sequences: snapshot.sequences,
        auditEvents: auditEvents,
      ),
      status: status,
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        await database.transaction(() async {
          for (final event in inserted) {
            await database.auditDao.addAuditEvent(
              AuditMapper.toCompanion(event, tenantId: tenantId),
            );
          }
          await database.auditDao.deleteAuditEventsNotIn(
            nextIds,
            tenantId: tenantId,
          );
        });
      },
    );
  }
}

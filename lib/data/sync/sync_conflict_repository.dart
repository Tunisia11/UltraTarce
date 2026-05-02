import 'dart:async';
import 'package:drift/drift.dart';
import '../local/database/app_database.dart';
import 'sync_conflict_models.dart';

class SyncConflictRepository {
  SyncConflictRepository(this._database);

  final AppDatabase _database;
  final _changes = StreamController<void>.broadcast();
  Stream<void> watchChanges() => _changes.stream;

  Future<List<SyncConflict>> getOpenConflicts({
    required String tenantId,
  }) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT * FROM sync_conflicts 
      WHERE tenant_id = ? AND status = 'open'
      ORDER BY created_at DESC
      ''',
          variables: [Variable.withString(tenantId)],
        )
        .get();

    return rows.map(_mapRow).toList();
  }

  Future<SyncConflict?> getById(String id) async {
    final row = await _database
        .customSelect(
          'SELECT * FROM sync_conflicts WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  Future<int> countOpenConflicts({required String tenantId}) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT COUNT(*) as count FROM sync_conflicts 
      WHERE tenant_id = ? AND status = 'open'
      ''',
          variables: [Variable.withString(tenantId)],
        )
        .getSingle();

    return rows.read<int>('count');
  }

  Stream<int> watchConflictCount({required String tenantId}) async* {
    yield await countOpenConflicts(tenantId: tenantId);
    await for (final _ in _changes.stream) {
      yield await countOpenConflicts(tenantId: tenantId);
    }
  }

  Future<void> markAsIgnored(String id) async {
    await _database.customStatement(
      "UPDATE sync_conflicts SET status = 'ignored' WHERE id = ?",
      [id],
    );
    _changes.add(null);
  }

  Future<void> markAsResolved(String id, {required String resolution}) async {
    await _database.customStatement(
      '''
      UPDATE sync_conflicts 
      SET status = 'resolved', 
          resolved_at = ?,
          resolved_by = ?
      WHERE id = ?
      ''',
      [DateTime.now().toUtc().toIso8601String(), resolution, id],
    );
    _changes.add(null);
  }

  SyncConflict _mapRow(QueryRow row) {
    return SyncConflict(
      id: row.read<String>('id'),
      tenantId: row.read<String>('tenant_id'),
      entityType: row.read<String>('entity_type'),
      entityId: row.read<String>('entity_id'),
      reason: SyncConflictReason.values.firstWhere(
        (e) => e.name == row.read<String>('reason'),
        orElse: () => SyncConflictReason.localPendingRemoteChanged,
      ),
      status: SyncConflictStatus.values.firstWhere(
        (e) => e.name == row.read<String>('status'),
        orElse: () => SyncConflictStatus.open,
      ),
      localPayloadJson: row.readNullable<String>('local_payload_json'),
      remotePayloadJson: row.readNullable<String>('remote_payload_json'),
      localUpdatedAt: _dateFrom(row.readNullable<String>('local_updated_at')),
      remoteUpdatedAt: _dateFrom(row.readNullable<String>('remote_updated_at')),
      createdAt: _dateFrom(row.read<String>('created_at'))!,
      resolvedAt: _dateFrom(row.readNullable<String>('resolved_at')),
      resolvedBy: row.readNullable<String>('resolved_by'),
    );
  }

  DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse('$value');
  }

  void notifyChanges() {
    _changes.add(null);
  }
}

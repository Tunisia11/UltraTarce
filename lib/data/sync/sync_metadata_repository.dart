import 'package:drift/drift.dart';
import '../local/database/app_database.dart';

class SyncMetadataRepository {
  SyncMetadataRepository(this._database);
  final AppDatabase _database;

  Future<DateTime?> getLastPullCompletedAt(String tenantId) async {
    final rows = await _database
        .customSelect(
          'SELECT value_json FROM sync_metadata WHERE key = ? AND tenant_id = ?',
          variables: [
            Variable.withString('last_pull_completed_at'),
            Variable.withString(tenantId),
          ],
        )
        .get();
    if (rows.isEmpty) return null;
    final value = rows.first.data['value_json'] as String;
    return DateTime.tryParse(value);
  }

  Future<void> setLastPullCompletedAt(String tenantId, DateTime value) async {
    await _database.customStatement(
      'INSERT OR REPLACE INTO sync_metadata (key, tenant_id, value_json, updated_at) VALUES (?, ?, ?, ?)',
      [
        'last_pull_completed_at',
        tenantId,
        value.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<Map<String, dynamic>> getAllMetadata(String tenantId) async {
    final rows = await _database
        .customSelect(
          'SELECT key, value_json FROM sync_metadata WHERE tenant_id = ?',
          variables: [Variable.withString(tenantId)],
        )
        .get();
    return {
      for (final row in rows) row.data['key'] as String: row.data['value_json'],
    };
  }
}

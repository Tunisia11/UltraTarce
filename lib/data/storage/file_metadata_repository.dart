import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../local/database/app_database.dart';
import 'storage_result.dart';

class FileMetadataRepository {
  FileMetadataRepository(this._database);

  final AppDatabase _database;

  Future<void> saveMetadata({
    required String tenantId,
    required StorageResult storage,
    String? entityType,
    String? entityId,
    String? purpose,
    String? userId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _database.customStatement(
        '''
        INSERT INTO files (
          id, tenant_id, bucket, path, type, linked_entity_type, linked_entity_id, 
          file_name, mime_type, size_bytes, created_at, updated_at, created_by, updated_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(bucket, path) DO UPDATE SET
          type = excluded.type,
          linked_entity_type = excluded.linked_entity_type,
          linked_entity_id = excluded.linked_entity_id,
          file_name = excluded.file_name,
          mime_type = excluded.mime_type,
          size_bytes = excluded.size_bytes,
          updated_at = excluded.updated_at,
          updated_by = excluded.updated_by
      ''',
        [
          storage.path, // Use path as unique local ID
          tenantId,
          storage.bucket,
          storage.path,
          purpose, // mapped to type
          entityType, // mapped to linked_entity_type
          entityId, // mapped to linked_entity_id
          storage.fileName,
          storage.mimeType,
          storage.sizeBytes,
          now, // created_at
          now, // updated_at
          userId, // created_by
          userId, // updated_by
        ],
      );
    } catch (e) {
      debugPrint('[file_metadata_repository] ERROR saving metadata: $e');
      // Non-blocking error as requested
    }
  }

  Future<FileRow?> getMetadata(String bucket, String path) async {
    try {
      final rows = await _database
          .customSelect(
            'SELECT * FROM files WHERE bucket = ? AND path = ?',
            variables: [Variable.withString(bucket), Variable.withString(path)],
          )
          .get();

      if (rows.isEmpty) return null;
      return FileRow.fromMap(rows.first.data);
    } catch (e) {
      debugPrint('[file_metadata_repository] ERROR getting metadata: $e');
      return null;
    }
  }

  Future<List<FileRow>> getFilesForEntity(
    String entityType,
    String entityId,
  ) async {
    try {
      final rows = await _database
          .customSelect(
            'SELECT * FROM files WHERE linked_entity_type = ? AND linked_entity_id = ? ORDER BY created_at DESC',
            variables: [
              Variable.withString(entityType),
              Variable.withString(entityId),
            ],
          )
          .get();

      return rows.map((r) => FileRow.fromMap(r.data)).toList();
    } catch (e) {
      debugPrint(
        '[file_metadata_repository] ERROR getting files for entity: $e',
      );
      return [];
    }
  }
}

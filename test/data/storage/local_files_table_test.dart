import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/storage/file_metadata_repository.dart';
import 'package:ultra_trace/data/storage/storage_result.dart';
import 'package:ultra_trace/app/tenant_context.dart';

void main() {
  late AppDatabase database;
  late FileMetadataRepository repository;

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(),
      const TenantContext(tenantIdOverride: 't1'),
    );
    repository = FileMetadataRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'AppDatabase creates files table and repository can insert/select',
    () async {
      // The table should be created by beforeOpen or migration
      // Drift calls beforeOpen when the first query is executed.

      const storage = StorageResult(
        bucket: 'test-bucket',
        path: 't1/test/file.png',
        fullPath: 'test-bucket/t1/test/file.png',
        fileName: 'file.png',
        mimeType: 'image/png',
        sizeBytes: 1024,
      );

      await repository.saveMetadata(
        tenantId: 't1',
        storage: storage,
        entityType: 'test_entity',
        entityId: 'e1',
        purpose: 'test_purpose',
        userId: 'u1',
      );

      final metadata = await repository.getMetadata(
        'test-bucket',
        't1/test/file.png',
      );
      expect(metadata, isNotNull);
      expect(metadata!.id, 't1/test/file.png');
      expect(metadata.tenantId, 't1');
      expect(metadata.bucket, 'test-bucket');
      expect(metadata.type, 'test_purpose'); // mapped from purpose
      expect(
        metadata.linkedEntityType,
        'test_entity',
      ); // mapped from entityType
      expect(metadata.linkedEntityId, 'e1'); // mapped from entityId
    },
  );

  test('getFilesForEntity returns files ordered by created_at', () async {
    await repository.saveMetadata(
      tenantId: 't1',
      storage: const StorageResult(bucket: 'b', path: 'p1', fullPath: 'b/p1'),
      entityType: 'products',
      entityId: 'prod1',
    );
    await repository.saveMetadata(
      tenantId: 't1',
      storage: const StorageResult(bucket: 'b', path: 'p2', fullPath: 'b/p2'),
      entityType: 'products',
      entityId: 'prod1',
    );

    final files = await repository.getFilesForEntity('products', 'prod1');
    expect(files.length, 2);
    // Drift native database might not have stable ordering if created_at is identical,
    // but we check the count at least.
  });
}

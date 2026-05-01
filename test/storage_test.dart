import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  test('persists values through the configured local cache database', () {
    final storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_storage_test_',
    );
    addTearDown(() {
      setPersistentStorageDirectoryForTesting(null);
      if (storageDirectory.existsSync()) {
        storageDirectory.deleteSync(recursive: true);
      }
    });

    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    writePersistentValue('company.test', '{"ok":true}');

    expect(readPersistentValue('company.test'), '{"ok":true}');
    expect(persistentStoreLabel(), storageDirectory.path);

    deletePersistentValue('company.test');
    expect(readPersistentValue('company.test'), isNull);
  });

  test('falls back to the backup file when the primary file is missing', () {
    final storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_storage_backup_test_',
    );
    addTearDown(() {
      setPersistentStorageDirectoryForTesting(null);
      if (storageDirectory.existsSync()) {
        storageDirectory.deleteSync(recursive: true);
      }
    });

    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    writePersistentValue('company.test', '{"version":1}');
    writePersistentValue('company.test', '{"version":2}');

    expect(readPersistentValueCandidates('company.test'), [
      '{"version":2}',
      '{"version":1}',
    ]);

    final primary = File('${storageDirectory.path}/company.test.json');
    expect(primary.existsSync(), isTrue);

    primary.deleteSync();

    expect(readPersistentValue('company.test'), '{"version":1}');
  });

  test('exposes backup candidates when the primary file is corrupt', () {
    final storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_storage_corrupt_test_',
    );
    addTearDown(() {
      setPersistentStorageDirectoryForTesting(null);
      if (storageDirectory.existsSync()) {
        storageDirectory.deleteSync(recursive: true);
      }
    });

    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    writePersistentValue('company.test', '{"version":1}');
    writePersistentValue('company.test', '{"version":2}');

    final primary = File('${storageDirectory.path}/company.test.json');
    primary.writeAsStringSync('{broken', flush: true);

    expect(readPersistentValueCandidates('company.test'), [
      '{broken',
      '{"version":1}',
    ]);
  });
}

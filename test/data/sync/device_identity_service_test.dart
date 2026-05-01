import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_device_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('creates and persists stable local device id', () {
    const service = DeviceIdentityService();

    final first = service.resolve();
    final second = service.resolve();

    expect(first.deviceId, startsWith('device_'));
    expect(second.deviceId, first.deviceId);
    expect(first.platform, isNotEmpty);
    expect(first.appVersion, isNotEmpty);
  });
}

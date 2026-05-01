import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../storage/app_storage.dart';
import '../../storage/app_storage_keys.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;
  final String platform;
  final String appVersion;
}

class DeviceIdentityService {
  const DeviceIdentityService();

  static const _appVersion = String.fromEnvironment(
    'TRACE_APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  DeviceIdentity resolve() {
    return DeviceIdentity(
      deviceId: getOrCreateDeviceId(),
      platform: platformName,
      appVersion: _appVersion,
    );
  }

  String getOrCreateDeviceId() {
    final stored = readPersistentValue(syncDeviceIdStorageKey)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final generated = _generateDeviceId();
    writePersistentValue(syncDeviceIdStorageKey, generated);
    return generated;
  }

  String get platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      _ => 'unknown',
    };
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'device_$hex';
  }
}

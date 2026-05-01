import '../storage/app_storage.dart';
import '../storage/app_storage_keys.dart';
import 'app_config.dart';

class TenantContext {
  const TenantContext({
    this.tenantIdOverride,
    this.tenantNameOverride,
    this.userIdOverride,
    this.authBypassOverride,
  });

  factory TenantContext.current({AppConfig? config}) {
    return TenantContext(authBypassOverride: config?.authBypassEnabled);
  }

  static const legacyTenantId = 'local_legacy_tenant';
  static const legacyTenantName = 'Société locale';
  static const devBypassTenantId = 'local-demo-tenant';
  static const devBypassTenantName = 'Société locale';
  static const localWorkspaceMode = 'compat_local_drift';

  final String? tenantIdOverride;
  final String? tenantNameOverride;
  final String? userIdOverride;
  final bool? authBypassOverride;

  String get selectedTenantId {
    final override = _clean(tenantIdOverride);
    if (override != null) return override;

    final stored = _clean(readPersistentValue(selectedTenantIdStorageKey));
    if (stored != null) return stored;

    if (authBypassOverride ?? const bool.fromEnvironment('TRACE_AUTH_BYPASS')) {
      return devBypassTenantId;
    }
    return legacyTenantId;
  }

  String get selectedTenantName {
    final override = _clean(tenantNameOverride);
    if (override != null) return override;

    final stored = _clean(readPersistentValue(selectedTenantNameStorageKey));
    if (stored != null) return stored;

    return isDevBypassTenantActive ? devBypassTenantName : legacyTenantName;
  }

  String get selectedUserId {
    final override = _clean(userIdOverride);
    if (override != null) return override;
    return _clean(readPersistentValue(selectedUserIdStorageKey)) ??
        'local-user';
  }

  bool get isDevBypassTenantActive =>
      selectedTenantId == devBypassTenantId ||
      (authBypassOverride ?? const bool.fromEnvironment('TRACE_AUTH_BYPASS'));

  bool get isLegacyLocalWorkspace =>
      selectedTenantId == legacyTenantId ||
      readPersistentValue(localWorkspaceModeStorageKey) == localWorkspaceMode;

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

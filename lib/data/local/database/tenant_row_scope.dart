class TenantRowScope {
  const TenantRowScope._();

  static const separator = '::';
  static const settingPrefix = 'tenant:';
  static const globalSettingPrefix = 'global:';

  static String rowId(String tenantId, String id) {
    final value = id.trim();
    if (value.isEmpty) return value;
    final prefix = '$tenantId$separator';
    if (value.startsWith(prefix)) return value;
    return '$prefix$value';
  }

  static String? nullableRowId(String tenantId, String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return rowId(tenantId, id);
  }

  static String domainId(String tenantId, String id) {
    final prefix = '$tenantId$separator';
    return id.startsWith(prefix) ? id.substring(prefix.length) : id;
  }

  static String? nullableDomainId(String tenantId, String? id) {
    if (id == null || id.isEmpty) return id;
    return domainId(tenantId, id);
  }

  static String settingKey(String tenantId, String key) {
    final value = key.trim();
    if (value.startsWith(settingPrefix) ||
        value.startsWith(globalSettingPrefix)) {
      return value;
    }
    return '$settingPrefix$tenantId$separator$value';
  }

  static String globalSettingKey(String key) {
    final value = key.trim();
    if (value.startsWith(globalSettingPrefix)) return value;
    return '$globalSettingPrefix$value';
  }
}

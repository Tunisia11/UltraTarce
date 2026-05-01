part of '../app_database.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getSetting(
    String key, {
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final scopedKey = TenantRowScope.settingKey(tenantId, key);
    final row =
        await (select(settings)..where(
              (table) =>
                  table.key.equals(scopedKey) & table.tenantId.equals(tenantId),
            ))
            .getSingleOrNull();
    return row?.valueJson;
  }

  Future<void> setSetting(
    String key,
    String valueJson, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final scopedKey = TenantRowScope.settingKey(tenantId, key);
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(scopedKey),
        tenantId: Value(tenantId),
        valueJson: Value(valueJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getGlobalSetting(String key) async {
    final row =
        await (select(settings)..where(
              (table) =>
                  table.key.equals(TenantRowScope.globalSettingKey(key)) &
                  table.tenantId.equals('global'),
            ))
            .getSingleOrNull();
    return row?.valueJson;
  }

  Future<void> setGlobalSetting(String key, String valueJson) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(TenantRowScope.globalSettingKey(key)),
        tenantId: const Value('global'),
        valueJson: Value(valueJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

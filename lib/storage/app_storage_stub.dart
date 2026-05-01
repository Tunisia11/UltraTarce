final Map<String, String> _memoryStorage = {};

String? readPersistentValue(String key) {
  final candidates = readPersistentValueCandidates(key);
  if (candidates.isNotEmpty) return candidates.first;
  return null;
}

List<String> readPersistentValueCandidates(String key) {
  final primary = _memoryStorage[key];
  final backup = _memoryStorage[_backupKey(key)];
  return [?primary, if (backup != primary) ?backup];
}

void writePersistentValue(String key, String value) {
  final current = _memoryStorage[key];
  if (current != null) {
    _memoryStorage[_backupKey(key)] = current;
  }
  _memoryStorage[key] = value;
}

void deletePersistentValue(String key) {
  _memoryStorage.remove(key);
  _memoryStorage.remove(_backupKey(key));
}

String persistentStoreLabel() => 'Mémoire locale de test';

void setPersistentStorageDirectoryForTesting(String? path) {}

String _backupKey(String key) => '$key.__bak';

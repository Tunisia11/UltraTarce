import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('localStorage.setItem')
external void _setItem(JSString key, JSString value);

@JS('localStorage.removeItem')
external void _removeItem(JSString key);

String? readPersistentValue(String key) {
  final candidates = readPersistentValueCandidates(key);
  if (candidates.isNotEmpty) return candidates.first;
  return null;
}

List<String> readPersistentValueCandidates(String key) {
  final primary = _getItem(key.toJS)?.toDart;
  final backup = _getItem(_backupKey(key).toJS)?.toDart;
  return [?primary, if (backup != primary) ?backup];
}

void writePersistentValue(String key, String value) {
  final current = _getItem(key.toJS)?.toDart;
  if (current != null) {
    _setItem(_backupKey(key).toJS, current.toJS);
  }
  _setItem(key.toJS, value.toJS);
}

void deletePersistentValue(String key) {
  _removeItem(key.toJS);
  _removeItem(_backupKey(key).toJS);
}

String persistentStoreLabel() => 'Navigateur localStorage';

void setPersistentStorageDirectoryForTesting(String? path) {}

String _backupKey(String key) => '$key.__bak';

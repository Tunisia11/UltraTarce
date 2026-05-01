import 'dart:io';

String? _overrideDirectory;

String? readPersistentValue(String key) {
  final candidates = readPersistentValueCandidates(key);
  if (candidates.isNotEmpty) return candidates.first;
  return null;
}

List<String> readPersistentValueCandidates(String key) {
  final values = <String>[];
  final file = _fileForKey(key);
  try {
    if (file.existsSync()) {
      values.add(file.readAsStringSync());
    }
  } catch (_) {}

  final backupFile = _backupFileForKey(key);
  try {
    if (backupFile.existsSync()) {
      final backup = backupFile.readAsStringSync();
      if (!values.contains(backup)) values.add(backup);
    }
  } catch (_) {}

  return values;
}

void writePersistentValue(String key, String value) {
  final file = _fileForKey(key);
  final tempFile = _tempFileForKey(key);
  final backupFile = _backupFileForKey(key);
  file.parent.createSync(recursive: true);
  _restrictToOwner(file.parent.path, directory: true);
  tempFile.writeAsStringSync(value, flush: true);
  _restrictToOwner(tempFile.path);

  if (file.existsSync()) {
    file.copySync(backupFile.path);
    _restrictToOwner(backupFile.path);
  }

  try {
    tempFile.renameSync(file.path);
  } on FileSystemException {
    if (file.existsSync()) {
      file.deleteSync();
    }
    tempFile.renameSync(file.path);
  }

  _restrictToOwner(file.path);
}

void deletePersistentValue(String key) {
  final file = _fileForKey(key);
  if (file.existsSync()) file.deleteSync();

  final backupFile = _backupFileForKey(key);
  if (backupFile.existsSync()) backupFile.deleteSync();

  final tempFile = _tempFileForKey(key);
  if (tempFile.existsSync()) tempFile.deleteSync();
}

String persistentStoreLabel() => _fileForKey('app').parent.path;

void setPersistentStorageDirectoryForTesting(String? path) {
  _overrideDirectory = path;
}

File _fileForKey(String key) {
  final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  return File('${_baseDirectory().path}${Platform.pathSeparator}$safeKey.json');
}

File _backupFileForKey(String key) => File('${_fileForKey(key).path}.bak');

File _tempFileForKey(String key) => File('${_fileForKey(key).path}.tmp');

Directory _baseDirectory() {
  if (_overrideDirectory != null) return Directory(_overrideDirectory!);

  final env = Platform.environment;
  if (Platform.isWindows) {
    final appData = env['APPDATA'] ?? env['LOCALAPPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData${Platform.pathSeparator}TraceUltra');
    }
  }

  if (Platform.isMacOS) {
    final home = env['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(
        '$home${Platform.pathSeparator}Library${Platform.pathSeparator}Application Support${Platform.pathSeparator}TraceUltra',
      );
    }
  }

  final xdgData = env['XDG_DATA_HOME'];
  if (xdgData != null && xdgData.isNotEmpty) {
    return Directory('$xdgData${Platform.pathSeparator}TraceUltra');
  }

  final home = env['HOME'] ?? Directory.current.path;
  return Directory(
    '$home${Platform.pathSeparator}.local${Platform.pathSeparator}share${Platform.pathSeparator}TraceUltra',
  );
}

void _restrictToOwner(String path, {bool directory = false}) {
  if (Platform.isWindows) return;
  try {
    Process.runSync('chmod', [directory ? '700' : '600', path]);
  } catch (_) {}
}

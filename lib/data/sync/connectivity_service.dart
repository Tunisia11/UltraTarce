import 'dart:async';

class ConnectivitySnapshot {
  const ConnectivitySnapshot({required this.isOnline});

  final bool isOnline;
}

class ConnectivityService {
  ConnectivityService({bool initialOnline = true}) : _isOnline = initialOnline;

  final _controller = StreamController<ConnectivitySnapshot>.broadcast();
  bool _isOnline;

  bool get isOnline => _isOnline;

  Stream<ConnectivitySnapshot> get changes async* {
    yield ConnectivitySnapshot(isOnline: _isOnline);
    yield* _controller.stream;
  }

  Future<ConnectivitySnapshot> checkNow() async {
    return ConnectivitySnapshot(isOnline: _isOnline);
  }

  void setOnlineForTesting(bool isOnline) {
    if (_isOnline == isOnline) return;
    _isOnline = isOnline;
    _controller.add(ConnectivitySnapshot(isOnline: isOnline));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

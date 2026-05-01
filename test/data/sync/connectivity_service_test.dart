import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/sync/connectivity_service.dart';

void main() {
  test('falls back to online and can report offline state', () async {
    final service = ConnectivityService();

    expect((await service.checkNow()).isOnline, isTrue);

    final states = <bool>[];
    final subscription = service.changes.listen(
      (state) => states.add(state.isOnline),
    );
    service.setOnlineForTesting(false);

    await expectLater(
      Stream.periodic(
        const Duration(milliseconds: 1),
        (_) => states.contains(false),
      ).where((value) => value),
      emits(true),
    );

    await subscription.cancel();
    await service.dispose();
  });
}

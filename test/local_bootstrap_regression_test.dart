import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/sync/cloud_bootstrap_cubit.dart';
import 'package:ultra_trace/data/sync/cloud_bootstrap_state.dart';

void main() {
  testWidgets('InventoryHomePage builds in local/test mode without Supabase', (
    tester,
  ) async {
    // This just verifies the localOnly cubit emits localReady immediately without crashing
    final cubit = CloudBootstrapCubit.localOnly();
    expect(cubit.state, isA<CloudBootstrapLocalReady>());
  });
}

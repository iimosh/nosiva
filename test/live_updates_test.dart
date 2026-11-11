import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/live/live_updates.dart';

void main() {
  testWidgets('fetches on listen, again on a ping, and only emits changes',
      (tester) async {
    final live = LiveUpdates();
    addTearDown(live.dispose);
    var calls = 0;
    var value = ['a'];
    final seen = <List<String>>[];

    final sub = live
        .watch(() async {
          calls++;
          return List.of(value);
        }, every: const Duration(seconds: 30))
        .listen(seen.add);

    await tester.pump();
    expect(calls, 1);
    expect(seen, [
      ['a']
    ]);

    live.ping(); // nothing changed: fetched, but not emitted again
    await tester.pump();
    expect(calls, 2);
    expect(seen.length, 1);

    value = ['a', 'b']; // a new message arrived
    live.ping();
    await tester.pump();
    expect(seen.last, ['a', 'b']);
    unawaited(sub.cancel());
    await tester.pump();
  });

  testWidgets('refreshes on its timer', (tester) async {
    final live = LiveUpdates();
    addTearDown(live.dispose);
    var calls = 0;
    final sub = live
        .watch(() async => ++calls, every: const Duration(seconds: 3))
        .listen((_) {});

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 3);
    unawaited(sub.cancel());
    await tester.pump();
  });

  testWidgets('a failed refresh keeps the last good result', (tester) async {
    final live = LiveUpdates();
    addTearDown(live.dispose);
    var fail = false;
    final values = <int>[];
    final errors = <Object>[];
    final sub = live.watch(() async {
      if (fail) throw StateError('offline');
      return 1;
    }, every: const Duration(seconds: 30)).listen(values.add, onError: errors.add);

    await tester.pump();
    fail = true;
    live.ping();
    await tester.pump();
    expect(values, [1]);
    expect(errors, isEmpty);
    unawaited(sub.cancel());
    await tester.pump();
  });
}

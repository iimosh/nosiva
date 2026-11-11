import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps screens fresh without a realtime connection (Neon has none the app
/// can use yet).
///
/// Lists refresh:
///   * straight away when something happens: a push notification arrives,
///     the app comes back to the foreground, or the person does something
///     (see [ping]);
///   * and on a timer while the app is open — every few seconds for an
///     open chat, less often for everything else.
/// Nothing is checked while the app is in the background, so it costs no
/// battery or data then.
class LiveUpdates {
  LiveUpdates() {
    _lifecycle = AppLifecycleListener(onResume: ping);
  }

  final _pings = StreamController<void>.broadcast();
  late final AppLifecycleListener _lifecycle;

  Stream<void> get pings => _pings.stream;

  /// Something may have changed: refresh what's on screen.
  void ping() {
    if (!_pings.isClosed) _pings.add(null);
  }

  void dispose() {
    _lifecycle.dispose();
    _pings.close();
  }

  static bool get _inForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  /// A stream of [fetch]'s result: fetched once on listen, then again on
  /// every [ping] and every [every] while the app is in the foreground.
  /// Only changed results are emitted, so screens don't rebuild for
  /// nothing. A failed refresh (e.g. offline) keeps the last good result.
  Stream<T> watch<T>(Future<T> Function() fetch, {required Duration every}) {
    late StreamController<T> controller;
    StreamSubscription<void>? sub;
    Timer? timer;
    var hasValue = false;
    T? last;
    var running = false;
    var again = false;

    Future<void> run() async {
      if (running) {
        again = true;
        return;
      }
      running = true;
      try {
        do {
          again = false;
          try {
            final value = await fetch();
            if (controller.isClosed) return;
            if (!hasValue || !const DeepCollectionEquality().equals(value, last)) {
              hasValue = true;
              last = value;
              controller.add(value);
            }
          } catch (e, st) {
            if (!hasValue && !controller.isClosed) controller.addError(e, st);
          }
        } while (again && !controller.isClosed);
      } finally {
        running = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        run();
        sub = pings.listen((_) => run());
        timer = Timer.periodic(every, (_) {
          if (_inForeground) run();
        });
      },
      onCancel: () {
        sub?.cancel();
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}

final liveUpdatesProvider = Provider<LiveUpdates>((ref) {
  final live = LiveUpdates();
  ref.onDispose(live.dispose);
  return live;
});

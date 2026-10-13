import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// Emits whether the phone has any network (Wi-Fi, mobile data, …) switched
/// on: once at start, then on every change. Overridden in tests.
final networkAvailableProvider = Provider<Stream<bool>>((ref) async* {
  final connectivity = Connectivity();
  bool hasNetwork(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  yield hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(hasNetwork);
});

/// Checks the internet actually works, not just that Wi-Fi is on (a café
/// network that needs a login, or mobile data with no credit, looks
/// "connected" but isn't). Overridden in tests.
final internetProbeProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    // Browsers can't look up addresses; trust the network state there.
    if (kIsWeb) return true;
    try {
      final host = Uri.parse(Env.supabaseUrl).host;
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  };
});

/// True while the app can't reach the internet. Drives the "No internet
/// connection" bar shown above every screen.
final isOfflineProvider =
    NotifierProvider<ConnectionStatus, bool>(ConnectionStatus.new);

class ConnectionStatus extends Notifier<bool> {
  /// Switching from Wi-Fi to mobile data briefly reports "no network";
  /// waiting this long before saying "offline" avoids a flash of the bar.
  static const gracePeriod = Duration(seconds: 2);

  /// While offline with a network switched on, how often to check again.
  static const recheckEvery = Duration(seconds: 8);

  Timer? _grace;
  Timer? _recheck;
  int _probeId = 0;

  @override
  bool build() {
    final sub = ref.watch(networkAvailableProvider).listen(_onNetwork);
    ref.onDispose(() {
      sub.cancel();
      _grace?.cancel();
      _recheck?.cancel();
    });
    return false;
  }

  void _onNetwork(bool available) {
    _grace?.cancel();
    _recheck?.cancel();
    if (available) {
      _probe();
    } else {
      _probeId++; // any probe still running is now out of date
      _grace = Timer(gracePeriod, () => state = true);
    }
  }

  Future<void> _probe() async {
    final id = ++_probeId;
    final online = await ref.read(internetProbeProvider)();
    if (id != _probeId) return;
    state = !online;
    if (!online) _recheck = Timer(recheckEvery, _probe);
  }
}

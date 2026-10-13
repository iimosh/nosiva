import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/network/connection_status.dart';
import 'package:nosiva/features/auth/presentation/splash_screen.dart';
import 'package:nosiva/l10n/app_localizations.dart';
import 'package:nosiva/shell/connection_banner.dart';

void main() {
  late StreamController<bool> network;
  late bool internetWorks;
  late ProviderContainer container;

  setUp(() {
    network = StreamController<bool>();
    internetWorks = true;
    container = ProviderContainer(overrides: [
      networkAvailableProvider.overrideWithValue(network.stream),
      internetProbeProvider.overrideWithValue(() async => internetWorks),
      introFinishedProvider.overrideWith((ref) => true),
    ]);
  });

  tearDown(() {
    container.dispose();
    network.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => ConnectionBanner(child: child!),
        home: const Scaffold(body: Text('screen')),
      ),
    ));
  }

  testWidgets('a quick network switch does not flash the offline bar',
      (tester) async {
    await pumpApp(tester);
    network.add(true);
    await tester.pump();

    network.add(false); // Wi-Fi drops while switching to mobile data…
    await tester.pump(const Duration(milliseconds: 500));
    network.add(true); // …and mobile data takes over.
    await tester.pump(const Duration(seconds: 3));

    expect(container.read(isOfflineProvider), isFalse);
    expect(find.text('No internet connection'), findsNothing);
  });

  testWidgets('shows the bar when offline, then "Back online" briefly',
      (tester) async {
    await pumpApp(tester);
    network.add(true);
    await tester.pump();

    network.add(false);
    await tester.pump(ConnectionStatus.gracePeriod);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(isOfflineProvider), isTrue);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('screen'), findsOneWidget); // the screen stays usable

    network.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Back online'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3)); // hides after 2 s…
    await tester.pump(const Duration(milliseconds: 300)); // …and slides away
    expect(find.text('Back online'), findsNothing);
  });

  testWidgets('Wi-Fi on but no internet counts as offline, and is rechecked',
      (tester) async {
    await pumpApp(tester);
    internetWorks = false;
    network.add(true);
    await tester.pump();
    expect(container.read(isOfflineProvider), isTrue);

    internetWorks = true;
    await tester.pump(ConnectionStatus.recheckEvery);
    expect(container.read(isOfflineProvider), isFalse);
    await tester.pump(const Duration(seconds: 3));
  });
}

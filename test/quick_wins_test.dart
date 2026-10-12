import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/widgets/pull_to_refresh.dart';
import 'package:nosiva/shell/scroll_to_top.dart';

void main() {
  group('PullToRefresh', () {
    Future<bool> pullDown(WidgetTester tester, Widget child) async {
      var refreshed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PullToRefresh(
            onRefresh: () async => refreshed = true,
            child: child,
          ),
        ),
      ));
      await tester.fling(find.byType(Scaffold), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      return refreshed;
    }

    testWidgets('works on a list', (tester) async {
      final refreshed = await pullDown(
        tester,
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [ListTile(title: Text('item'))],
        ),
      );
      expect(refreshed, isTrue);
    });

    testWidgets('works on an empty state that does not scroll', (tester) async {
      final refreshed = await pullDown(
        tester,
        const Center(child: Text('Nothing here yet')),
      );
      expect(refreshed, isTrue);
    });
  });

  testWidgets('tapping the open tab again scrolls its list to the top',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: ScrollToTopOnReselect(
            tab: 3,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
            ),
          ),
        ),
      ),
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsNothing);

    // Another tab: nothing happens.
    container.read(tabReselectedProvider.notifier).state = (tab: 1, count: 1);
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsNothing);

    container.read(tabReselectedProvider.notifier).state = (tab: 3, count: 2);
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsOneWidget);
  });
}

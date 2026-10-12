import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fired when the bottom-bar tab that's already open is tapped again.
/// `count` changes on every tap so repeated taps still notify.
final tabReselectedProvider =
    StateProvider<({int tab, int count})?>((ref) => null);

const _scrollDuration = Duration(milliseconds: 450);

/// Wraps a tab's screen: tapping that tab again scrolls its main list back
/// to the top, as in most apps.
///
/// Lists on the screen that don't have their own controller pick up the one
/// provided here automatically (a screen with its own controller, like the
/// home feed, listens to [tabReselectedProvider] itself).
class ScrollToTopOnReselect extends ConsumerStatefulWidget {
  const ScrollToTopOnReselect({super.key, required this.tab, required this.child});

  final int tab;
  final Widget child;

  @override
  ConsumerState<ScrollToTopOnReselect> createState() => _ScrollToTopOnReselectState();
}

class _ScrollToTopOnReselectState extends ConsumerState<ScrollToTopOnReselect> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tabReselectedProvider, (_, next) {
      if (next?.tab != widget.tab) return;
      // Several lists can be attached (e.g. the pages of a tab bar).
      for (final position in _controller.positions) {
        position.animateTo(0, duration: _scrollDuration, curve: Curves.easeOutCubic);
      }
    });
    return PrimaryScrollController(
      controller: _controller,
      // Flutter only shares this controller automatically on iOS/macOS;
      // allow it everywhere.
      automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
      child: widget.child,
    );
  }
}

/// Scrolls [controller] to the top when tab [tab] is reselected — for a
/// screen whose list has its own controller.
void scrollToTopOnReselect(WidgetRef ref, int tab, ScrollController controller) {
  ref.listen(tabReselectedProvider, (_, next) {
    if (next?.tab != tab || !controller.hasClients) return;
    controller.animateTo(0, duration: _scrollDuration, curve: Curves.easeOutCubic);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Pull down to reload, on any screen.
///
/// [child] can be a scrolling list (give it AlwaysScrollableScrollPhysics so
/// short lists can still be pulled) or anything else — an empty state, an
/// error, a loading skeleton — which is made pullable automatically.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Push the spinner down, e.g. below a status bar drawn over the content.
  final double edgeOffset;

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    try {
      await onRefresh();
    } catch (_) {
      // The screen shows its own error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = child is ScrollView
        ? child
        : LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: box.maxHeight, child: child),
            ),
          );
    return RefreshIndicator(
      color: AppColors.hotPink,
      edgeOffset: edgeOffset,
      onRefresh: _refresh,
      child: content,
    );
  }
}

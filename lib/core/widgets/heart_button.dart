import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The favorite (heart) button with a little pop animation for the
/// optimistic-like interaction. 💖
class HeartButton extends StatefulWidget {
  const HeartButton({
    super.key,
    required this.liked,
    required this.onTap,
    this.size = 24,
    this.withBackground = true,
  });

  final bool liked;
  final VoidCallback onTap;
  final double size;
  final bool withBackground;

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.liked ? Icons.favorite : Icons.favorite_border,
      color: widget.liked ? AppColors.hotPink : AppColors.plumSoft,
      size: widget.size,
    );

    final scale = Tween<double>(begin: 1, end: 1.35)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);

    final animated = ScaleTransition(scale: scale, child: icon);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.withBackground
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: AppShadows.subtle(AppColors.plum),
              ),
              child: animated,
            )
          : animated,
    );
  }
}

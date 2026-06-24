import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Swipeable photo carousel with page dots, used on the item detail screen.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.imageUrls});
  final List<String> imageUrls;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 380,
        color: AppColors.blush,
        alignment: Alignment.center,
        child: const Icon(Icons.checkroom_outlined,
            color: AppColors.hotPink, size: 56),
      );
    }

    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.imageUrls.length,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => const ColoredBox(color: AppColors.blush),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: AppColors.blush,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 8,
                    width: active ? 22 : 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.hotPink : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

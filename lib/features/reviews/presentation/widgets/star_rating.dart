import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';

/// A row of 5 stars. Read-only when [onChanged] is null, tappable otherwise.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.onChanged,
  });

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Read-only: announced once as "4 out of 5 stars". Tappable: each star
    // is its own button, with the chosen one marked as selected.
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: onChanged != null,
            selected: onChanged != null && i == rating,
            label: onChanged == null ? null : l10n.ratingStars(i),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(i),
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: AppColors.sun,
                ),
              ),
            ),
          ),
      ],
    );
    if (onChanged != null) return row;
    return Semantics(
      label: l10n.ratingStars(rating),
      excludeSemantics: true,
      child: row,
    );
  }
}

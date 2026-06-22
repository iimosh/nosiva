import 'listing_enums.dart';

/// Immutable filter/query spec for browse & search.
class ListingFilter {
  const ListingFilter({
    this.query,
    this.category,
    this.size,
    this.brand,
    this.condition,
    this.color,
    this.styleTags = const [],
    this.minPrice,
    this.maxPrice,
    this.location,
    this.sort = ListingSort.newest,
  });

  final String? query;
  final ListingCategory? category;
  final String? size;
  final String? brand;
  final ItemCondition? condition;
  final String? color;
  final List<String> styleTags;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final ListingSort sort;

  bool get isEmpty =>
      (query == null || query!.isEmpty) &&
      category == null &&
      size == null &&
      brand == null &&
      condition == null &&
      color == null &&
      styleTags.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      location == null;

  ListingFilter copyWith({
    String? query,
    ListingCategory? category,
    bool clearCategory = false,
    String? size,
    String? brand,
    ItemCondition? condition,
    String? color,
    List<String>? styleTags,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearLocation = false,
    ListingSort? sort,
  }) {
    return ListingFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      size: size ?? this.size,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      color: color ?? this.color,
      styleTags: styleTags ?? this.styleTags,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      location: clearLocation ? null : (location ?? this.location),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ListingFilter &&
      other.query == query &&
      other.category == category &&
      other.size == size &&
      other.brand == brand &&
      other.condition == condition &&
      other.color == color &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.location == location &&
      other.sort == sort &&
      other.styleTags.join(',') == styleTags.join(',');

  @override
  int get hashCode => Object.hash(query, category, size, brand, condition, color,
      minPrice, maxPrice, location, sort, styleTags.join(','));
}

enum ListingSort {
  newest('created_at', false),
  priceLow('price', true),
  priceHigh('price', false),
  popular('favorite_count', false);

  const ListingSort(this.column, this.ascending);
  final String column;
  final bool ascending;
}

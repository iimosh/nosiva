// Domain enums for listings. Each carries a stable `value` stored in Postgres
// and a human `label` for the UI.

enum ListingCategory {
  tops('tops', 'Tops', '👚'),
  dresses('dresses', 'Dresses', '👗'),
  bottoms('bottoms', 'Bottoms', '👖'),
  shoes('shoes', 'Shoes', '👠'),
  bags('bags', 'Bags', '👜'),
  accessories('accessories', 'Accessories', '🧣'),
  jewelry('jewelry', 'Jewelry', '💍'),
  outerwear('outerwear', 'Outerwear', '🧥');

  const ListingCategory(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static ListingCategory fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => tops);
}

enum ItemCondition {
  newWithTags('new_with_tags', 'New with tags'),
  likeNew('like_new', 'Like new'),
  good('good', 'Good'),
  fair('fair', 'Fair');

  const ItemCondition(this.value, this.label);
  final String value;
  final String label;

  static ItemCondition fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => good);
}

enum ListingStatus {
  active('active'),
  sold('sold'),
  hidden('hidden');

  const ListingStatus(this.value);
  final String value;

  static ListingStatus fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => active);
}

enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  countered('countered'),
  expired('expired');

  const OfferStatus(this.value);
  final String value;

  static OfferStatus fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => pending);
}

enum OrderStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  shipped('shipped', 'Shipped'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => pending);
}

/// Curated style tags shown in onboarding, listing creation, and filters.
const kStyleTags = <String>[
  'Y2K',
  'coquette',
  'streetwear',
  'vintage',
  'minimalist',
  'cottagecore',
  'grunge',
  'preppy',
  'boho',
  'academia',
  'athleisure',
  'gorpcore',
];

/// Common clothing sizes used in onboarding & filters.
const kSizes = <String>['XS', 'S', 'M', 'L', 'XL', 'XXL', '6', '8', '10', '12'];

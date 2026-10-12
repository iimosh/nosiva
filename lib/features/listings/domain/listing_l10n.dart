import '../../../l10n/app_localizations.dart';
import 'listing_enums.dart';
import 'listing_filter.dart';

extension ListingSortL10n on ListingSort {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ListingSort.newest => l10n.sortNewest,
      ListingSort.priceLow => l10n.sortPriceLow,
      ListingSort.priceHigh => l10n.sortPriceHigh,
      ListingSort.popular => l10n.sortPopular,
    };
  }
}

extension ListingCategoryL10n on ListingCategory {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ListingCategory.tops => l10n.categoryTops,
      ListingCategory.dresses => l10n.categoryDresses,
      ListingCategory.bottoms => l10n.categoryBottoms,
      ListingCategory.shoes => l10n.categoryShoes,
      ListingCategory.bags => l10n.categoryBags,
      ListingCategory.accessories => l10n.categoryAccessories,
      ListingCategory.jewelry => l10n.categoryJewelry,
      ListingCategory.outerwear => l10n.categoryOuterwear,
    };
  }
}

extension ItemConditionL10n on ItemCondition {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ItemCondition.newWithTags => l10n.conditionNewWithTags,
      ItemCondition.likeNew => l10n.conditionLikeNew,
      ItemCondition.good => l10n.conditionGood,
      ItemCondition.fair => l10n.conditionFair,
    };
  }
}

extension ListingStatusL10n on ListingStatus {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ListingStatus.active => l10n.active,
      ListingStatus.sold => l10n.sold,
      ListingStatus.hidden => l10n.hidden,
    };
  }
}

extension OrderStatusL10n on OrderStatus {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.paid => l10n.orderStatusPaid,
      OrderStatus.shipped => l10n.orderStatusShipped,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
    };
  }
}

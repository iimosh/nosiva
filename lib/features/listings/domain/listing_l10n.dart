import '../../../l10n/app_localizations.dart';
import 'listing_enums.dart';

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

  String localizedWithEmoji(AppLocalizations l10n) {
    return '$emoji ${localizedLabel(l10n)}';
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
      ListingStatus.reserved => l10n.reserved,
      ListingStatus.sold => l10n.sold,
      ListingStatus.hidden => l10n.hidden,
    };
  }
}

String localizedStyleTag(String tag, AppLocalizations l10n) {
  return switch (tag) {
    'Y2K' => l10n.styleTagY2k,
    'coquette' => l10n.styleTagCoquette,
    'streetwear' => l10n.styleTagStreetwear,
    'vintage' => l10n.styleTagVintage,
    'minimalist' => l10n.styleTagMinimalist,
    'cottagecore' => l10n.styleTagCottagecore,
    'grunge' => l10n.styleTagGrunge,
    'preppy' => l10n.styleTagPreppy,
    'boho' => l10n.styleTagBoho,
    'academia' => l10n.styleTagAcademia,
    'athleisure' => l10n.styleTagAthleisure,
    'gorpcore' => l10n.styleTagGorpcore,
    _ => tag,
  };
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

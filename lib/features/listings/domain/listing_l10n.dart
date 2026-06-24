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

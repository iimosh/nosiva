import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mk'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nosiva'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @macedonian.
  ///
  /// In en, this message translates to:
  /// **'Macedonian'**
  String get macedonian;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @oopsGlitched.
  ///
  /// In en, this message translates to:
  /// **'Oops, something glitched'**
  String get oopsGlitched;

  /// No description provided for @discardListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard listing?'**
  String get discardListingTitle;

  /// No description provided for @discardListingBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved listing details. Do you want to discard them?'**
  String get discardListingBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nosiva'**
  String get welcomeTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'pre-loved, main character energy ✨'**
  String get splashTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell pre-loved fashion with\na community that gets your vibe.'**
  String get welcomeSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back 👋'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your closet missed you.'**
  String get welcomeBackSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordDotsHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordDotsHint;

  /// No description provided for @passwordSignupHint.
  ///
  /// In en, this message translates to:
  /// **'at least 8 characters'**
  String get passwordSignupHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'slaygirl_99'**
  String get usernameHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @newHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreateAccount;

  /// No description provided for @joinNosiva.
  ///
  /// In en, this message translates to:
  /// **'Join Nosiva 💕'**
  String get joinNosiva;

  /// No description provided for @yourClosetYourRules.
  ///
  /// In en, this message translates to:
  /// **'Your closet, your rules.'**
  String get yourClosetYourRules;

  /// No description provided for @alreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccountSignIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Let’s set up your vibe ✨'**
  String get accountCreated;

  /// No description provided for @welcomeBackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back bestie 💖'**
  String get welcomeBackSuccess;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign you in — check your details'**
  String get signInFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign you up — {error}'**
  String signUpFailed(Object error);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s set your vibe ✨'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll use this to curate your feed.'**
  String get onboardingSubtitle;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptional;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get displayNameHint;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get locationOptional;

  /// No description provided for @cityCountry.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get cityCountry;

  /// No description provided for @favoriteCategories.
  ///
  /// In en, this message translates to:
  /// **'Favorite categories'**
  String get favoriteCategories;

  /// No description provided for @yourSizes.
  ///
  /// In en, this message translates to:
  /// **'Your sizes'**
  String get yourSizes;

  /// No description provided for @stylesYouLove.
  ///
  /// In en, this message translates to:
  /// **'Styles you love'**
  String get stylesYouLove;

  /// No description provided for @startSlaying.
  ///
  /// In en, this message translates to:
  /// **'Start slaying 💖'**
  String get startSlaying;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save — {error}'**
  String couldNotSave(Object error);

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @nothingHereYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to list something fabulous, or check back soon ✨'**
  String get nothingHereYetMessage;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites 💖'**
  String get favorites;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty bestie'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on anything you love to save it here.'**
  String get wishlistEmptyMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for that dream piece…'**
  String get searchHint;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items & people...'**
  String get homeSearchHint;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches, bestie'**
  String get noMatches;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try fewer filters or a different search.'**
  String get noMatchesMessage;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryTops.
  ///
  /// In en, this message translates to:
  /// **'Tops'**
  String get categoryTops;

  /// No description provided for @categoryDresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get categoryDresses;

  /// No description provided for @categoryBottoms.
  ///
  /// In en, this message translates to:
  /// **'Bottoms'**
  String get categoryBottoms;

  /// No description provided for @categoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get categoryShoes;

  /// No description provided for @categoryBags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get categoryBags;

  /// No description provided for @categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessories;

  /// No description provided for @categoryJewelry.
  ///
  /// In en, this message translates to:
  /// **'Jewelry'**
  String get categoryJewelry;

  /// No description provided for @categoryOuterwear.
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get categoryOuterwear;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @conditionNewWithTags.
  ///
  /// In en, this message translates to:
  /// **'New with tags'**
  String get conditionNewWithTags;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like new'**
  String get conditionLikeNew;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @styleTagY2k.
  ///
  /// In en, this message translates to:
  /// **'Y2K'**
  String get styleTagY2k;

  /// No description provided for @styleTagCoquette.
  ///
  /// In en, this message translates to:
  /// **'Coquette'**
  String get styleTagCoquette;

  /// No description provided for @styleTagStreetwear.
  ///
  /// In en, this message translates to:
  /// **'Streetwear'**
  String get styleTagStreetwear;

  /// No description provided for @styleTagVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get styleTagVintage;

  /// No description provided for @styleTagMinimalist.
  ///
  /// In en, this message translates to:
  /// **'Minimalist'**
  String get styleTagMinimalist;

  /// No description provided for @styleTagCottagecore.
  ///
  /// In en, this message translates to:
  /// **'Cottagecore'**
  String get styleTagCottagecore;

  /// No description provided for @styleTagGrunge.
  ///
  /// In en, this message translates to:
  /// **'Grunge'**
  String get styleTagGrunge;

  /// No description provided for @styleTagPreppy.
  ///
  /// In en, this message translates to:
  /// **'Preppy'**
  String get styleTagPreppy;

  /// No description provided for @styleTagBoho.
  ///
  /// In en, this message translates to:
  /// **'Boho'**
  String get styleTagBoho;

  /// No description provided for @styleTagAcademia.
  ///
  /// In en, this message translates to:
  /// **'Academia'**
  String get styleTagAcademia;

  /// No description provided for @styleTagAthleisure.
  ///
  /// In en, this message translates to:
  /// **'Athleisure'**
  String get styleTagAthleisure;

  /// No description provided for @styleTagGorpcore.
  ///
  /// In en, this message translates to:
  /// **'Gorpcore'**
  String get styleTagGorpcore;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @cityOrCountry.
  ///
  /// In en, this message translates to:
  /// **'City or country'**
  String get cityOrCountry;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @listAnItem.
  ///
  /// In en, this message translates to:
  /// **'List an item'**
  String get listAnItem;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @listingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Y2K butterfly baby tee'**
  String get listingTitleHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @listingDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Condition details, measurements, fit notes…'**
  String get listingDescriptionHint;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Brandy Melville'**
  String get brandHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @colorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pink'**
  String get colorHint;

  /// No description provided for @styleTags.
  ///
  /// In en, this message translates to:
  /// **'Style tags'**
  String get styleTags;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priceUsd.
  ///
  /// In en, this message translates to:
  /// **'Price (MKD)'**
  String get priceUsd;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get priceHint;

  /// No description provided for @listIt.
  ///
  /// In en, this message translates to:
  /// **'List it 💖'**
  String get listIt;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category bestie'**
  String get pickCategory;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo 📸'**
  String get addPhoto;

  /// No description provided for @photoAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add photo — {error}'**
  String photoAddFailed(Object error);

  /// No description provided for @listedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Listed! Time to make that coin 💸'**
  String get listedSuccess;

  /// No description provided for @listFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t list — {error}'**
  String listFailed(Object error);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @listingNotYours.
  ///
  /// In en, this message translates to:
  /// **'This listing is not yours'**
  String get listingNotYours;

  /// No description provided for @onlySellerCanEdit.
  ///
  /// In en, this message translates to:
  /// **'Only the seller can edit this item.'**
  String get onlySellerCanEdit;

  /// No description provided for @listingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Listing updated'**
  String get listingUpdated;

  /// No description provided for @updateListingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update listing - {error}'**
  String updateListingFailed(Object error);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @vibe.
  ///
  /// In en, this message translates to:
  /// **'Vibe'**
  String get vibe;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @shipsFrom.
  ///
  /// In en, this message translates to:
  /// **'Ships from {location}'**
  String shipsFrom(Object location);

  /// No description provided for @calculatedAtCheckout.
  ///
  /// In en, this message translates to:
  /// **'Calculated at checkout'**
  String get calculatedAtCheckout;

  /// No description provided for @buyerProtection.
  ///
  /// In en, this message translates to:
  /// **'Buyer protection'**
  String get buyerProtection;

  /// No description provided for @buyerProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment is held until you confirm delivery.'**
  String get buyerProtectionBody;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @returnsBody.
  ///
  /// In en, this message translates to:
  /// **'Item as described — returns handled case by case.'**
  String get returnsBody;

  /// No description provided for @moreFromSeller.
  ///
  /// In en, this message translates to:
  /// **'More from this seller'**
  String get moreFromSeller;

  /// No description provided for @youMightAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get youMightAlsoLike;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make offer'**
  String get makeOffer;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart 🛍️'**
  String get addedToCart;

  /// No description provided for @makeOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make an offer 💌'**
  String get makeOfferTitle;

  /// No description provided for @listedAt.
  ///
  /// In en, this message translates to:
  /// **'Listed at {price}'**
  String listedAt(Object price);

  /// No description provided for @yourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get yourOffer;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get sendOffer;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent! Fingers crossed 🤞'**
  String get offerSent;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart 🛍️'**
  String get cart;

  /// No description provided for @bagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get bagEmpty;

  /// No description provided for @bagEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add something fabulous and come back ✨'**
  String get bagEmptyMessage;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping address'**
  String get shippingAddress;

  /// No description provided for @shippingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, City, ZIP, Country'**
  String get shippingAddressHint;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout · {price}'**
  String checkout(Object price);

  /// No description provided for @paymentStubbed.
  ///
  /// In en, this message translates to:
  /// **'💳 Payment is stubbed (Stripe integration point)'**
  String get paymentStubbed;

  /// No description provided for @addShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a shipping address first 📦'**
  String get addShippingAddress;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed! You did that 💖'**
  String get orderPlaced;

  /// No description provided for @checkoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Checkout failed — {error}'**
  String checkoutFailed(Object error);

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @buying.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get buying;

  /// No description provided for @selling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get selling;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @ordersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your purchases and sales will show up here.'**
  String get ordersEmptyMessage;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New messages, offers and sales will pop up here.'**
  String get notificationsEmptyMessage;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @noMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'When you message a seller (or get a buyer), it shows up here.'**
  String get noMessagesMessage;

  /// No description provided for @nosivaUser.
  ///
  /// In en, this message translates to:
  /// **'Nosiva user'**
  String get nosivaUser;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi 👋'**
  String get sayHi;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @sayHiTitle.
  ///
  /// In en, this message translates to:
  /// **'Say hi!'**
  String get sayHiTitle;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation — ask about size, fit, anything.'**
  String get chatEmptyMessage;

  /// No description provided for @messageFailed.
  ///
  /// In en, this message translates to:
  /// **'Message failed — {error}'**
  String messageFailed(Object error);

  /// No description provided for @imageSharingTodo.
  ///
  /// In en, this message translates to:
  /// **'Image sharing — TODO 📷'**
  String get imageSharingTodo;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin 🛡️'**
  String get admin;

  /// No description provided for @noProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No profile found'**
  String get noProfileFound;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @followersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String followersCount(int count);

  /// No description provided for @shareTodo.
  ///
  /// In en, this message translates to:
  /// **'Sharing is coming soon'**
  String get shareTodo;

  /// No description provided for @startChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat - {error}'**
  String startChatFailed(Object error);

  /// No description provided for @sendOfferFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send offer - {error}'**
  String sendOfferFailed(Object error);

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoriteAdded;

  /// No description provided for @favoriteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update favorites'**
  String get favoriteUpdateFailed;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editProfileTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit profile — TODO ✏️'**
  String get editProfileTodo;

  /// No description provided for @myCloset.
  ///
  /// In en, this message translates to:
  /// **'My closet'**
  String get myCloset;

  /// No description provided for @closetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your closet is empty bestie ✨'**
  String get closetEmpty;

  /// No description provided for @closetEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'List your first piece and start earning.'**
  String get closetEmptyMessage;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moderate listings, view stats & users'**
  String get adminDashboardSubtitle;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get orderStatusPaid;

  /// No description provided for @orderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @adminListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get adminListings;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get adminHidden;

  /// No description provided for @adminAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminAdmins;

  /// No description provided for @nothingToModerate.
  ///
  /// In en, this message translates to:
  /// **'Nothing to moderate'**
  String get nothingToModerate;

  /// No description provided for @newListingsWillShow.
  ///
  /// In en, this message translates to:
  /// **'New listings will show up here as they are posted.'**
  String get newListingsWillShow;

  /// No description provided for @reportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports coming soon'**
  String get reportsComingSoon;

  /// No description provided for @reportsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'User reports of listings and sellers will land here for review.'**
  String get reportsComingSoonBody;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get noUsersYet;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdmin;

  /// No description provided for @manageRole.
  ///
  /// In en, this message translates to:
  /// **'Manage role'**
  String get manageRole;

  /// No description provided for @roleChangeQuestion.
  ///
  /// In en, this message translates to:
  /// **'{action}?'**
  String roleChangeQuestion(Object action);

  /// No description provided for @userWillGetModerationPowers.
  ///
  /// In en, this message translates to:
  /// **'{user} will get full moderation powers.'**
  String userWillGetModerationPowers(Object user);

  /// No description provided for @userWillLoseAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'{user} will lose admin access.'**
  String userWillLoseAdminAccess(Object user);

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get youLabel;

  /// No description provided for @promotedToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Promoted to admin'**
  String get promotedToAdmin;

  /// No description provided for @adminRemoved.
  ///
  /// In en, this message translates to:
  /// **'Admin removed'**
  String get adminRemoved;

  /// No description provided for @updateRoleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update role - {error}'**
  String updateRoleFailed(Object error);

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get adminBadge;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @unhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get unhide;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @hideListing.
  ///
  /// In en, this message translates to:
  /// **'Hide listing'**
  String get hideListing;

  /// No description provided for @unhideListing.
  ///
  /// In en, this message translates to:
  /// **'Unhide listing'**
  String get unhideListing;

  /// No description provided for @listingRestored.
  ///
  /// In en, this message translates to:
  /// **'Listing restored'**
  String get listingRestored;

  /// No description provided for @listingHidden.
  ///
  /// In en, this message translates to:
  /// **'Listing hidden'**
  String get listingHidden;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get deleteListing;

  /// No description provided for @deleteListingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete listing?'**
  String get deleteListingQuestion;

  /// No description provided for @listingWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently removed.'**
  String listingWillBeRemoved(Object title);

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed - {error}'**
  String actionFailed(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mk':
      return AppLocalizationsMk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

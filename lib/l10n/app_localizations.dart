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

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @oopsGlitched.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
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
  /// **'second-hand fashion, thoughtfully listed'**
  String get splashTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell second-hand clothing and accessories in one simple marketplace.'**
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

  /// No description provided for @welcomeHeadlineTop.
  ///
  /// In en, this message translates to:
  /// **'Give fashion'**
  String get welcomeHeadlineTop;

  /// No description provided for @welcomeHeadlineAccent.
  ///
  /// In en, this message translates to:
  /// **'a second life'**
  String get welcomeHeadlineAccent;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @otherSize.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherSize;

  /// No description provided for @customSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your size'**
  String get customSizeTitle;

  /// No description provided for @customSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 38, W30 L32, One size'**
  String get customSizeHint;

  /// No description provided for @customSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Up to 20 letters or numbers (. / - ( ) allowed)'**
  String get customSizeInvalid;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @haveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountQuestion;

  /// No description provided for @guestPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account in a minute to buy, sell and chat with other members.'**
  String get guestPromptBody;

  /// No description provided for @guestBuyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to buy this item'**
  String get guestBuyTitle;

  /// No description provided for @guestOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to make an offer'**
  String get guestOfferTitle;

  /// No description provided for @guestMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send a message'**
  String get guestMessageTitle;

  /// No description provided for @guestFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites'**
  String get guestFavoriteTitle;

  /// No description provided for @guestFollowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow sellers'**
  String get guestFollowTitle;

  /// No description provided for @guestReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to report'**
  String get guestReportTitle;

  /// No description provided for @guestCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your cart'**
  String get guestCartTitle;

  /// No description provided for @guestActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your orders and offers'**
  String get guestActivityTitle;

  /// No description provided for @guestActivityBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep track of everything you buy and sell.'**
  String get guestActivityBody;

  /// No description provided for @guestSellTitle.
  ///
  /// In en, this message translates to:
  /// **'Start selling'**
  String get guestSellTitle;

  /// No description provided for @guestSellBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to list your pieces and reach buyers near you.'**
  String get guestSellBody;

  /// No description provided for @guestInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Your messages'**
  String get guestInboxTitle;

  /// No description provided for @guestInboxBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to chat with buyers and sellers.'**
  String get guestInboxBody;

  /// No description provided for @guestProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get guestProfileTitle;

  /// No description provided for @guestProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your profile, listings and favorites.'**
  String get guestProfileBody;

  /// No description provided for @guestFollowingTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow sellers you love'**
  String get guestFollowingTitle;

  /// No description provided for @guestFollowingBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see new listings from people you follow.'**
  String get guestFollowingBody;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue managing your listings.'**
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

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we’ll send you a link to reset it.'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a reset link'**
  String get resetLinkSent;

  /// No description provided for @resetLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send reset link — {error}'**
  String resetLinkFailed(Object error);

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don’t match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update password — {error}'**
  String passwordUpdateFailed(Object error);

  /// No description provided for @updatePasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePasswordCta;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'username'**
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
  /// **'Join Nosiva'**
  String get joinNosiva;

  /// No description provided for @yourClosetYourRules.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start buying and selling.'**
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
  /// **'Account created. Let’s set up your preferences.'**
  String get accountCreated;

  /// No description provided for @welcomeBackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
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
  /// **'Set up your profile'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo, your name and city so buyers know who they\'re dealing with. Everything here is optional.'**
  String get onboardingSubtitle;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptional;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

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

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save — {error}'**
  String couldNotSave(Object error);

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @nothingHereYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to publish a listing, or check again later.'**
  String get nothingHereYetMessage;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on anything you love to save it here.'**
  String get wishlistEmptyMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search listings...'**
  String get searchHint;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items & people...'**
  String get homeSearchHint;

  /// No description provided for @latestListings.
  ///
  /// In en, this message translates to:
  /// **'Latest listings'**
  String get latestListings;

  /// No description provided for @browseItems.
  ///
  /// In en, this message translates to:
  /// **'Browse items'**
  String get browseItems;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
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

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInfo;

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get itemDetails;

  /// No description provided for @pricingAndLocation.
  ///
  /// In en, this message translates to:
  /// **'Price and location'**
  String get pricingAndLocation;

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
  /// **'e.g. cotton shirt'**
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
  /// **'Publish listing'**
  String get listIt;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get pickCategory;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo'**
  String get addPhoto;

  /// No description provided for @photoAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add photo — {error}'**
  String photoAddFailed(Object error);

  /// No description provided for @maxPhotosReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} photos'**
  String maxPhotosReached(Object max);

  /// No description provided for @editPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit photo'**
  String get editPhoto;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @rotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get rotateRight;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @moveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get moveLeft;

  /// No description provided for @moveRight.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get moveRight;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @keepOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Listings need at least one photo'**
  String get keepOnePhoto;

  /// No description provided for @photoEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t edit photo — {error}'**
  String photoEditFailed(Object error);

  /// No description provided for @listedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Listing published successfully.'**
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

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @itemNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available'**
  String get itemNoLongerAvailable;

  /// No description provided for @soldItemsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Some items were just sold and removed from your bag'**
  String get soldItemsRemoved;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @vibe.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get vibe;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

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
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @makeOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
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
  /// **'Offer sent.'**
  String get offerSent;

  /// No description provided for @newOffer.
  ///
  /// In en, this message translates to:
  /// **'New offer'**
  String get newOffer;

  /// No description provided for @offerPending.
  ///
  /// In en, this message translates to:
  /// **'Offer pending'**
  String get offerPending;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get offerDeclined;

  /// No description provided for @offeredPrice.
  ///
  /// In en, this message translates to:
  /// **'Offered {price}'**
  String offeredPrice(Object price);

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Listed {price}'**
  String originalPrice(Object price);

  /// No description provided for @offeredTime.
  ///
  /// In en, this message translates to:
  /// **'Offered {time}'**
  String offeredTime(Object time);

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get acceptOffer;

  /// No description provided for @declineOffer.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineOffer;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @bagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get bagEmpty;

  /// No description provided for @bagEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an item to continue checkout.'**
  String get bagEmptyMessage;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get shippingAddress;

  /// No description provided for @shippingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street and number, city'**
  String get shippingAddressHint;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Place order · {price}'**
  String checkout(Object price);

  /// No description provided for @addShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address first'**
  String get addShippingAddress;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully.'**
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

  /// No description provided for @buyingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your purchases will appear here.'**
  String get buyingEmptyMessage;

  /// No description provided for @sellingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Orders for your listed items will appear here.'**
  String get sellingEmptyMessage;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

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

  /// No description provided for @messageUser.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageUser;

  /// No description provided for @searchConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages or people...'**
  String get searchConversationsHint;

  /// No description provided for @findSomeoneToMessage.
  ///
  /// In en, this message translates to:
  /// **'Find someone to message'**
  String get findSomeoneToMessage;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get deleteConversation;

  /// No description provided for @deleteConversationMessage.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see this chat anymore. It\'ll come back if they message you again.'**
  String get deleteConversationMessage;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListingsYet;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sayHi;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @sayHiTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
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

  /// No description provided for @imageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send image - {error}'**
  String imageSendFailed(Object error);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
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

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(int count);

  /// No description provided for @rateUser.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String rateUser(Object name);

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get leaveReview;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get editReview;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share how it went (optional)'**
  String get reviewCommentHint;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @updateReview.
  ///
  /// In en, this message translates to:
  /// **'Update review'**
  String get updateReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// No description provided for @reviewUpdated.
  ///
  /// In en, this message translates to:
  /// **'Review updated'**
  String get reviewUpdated;

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t submit review — {error}'**
  String reviewFailed(Object error);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @noReviewsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Reviews from buyers and sellers will show up here.'**
  String get noReviewsYetMessage;

  /// No description provided for @pickRating.
  ///
  /// In en, this message translates to:
  /// **'Select a star rating'**
  String get pickRating;

  /// No description provided for @listings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Short description about you'**
  String get bioHint;

  /// No description provided for @profilePhotoInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updates can be added later.'**
  String get profilePhotoInfo;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, and underscores'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken'**
  String get usernameTaken;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get confirmEmailSent;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first. Check your inbox for the link.'**
  String get emailNotConfirmed;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @reportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListing;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get unblockUser;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockUserTitle(Object name);

  /// No description provided for @blockUserMessage.
  ///
  /// In en, this message translates to:
  /// **'They won’t be able to message you or make offers or orders, and you won’t see their listings or chats. You can unblock them anytime.'**
  String get blockUserMessage;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get userUnblocked;

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update block — {error}'**
  String blockFailed(Object error);

  /// No description provided for @youBlockedThisUser.
  ///
  /// In en, this message translates to:
  /// **'You blocked this person.'**
  String get youBlockedThisUser;

  /// No description provided for @cannotMessage.
  ///
  /// In en, this message translates to:
  /// **'You can’t message this person.'**
  String get cannotMessage;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportWhy.
  ///
  /// In en, this message translates to:
  /// **'What’s the problem?'**
  String get reportWhy;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reasonSpam;

  /// No description provided for @reasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get reasonScam;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reasonInappropriate;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reasonHarassment;

  /// No description provided for @reasonCounterfeit.
  ///
  /// In en, this message translates to:
  /// **'Counterfeit item'**
  String get reasonCounterfeit;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reasonOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get reportDetailsHint;

  /// No description provided for @sendReportCta.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReportCta;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we’ll review this'**
  String get reportSent;

  /// No description provided for @reportAlready.
  ///
  /// In en, this message translates to:
  /// **'You’ve already reported this'**
  String get reportAlready;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send report — {error}'**
  String reportFailed(Object error);

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No open reports'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New reports from users will show up here.'**
  String get reportsEmptyBody;

  /// No description provided for @reportActionResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get reportActionResolve;

  /// No description provided for @reportActionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get reportActionDismiss;

  /// No description provided for @reportActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get reportActionView;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by {name}'**
  String reportedBy(Object name);

  /// No description provided for @reportTypeUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get reportTypeUser;

  /// No description provided for @reportTypeListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get reportTypeListing;

  /// No description provided for @reportClosed.
  ///
  /// In en, this message translates to:
  /// **'Report closed'**
  String get reportClosed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, listings, messages, reviews and order history. This can’t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAccountTypeToConfirm;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel your open orders before deleting your account.'**
  String get deleteAccountOpenOrders;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t delete account — {error}'**
  String deleteAccountFailed(Object error);

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted'**
  String get accountDeleted;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile - {error}'**
  String profileUpdateFailed(Object error);

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get photoUpdated;

  /// No description provided for @photoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update photo - {error}'**
  String photoUpdateFailed(Object error);

  /// No description provided for @myCloset.
  ///
  /// In en, this message translates to:
  /// **'My closet'**
  String get myCloset;

  /// No description provided for @closetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your closet is empty'**
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
  /// **'Accepted'**
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

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @orderedLabel.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get orderedLabel;

  /// No description provided for @actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get actionNeeded;

  /// No description provided for @newActivity.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newActivity;

  /// No description provided for @updatedActivity.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedActivity;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchived;

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get hideArchived;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restored;

  /// No description provided for @noArchivedOrders.
  ///
  /// In en, this message translates to:
  /// **'No archived orders'**
  String get noArchivedOrders;

  /// No description provided for @orderedTime.
  ///
  /// In en, this message translates to:
  /// **'Ordered {time}'**
  String orderedTime(Object time);

  /// No description provided for @updatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedTime(Object time);

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept order'**
  String get acceptOrder;

  /// No description provided for @declineOrder.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineOrder;

  /// No description provided for @markShipped.
  ///
  /// In en, this message translates to:
  /// **'Mark as shipped'**
  String get markShipped;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get markDelivered;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @confirmReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm received'**
  String get confirmReceived;

  /// No description provided for @orderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated'**
  String get orderUpdated;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order? This can\'t be undone.'**
  String get cancelOrderConfirm;

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

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location on your phone to use this.'**
  String get locationServicesOff;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked. Turn it on in Settings to use this.'**
  String get locationPermissionBlocked;

  /// No description provided for @locationCityNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your city. Please type it in.'**
  String get locationCityNotFound;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location. Try again or type your city.'**
  String get locationUnavailable;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorNotAllowed;

  /// No description provided for @errorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That already exists.'**
  String get errorAlreadyExists;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available.'**
  String get errorNotFound;

  /// No description provided for @errorInvalidData.
  ///
  /// In en, this message translates to:
  /// **'Some details aren\'t valid. Please check them and try again.'**
  String get errorInvalidData;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large. Please choose a smaller one.'**
  String get errorFileTooLarge;

  /// No description provided for @errorFileType.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t supported. Please use a JPG, PNG or WebP photo.'**
  String get errorFileType;

  /// No description provided for @shareListingText.
  ///
  /// In en, this message translates to:
  /// **'Check out \"{title}\" for {price} on Nosiva, the second-hand fashion marketplace.'**
  String shareListingText(String title, String price);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Auto follows your phone\'s light or dark setting.'**
  String get themeAutoHint;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Most liked'**
  String get sortPopular;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay cash on delivery'**
  String get cashOnDelivery;

  /// No description provided for @cashOnDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'No payment in the app. You pay the courier in cash when your item arrives.'**
  String get cashOnDeliveryBody;

  /// No description provided for @markSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get markSold;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark as available'**
  String get markAvailable;

  /// No description provided for @markSoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold?'**
  String get markSoldTitle;

  /// No description provided for @markSoldBody.
  ///
  /// In en, this message translates to:
  /// **'Buyers will see it as sold and won\'t be able to order it. You can make it available again anytime.'**
  String get markSoldBody;

  /// No description provided for @markedSold.
  ///
  /// In en, this message translates to:
  /// **'Marked as sold'**
  String get markedSold;

  /// No description provided for @markedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available again'**
  String get markedAvailable;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'07X XXX XXX'**
  String get phoneNumberHint;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number for the courier'**
  String get addPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @phoneOnlyForSeller.
  ///
  /// In en, this message translates to:
  /// **'Only the seller sees your number, to arrange delivery.'**
  String get phoneOnlyForSeller;

  /// No description provided for @buyerPhone.
  ///
  /// In en, this message translates to:
  /// **'Buyer\'s phone'**
  String get buyerPhone;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get validationPriceRequired;

  /// No description provided for @validationNumbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Enter numbers only'**
  String get validationNumbersOnly;

  /// No description provided for @validationPriceTooLow.
  ///
  /// In en, this message translates to:
  /// **'Price must be more than 0'**
  String get validationPriceTooLow;

  /// No description provided for @validationPriceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Enter a lower price'**
  String get validationPriceTooHigh;

  /// No description provided for @validationTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters'**
  String validationTooShort(int min);

  /// No description provided for @offerDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'If the seller accepts, they\'ll get your address and phone to send the item. You pay the courier in cash on delivery.'**
  String get offerDeliveryNote;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password, then choose a new one. Any other phone or computer signed in to your account will be signed out.'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You sign in with {email}. Enter the new address and your password to confirm it\'s you.'**
  String changeEmailSubtitle(String email);

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Your current password is incorrect.'**
  String get errorWrongPassword;

  /// No description provided for @errorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get errorSamePassword;

  /// No description provided for @errorSameEmail.
  ///
  /// In en, this message translates to:
  /// **'That\'s already your email.'**
  String get errorSameEmail;

  /// No description provided for @emailChangePending.
  ///
  /// In en, this message translates to:
  /// **'Almost done — open the confirmation link we emailed you to finish the change. Check both your old and new inbox.'**
  String get emailChangePending;

  /// No description provided for @emailChanged.
  ///
  /// In en, this message translates to:
  /// **'Your email has been changed.'**
  String get emailChanged;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineBanner;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnline;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @supportEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'No email app found. Our address was copied: {email}'**
  String supportEmailCopied(String email);

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String legalLastUpdated(String date);

  /// No description provided for @legalConsentStart.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the '**
  String get legalConsentStart;

  /// No description provided for @legalConsentMiddle.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get legalConsentMiddle;

  /// No description provided for @legalConsentEnd.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legalConsentEnd;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from cart'**
  String get removeFromCart;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @removeRecentSearch.
  ///
  /// In en, this message translates to:
  /// **'Remove from recent searches'**
  String get removeRecentSearch;

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message the seller'**
  String get messageSeller;

  /// No description provided for @sendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send a photo'**
  String get sendPhoto;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @shareListing.
  ///
  /// In en, this message translates to:
  /// **'Share listing'**
  String get shareListing;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'{count} out of 5 stars'**
  String ratingStars(int count);

  /// No description provided for @newItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String newItemsCount(int count);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Off — tap to turn on'**
  String get notificationsOff;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on in your phone\'s Settings → Apps → Nosiva → Notifications.'**
  String get notificationsBlocked;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Messages, offers and orders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'New messages, offers and updates on your orders.'**
  String get notificationChannelDescription;
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

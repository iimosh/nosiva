// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nosiva';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get macedonian => 'Macedonian';

  @override
  String get systemDefault => 'System default';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get sell => 'Sell';

  @override
  String get inbox => 'Inbox';

  @override
  String get me => 'Me';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get tryAgain => 'Try again';

  @override
  String get undo => 'Undo';

  @override
  String get oopsGlitched => 'Something went wrong';

  @override
  String get discardListingTitle => 'Discard listing?';

  @override
  String get discardListingBody =>
      'You have unsaved listing details. Do you want to discard them?';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get welcomeTitle => 'Nosiva';

  @override
  String get splashTagline => 'second-hand fashion, thoughtfully listed';

  @override
  String get welcomeSubtitle =>
      'Buy and sell second-hand clothing and accessories in one simple marketplace.';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get welcomeHeadlineTop => 'Give fashion';

  @override
  String get welcomeHeadlineAccent => 'a second life';

  @override
  String get getStarted => 'Get started';

  @override
  String get otherSize => 'Other';

  @override
  String get customSizeTitle => 'Your size';

  @override
  String get customSizeHint => 'e.g. 38, W30 L32, One size';

  @override
  String get customSizeInvalid =>
      'Up to 20 letters or numbers (. / - ( ) allowed)';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get haveAccountQuestion => 'Already have an account?';

  @override
  String get guestPromptBody =>
      'Create a free account in a minute to buy, sell and chat with other members.';

  @override
  String get guestBuyTitle => 'Sign in to buy this item';

  @override
  String get guestOfferTitle => 'Sign in to make an offer';

  @override
  String get guestMessageTitle => 'Sign in to send a message';

  @override
  String get guestFavoriteTitle => 'Sign in to save favorites';

  @override
  String get guestFollowTitle => 'Sign in to follow sellers';

  @override
  String get guestReportTitle => 'Sign in to report';

  @override
  String get guestCartTitle => 'Sign in to see your cart';

  @override
  String get guestActivityTitle => 'Your orders and offers';

  @override
  String get guestActivityBody =>
      'Sign in to keep track of everything you buy and sell.';

  @override
  String get guestSellTitle => 'Start selling';

  @override
  String get guestSellBody =>
      'Sign in to list your pieces and reach buyers near you.';

  @override
  String get guestInboxTitle => 'Your messages';

  @override
  String get guestInboxBody => 'Sign in to chat with buyers and sellers.';

  @override
  String get guestProfileTitle => 'Your profile';

  @override
  String get guestProfileBody =>
      'Sign in to manage your profile, listings and favorites.';

  @override
  String get guestFollowingTitle => 'Follow sellers you love';

  @override
  String get guestFollowingBody =>
      'Sign in to see new listings from people you follow.';

  @override
  String get welcomeBackTitle => 'Welcome back';

  @override
  String get welcomeBackSubtitle =>
      'Sign in to continue managing your listings.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordDotsHint => '••••••••';

  @override
  String get passwordSignupHint => 'at least 8 characters';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email and we’ll send you a link to reset it.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetLinkSent => 'Check your email for a reset link';

  @override
  String resetLinkFailed(Object error) {
    return 'Couldn’t send reset link — $error';
  }

  @override
  String get setNewPasswordTitle => 'Set a new password';

  @override
  String get setNewPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordsDontMatch => 'Passwords don’t match';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String passwordUpdateFailed(Object error) {
    return 'Couldn’t update password — $error';
  }

  @override
  String get updatePasswordCta => 'Update password';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'username';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get newHereCreateAccount => 'New here? Create an account';

  @override
  String get joinNosiva => 'Join Nosiva';

  @override
  String get yourClosetYourRules =>
      'Create your account to start buying and selling.';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get accountCreated =>
      'Account created. Let’s set up your preferences.';

  @override
  String get welcomeBackSuccess => 'Welcome back.';

  @override
  String get signInFailed => 'Couldn’t sign you in — check your details';

  @override
  String signUpFailed(Object error) {
    return 'Couldn’t sign you up — $error';
  }

  @override
  String get onboardingTitle => 'Set up your profile';

  @override
  String get onboardingSubtitle =>
      'Add a photo, your name and city so buyers know who they\'re dealing with. Everything here is optional.';

  @override
  String get displayNameOptional => 'Display name (optional)';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'What should we call you?';

  @override
  String get locationOptional => 'Location (optional)';

  @override
  String get cityCountry => 'City, Country';

  @override
  String get continueButton => 'Continue';

  @override
  String couldNotSave(Object error) {
    return 'Couldn’t save — $error';
  }

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get nothingHereYetMessage =>
      'Be the first to publish a listing, or check again later.';

  @override
  String get favorites => 'Favorites';

  @override
  String get wishlistEmpty => 'Your wishlist is empty';

  @override
  String get wishlistEmptyMessage =>
      'Tap the heart on anything you love to save it here.';

  @override
  String get searchHint => 'Search listings...';

  @override
  String get homeSearchHint => 'Search items & people...';

  @override
  String get latestListings => 'Latest listings';

  @override
  String get browseItems => 'Browse items';

  @override
  String get people => 'People';

  @override
  String get noMatches => 'No matches found';

  @override
  String get noMatchesMessage => 'Try fewer filters or a different search.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filters => 'Filters';

  @override
  String get category => 'Category';

  @override
  String get categoryTops => 'Tops';

  @override
  String get categoryDresses => 'Dresses';

  @override
  String get categoryBottoms => 'Bottoms';

  @override
  String get categoryShoes => 'Shoes';

  @override
  String get categoryBags => 'Bags';

  @override
  String get categoryAccessories => 'Accessories';

  @override
  String get categoryJewelry => 'Jewelry';

  @override
  String get categoryOuterwear => 'Outerwear';

  @override
  String get condition => 'Condition';

  @override
  String get conditionNewWithTags => 'New with tags';

  @override
  String get conditionLikeNew => 'Like new';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionFair => 'Fair';

  @override
  String get size => 'Size';

  @override
  String get location => 'Location';

  @override
  String get cityOrCountry => 'City or country';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get priceRange => 'Price range';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get showResults => 'Show results';

  @override
  String get listAnItem => 'List an item';

  @override
  String get photos => 'Photos';

  @override
  String get basicInfo => 'Basic information';

  @override
  String get itemDetails => 'Item details';

  @override
  String get pricingAndLocation => 'Price and location';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get title => 'Title';

  @override
  String get listingTitleHint => 'e.g. cotton shirt';

  @override
  String get description => 'Description';

  @override
  String get listingDescriptionHint =>
      'Condition details, measurements, fit notes…';

  @override
  String get brand => 'Brand';

  @override
  String get brandHint => 'e.g. Brandy Melville';

  @override
  String get color => 'Color';

  @override
  String get colorHint => 'e.g. Pink';

  @override
  String get status => 'Status';

  @override
  String get priceUsd => 'Price (MKD)';

  @override
  String get priceHint => '0.00';

  @override
  String get listIt => 'Publish listing';

  @override
  String get pickCategory => 'Choose a category';

  @override
  String get addPhoto => 'Add at least one photo';

  @override
  String photoAddFailed(Object error) {
    return 'Couldn’t add photo — $error';
  }

  @override
  String maxPhotosReached(Object max) {
    return 'You can add up to $max photos';
  }

  @override
  String get editPhoto => 'Edit photo';

  @override
  String get crop => 'Crop';

  @override
  String get rotateLeft => 'Rotate left';

  @override
  String get rotateRight => 'Rotate right';

  @override
  String get done => 'Done';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get viewPhoto => 'View photo';

  @override
  String get removePhoto => 'Remove';

  @override
  String get keepOnePhoto => 'Listings need at least one photo';

  @override
  String photoEditFailed(Object error) {
    return 'Couldn’t edit photo — $error';
  }

  @override
  String get listedSuccess => 'Listing published successfully.';

  @override
  String listFailed(Object error) {
    return 'Couldn’t list — $error';
  }

  @override
  String get add => 'Add';

  @override
  String get editListing => 'Edit listing';

  @override
  String get listingNotYours => 'This listing is not yours';

  @override
  String get onlySellerCanEdit => 'Only the seller can edit this item.';

  @override
  String get listingUpdated => 'Listing updated';

  @override
  String updateListingFailed(Object error) {
    return 'Could not update listing - $error';
  }

  @override
  String get active => 'Active';

  @override
  String get sold => 'Sold';

  @override
  String get itemNoLongerAvailable => 'This item is no longer available';

  @override
  String get soldItemsRemoved =>
      'Some items were just sold and removed from your bag';

  @override
  String get hidden => 'Hidden';

  @override
  String get vibe => 'Style';

  @override
  String get seller => 'Seller';

  @override
  String get moreFromSeller => 'More from this seller';

  @override
  String get youMightAlsoLike => 'You might also like';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Read less';

  @override
  String get follow => 'Follow';

  @override
  String get makeOffer => 'Make offer';

  @override
  String get buyNow => 'Buy now';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get makeOfferTitle => 'Make an offer';

  @override
  String listedAt(Object price) {
    return 'Listed at $price';
  }

  @override
  String get yourOffer => 'Your offer';

  @override
  String get sendOffer => 'Send offer';

  @override
  String get offerSent => 'Offer sent.';

  @override
  String get newOffer => 'New offer';

  @override
  String get offerPending => 'Offer pending';

  @override
  String get offerAccepted => 'Offer accepted';

  @override
  String get offerDeclined => 'Offer declined';

  @override
  String offeredPrice(Object price) {
    return 'Offered $price';
  }

  @override
  String originalPrice(Object price) {
    return 'Listed $price';
  }

  @override
  String offeredTime(Object time) {
    return 'Offered $time';
  }

  @override
  String get acceptOffer => 'Accept offer';

  @override
  String get declineOffer => 'Decline';

  @override
  String get cart => 'Cart';

  @override
  String get bagEmpty => 'Your bag is empty';

  @override
  String get bagEmptyMessage => 'Add an item to continue checkout.';

  @override
  String get shippingAddress => 'Delivery address';

  @override
  String get shippingAddressHint => 'Street and number, city';

  @override
  String get total => 'Total';

  @override
  String checkout(Object price) {
    return 'Place order · $price';
  }

  @override
  String get addShippingAddress => 'Add a delivery address first';

  @override
  String get orderPlaced => 'Order placed successfully.';

  @override
  String checkoutFailed(Object error) {
    return 'Checkout failed — $error';
  }

  @override
  String get orders => 'Orders';

  @override
  String get buying => 'Buying';

  @override
  String get selling => 'Selling';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get ordersEmptyMessage =>
      'Your purchases and sales will show up here.';

  @override
  String get buyingEmptyMessage => 'Your purchases will appear here.';

  @override
  String get sellingEmptyMessage =>
      'Orders for your listed items will appear here.';

  @override
  String get item => 'Item';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get noMessagesMessage =>
      'When you message a seller (or get a buyer), it shows up here.';

  @override
  String get nosivaUser => 'Nosiva user';

  @override
  String get messageUser => 'Message';

  @override
  String get searchConversationsHint => 'Search messages or people...';

  @override
  String get findSomeoneToMessage => 'Find someone to message';

  @override
  String get deleteConversation => 'Delete conversation?';

  @override
  String get deleteConversationMessage =>
      'You won\'t see this chat anymore. It\'ll come back if they message you again.';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String get userNotFound => 'User not found';

  @override
  String get noListingsYet => 'No listings yet';

  @override
  String get sayHi => 'Send message';

  @override
  String get chat => 'Chat';

  @override
  String get messageHint => 'Message...';

  @override
  String get sayHiTitle => 'Send a message';

  @override
  String get chatEmptyMessage =>
      'Start the conversation — ask about size, fit, anything.';

  @override
  String messageFailed(Object error) {
    return 'Message failed — $error';
  }

  @override
  String imageSendFailed(Object error) {
    return 'Could not send image - $error';
  }

  @override
  String get myProfile => 'My profile';

  @override
  String get profile => 'Profile';

  @override
  String get admin => 'Admin';

  @override
  String get noProfileFound => 'No profile found';

  @override
  String get followers => 'Followers';

  @override
  String followersCount(int count) {
    return '$count followers';
  }

  @override
  String startChatFailed(Object error) {
    return 'Could not start chat - $error';
  }

  @override
  String sendOfferFailed(Object error) {
    return 'Could not send offer - $error';
  }

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteUpdateFailed => 'Could not update favorites';

  @override
  String get following => 'Following';

  @override
  String get forYou => 'For You';

  @override
  String get rating => 'Rating';

  @override
  String get reviews => 'Reviews';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String rateUser(Object name) {
    return 'Rate $name';
  }

  @override
  String get leaveReview => 'Rate your experience';

  @override
  String get editReview => 'Edit your review';

  @override
  String get yourRating => 'Your rating';

  @override
  String get reviewCommentHint => 'Share how it went (optional)';

  @override
  String get submitReview => 'Submit review';

  @override
  String get updateReview => 'Update review';

  @override
  String get reviewSubmitted => 'Review submitted';

  @override
  String get reviewUpdated => 'Review updated';

  @override
  String reviewFailed(Object error) {
    return 'Couldn’t submit review — $error';
  }

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get noReviewsYetMessage =>
      'Reviews from buyers and sellers will show up here.';

  @override
  String get pickRating => 'Select a star rating';

  @override
  String get listings => 'Listings';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Short description about you';

  @override
  String get profilePhotoInfo => 'Profile photo updates can be added later.';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters';

  @override
  String get usernameInvalid => 'Use only letters, numbers, and underscores';

  @override
  String get usernameTaken => 'That username is already taken';

  @override
  String get confirmEmailSent =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get emailNotConfirmed =>
      'Please confirm your email first. Check your inbox for the link.';

  @override
  String get reportUser => 'Report user';

  @override
  String get reportListing => 'Report listing';

  @override
  String get blockUser => 'Block user';

  @override
  String get unblockUser => 'Unblock user';

  @override
  String blockUserTitle(Object name) {
    return 'Block $name?';
  }

  @override
  String get blockUserMessage =>
      'They won’t be able to message you or make offers or orders, and you won’t see their listings or chats. You can unblock them anytime.';

  @override
  String get userBlocked => 'User blocked';

  @override
  String get userUnblocked => 'User unblocked';

  @override
  String blockFailed(Object error) {
    return 'Couldn’t update block — $error';
  }

  @override
  String get youBlockedThisUser => 'You blocked this person.';

  @override
  String get cannotMessage => 'You can’t message this person.';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportWhy => 'What’s the problem?';

  @override
  String get reasonSpam => 'Spam';

  @override
  String get reasonScam => 'Scam or fraud';

  @override
  String get reasonInappropriate => 'Inappropriate content';

  @override
  String get reasonHarassment => 'Harassment';

  @override
  String get reasonCounterfeit => 'Counterfeit item';

  @override
  String get reasonOther => 'Something else';

  @override
  String get reportDetailsHint => 'Add details (optional)';

  @override
  String get sendReportCta => 'Send report';

  @override
  String get reportSent => 'Thanks, we’ll review this';

  @override
  String get reportAlready => 'You’ve already reported this';

  @override
  String reportFailed(Object error) {
    return 'Couldn’t send report — $error';
  }

  @override
  String get reportsEmptyTitle => 'No open reports';

  @override
  String get reportsEmptyBody => 'New reports from users will show up here.';

  @override
  String get reportActionResolve => 'Resolve';

  @override
  String get reportActionDismiss => 'Dismiss';

  @override
  String get reportActionView => 'View';

  @override
  String reportedBy(Object name) {
    return 'Reported by $name';
  }

  @override
  String get reportTypeUser => 'User';

  @override
  String get reportTypeListing => 'Listing';

  @override
  String get reportClosed => 'Report closed';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, listings, messages, reviews and order history. This can’t be undone.';

  @override
  String get deleteAccountTypeToConfirm => 'Type DELETE to confirm';

  @override
  String get deleteAccountConfirm => 'Delete forever';

  @override
  String get deleteAccountOpenOrders =>
      'Finish or cancel your open orders before deleting your account.';

  @override
  String deleteAccountFailed(Object error) {
    return 'Couldn’t delete account — $error';
  }

  @override
  String get accountDeleted => 'Your account was deleted';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String profileUpdateFailed(Object error) {
    return 'Could not update profile - $error';
  }

  @override
  String get changePhoto => 'Change photo';

  @override
  String get photoUpdated => 'Profile photo updated';

  @override
  String photoUpdateFailed(Object error) {
    return 'Could not update photo - $error';
  }

  @override
  String get myCloset => 'My closet';

  @override
  String get closetEmpty => 'Your closet is empty';

  @override
  String get closetEmptyMessage => 'List your first piece and start earning.';

  @override
  String get activity => 'Activity';

  @override
  String get alerts => 'Alerts';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get adminDashboardSubtitle => 'Moderate listings, view stats & users';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusPaid => 'Accepted';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderDetails => 'Order details';

  @override
  String get buyer => 'Buyer';

  @override
  String get orderedLabel => 'Ordered';

  @override
  String get actionNeeded => 'Action needed';

  @override
  String get newActivity => 'New';

  @override
  String get updatedActivity => 'Updated';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String get showArchived => 'Show archived';

  @override
  String get hideArchived => 'Hide archived';

  @override
  String get restore => 'Restore';

  @override
  String get restored => 'Restored';

  @override
  String get noArchivedOrders => 'No archived orders';

  @override
  String orderedTime(Object time) {
    return 'Ordered $time';
  }

  @override
  String updatedTime(Object time) {
    return 'Updated $time';
  }

  @override
  String get acceptOrder => 'Accept order';

  @override
  String get declineOrder => 'Decline';

  @override
  String get markShipped => 'Mark as shipped';

  @override
  String get markDelivered => 'Mark as delivered';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get confirmReceived => 'Confirm received';

  @override
  String get orderUpdated => 'Order updated';

  @override
  String get cancelOrderConfirm => 'Cancel this order? This can\'t be undone.';

  @override
  String get adminListings => 'Listings';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminHidden => 'Hidden';

  @override
  String get adminAdmins => 'Admins';

  @override
  String get nothingToModerate => 'Nothing to moderate';

  @override
  String get newListingsWillShow =>
      'New listings will show up here as they are posted.';

  @override
  String get reportsComingSoonBody =>
      'User reports of listings and sellers will land here for review.';

  @override
  String get noUsersYet => 'No users yet';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get manageRole => 'Manage role';

  @override
  String roleChangeQuestion(Object action) {
    return '$action?';
  }

  @override
  String userWillGetModerationPowers(Object user) {
    return '$user will get full moderation powers.';
  }

  @override
  String userWillLoseAdminAccess(Object user) {
    return '$user will lose admin access.';
  }

  @override
  String get youLabel => 'you';

  @override
  String get promotedToAdmin => 'Promoted to admin';

  @override
  String get adminRemoved => 'Admin removed';

  @override
  String updateRoleFailed(Object error) {
    return 'Could not update role - $error';
  }

  @override
  String get adminBadge => 'ADMIN';

  @override
  String get hide => 'Hide';

  @override
  String get unhide => 'Unhide';

  @override
  String get moderate => 'Moderate';

  @override
  String get hideListing => 'Hide listing';

  @override
  String get unhideListing => 'Unhide listing';

  @override
  String get listingRestored => 'Listing restored';

  @override
  String get listingHidden => 'Listing hidden';

  @override
  String get deleteListing => 'Delete listing';

  @override
  String get deleteListingQuestion => 'Delete listing?';

  @override
  String listingWillBeRemoved(Object title) {
    return '\"$title\" will be permanently removed.';
  }

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String actionFailed(Object error) {
    return 'Action failed - $error';
  }

  @override
  String get locationServicesOff =>
      'Turn on location on your phone to use this.';

  @override
  String get locationPermissionDenied => 'Location access was denied.';

  @override
  String get locationPermissionBlocked =>
      'Location is blocked. Turn it on in Settings to use this.';

  @override
  String get locationCityNotFound =>
      'We couldn\'t find your city. Please type it in.';

  @override
  String get locationUnavailable =>
      'We couldn\'t get your location. Try again or type your city.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorNotAllowed => 'You don\'t have permission to do that.';

  @override
  String get errorAlreadyExists => 'That already exists.';

  @override
  String get errorNotFound => 'This is no longer available.';

  @override
  String get errorInvalidData =>
      'Some details aren\'t valid. Please check them and try again.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorEmailInUse => 'An account with this email already exists.';

  @override
  String get errorWeakPassword => 'Please choose a stronger password.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorFileTooLarge =>
      'This photo is too large. Please choose a smaller one.';

  @override
  String get errorFileType =>
      'This file type isn\'t supported. Please use a JPG, PNG or WebP photo.';

  @override
  String shareListingText(String title, String price) {
    return 'Check out \"$title\" for $price on Nosiva, the second-hand fashion marketplace.';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAutoHint =>
      'Auto follows your phone\'s light or dark setting.';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPriceLow => 'Price: low to high';

  @override
  String get sortPriceHigh => 'Price: high to low';

  @override
  String get sortPopular => 'Most liked';

  @override
  String get cashOnDelivery => 'Pay cash on delivery';

  @override
  String get cashOnDeliveryBody =>
      'No payment in the app. You pay the courier in cash when your item arrives.';

  @override
  String get markSold => 'Mark as sold';

  @override
  String get markAvailable => 'Mark as available';

  @override
  String get markSoldTitle => 'Mark as sold?';

  @override
  String get markSoldBody =>
      'Buyers will see it as sold and won\'t be able to order it. You can make it available again anytime.';

  @override
  String get markedSold => 'Marked as sold';

  @override
  String get markedAvailable => 'Available again';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberHint => '07X XXX XXX';

  @override
  String get addPhoneNumber => 'Add a phone number for the courier';

  @override
  String get invalidPhoneNumber => 'Enter a valid phone number';

  @override
  String get phoneOnlyForSeller =>
      'Only the seller sees your number, to arrange delivery.';

  @override
  String get buyerPhone => 'Buyer\'s phone';

  @override
  String get call => 'Call';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordTooShort => 'Use at least 8 characters';

  @override
  String get validationPriceRequired => 'Price is required';

  @override
  String get validationNumbersOnly => 'Enter numbers only';

  @override
  String get validationPriceTooLow => 'Price must be more than 0';

  @override
  String get validationPriceTooHigh => 'Enter a lower price';

  @override
  String validationTooShort(int min) {
    return 'Use at least $min characters';
  }

  @override
  String get offerDeliveryNote =>
      'If the seller accepts, they\'ll get your address and phone to send the item. You pay the courier in cash on delivery.';

  @override
  String get accountSection => 'Account';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'Enter your current password, then choose a new one. Any other phone or computer signed in to your account will be signed out.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get changeEmail => 'Change email';

  @override
  String changeEmailSubtitle(String email) {
    return 'You sign in with $email. Enter the new address and your password to confirm it\'s you.';
  }

  @override
  String get newEmail => 'New email';

  @override
  String get errorWrongPassword => 'Your current password is incorrect.';

  @override
  String get errorSamePassword =>
      'The new password must be different from the current one.';

  @override
  String get errorSameEmail => 'That\'s already your email.';

  @override
  String get emailChangePending =>
      'Almost done — open the confirmation link we emailed you to finish the change. Check both your old and new inbox.';

  @override
  String get emailChanged => 'Your email has been changed.';

  @override
  String get offlineBanner => 'No internet connection';

  @override
  String get backOnline => 'Back online';

  @override
  String get aboutSection => 'About';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get contactUs => 'Contact us';

  @override
  String supportEmailCopied(String email) {
    return 'No email app found. Our address was copied: $email';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get legalConsentStart => 'By continuing, you agree to the ';

  @override
  String get legalConsentMiddle => ' and the ';

  @override
  String get legalConsentEnd => '.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get refresh => 'Refresh';

  @override
  String get removeFromCart => 'Remove from cart';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get removeRecentSearch => 'Remove from recent searches';

  @override
  String get messageSeller => 'Message the seller';

  @override
  String get sendPhoto => 'Send a photo';

  @override
  String get sendMessage => 'Send message';

  @override
  String get shareListing => 'Share listing';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String ratingStars(int count) {
    return '$count out of 5 stars';
  }

  @override
  String newItemsCount(int count) {
    return '$count new';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off — tap to turn on';

  @override
  String get notificationsBlocked =>
      'Notifications are blocked. Turn them on in your phone\'s Settings → Apps → Nosiva → Notifications.';

  @override
  String get notificationChannelName => 'Messages, offers and orders';

  @override
  String get notificationChannelDescription =>
      'New messages, offers and updates on your orders.';
}

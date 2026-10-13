/// Public facts about the app shown in Settings → About and the legal pages.
abstract final class AppInfo {
  /// Where people write for help, data requests and complaints.
  // TODO(prelaunch): switch to the real support address once the domain and
  // its email are set up.
  static const supportEmail = 'support@nosiva.mk';

  /// Shown on the privacy policy and terms; bump when either text changes.
  static final legalUpdated = DateTime(2026, 10, 13);
}

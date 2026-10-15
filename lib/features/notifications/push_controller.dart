import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../activity/presentation/activity_screen.dart'
    show activityTabRequestProvider;
import '../auth/presentation/splash_screen.dart' show introFinishedProvider;
import 'data/push_tokens_repository.dart';
import 'domain/push_target.dart';

/// The chat currently on screen, so a new message there doesn't also pop up
/// as a notification. Set by ChatScreen.
abstract final class OpenChat {
  static String? conversationId;
}

/// Push notifications (Android): connects to Firebase, keeps the server
/// told which account this phone belongs to, shows notifications that
/// arrive while the app is open, and opens the right screen when one is
/// tapped.
///
/// State is whether push works on this phone. It stays false (and every
/// method quietly does nothing) when Firebase isn't set up — for example a
/// build without google-services.json — so the rest of the app never
/// depends on it.
class PushController extends Notifier<bool> {
  static const _channelId = 'nosiva_activity';
  static const _askedKey = 'push_permission_asked';

  final _local = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _registeredToken;
  PushTarget? _pending;

  @override
  bool build() {
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
    });
    unawaited(_start());
    return false;
  }

  Future<void> _start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
      );
      await _createChannel();

      _messaging = messaging;
      state = true;

      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_showWhileOpen))
        ..add(FirebaseMessaging.onMessageOpenedApp
            .listen((m) => _open(PushTarget.fromData(m.data))))
        ..add(messaging.onTokenRefresh.listen((_) => _syncToken()));

      ref.listen(currentAuthUserProvider, (previous, user) {
        if (user != null && user.id != previous?.id) _syncToken();
        _openPending();
      }, fireImmediately: true);
      ref.listen(localeControllerProvider, (_, __) {
        _createChannel();
        _syncToken(force: true);
      });
      ref.listen(introFinishedProvider, (_, __) => _openPending());

      // Opened by tapping a notification while the app was closed.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(PushTarget.fromData(initial.data));
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _openPayload(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      // No Firebase config, or Google Play services missing: no push.
      if (kDebugMode) debugPrint('[push] unavailable: $e');
    }
  }

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeControllerProvider));

  AndroidNotificationChannel get _channel => AndroidNotificationChannel(
        _channelId,
        _l10n.notificationChannelName,
        description: _l10n.notificationChannelDescription,
        importance: Importance.high,
      );

  /// Creating it again with the same id just renames it (language change).
  Future<void> _createChannel() async {
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Links this phone to the signed-in account on the server. Runs at every
  /// start (the server forgets phones not seen for 60 days), on sign-in, and
  /// when Firebase or the app language changes. Failures (offline) are
  /// retried on the next start.
  Future<void> _syncToken({bool force = false}) async {
    final messaging = _messaging;
    if (messaging == null || ref.read(currentAuthUserProvider) == null) return;
    try {
      final token = await messaging.getToken();
      if (token == null || (!force && token == _registeredToken)) return;
      await ref.read(pushTokensRepositoryProvider).register(
            token,
            languageCode: ref.read(localeControllerProvider).languageCode,
          );
      _registeredToken = token;
    } catch (e) {
      if (kDebugMode) debugPrint('[push] token sync failed: $e');
    }
  }

  /// Call before signing out, while the session still exists: unlinks this
  /// phone from the account and throws its Firebase token away, so the next
  /// person using the phone never gets the previous account's
  /// notifications. Never throws; never delays sign-out by more than a few
  /// seconds.
  Future<void> forgetDevice() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final token = _registeredToken ?? await messaging.getToken();
      if (token != null) {
        await ref
            .read(pushTokensRepositoryProvider)
            .unregister(token)
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
    try {
      await messaging.deleteToken().timeout(const Duration(seconds: 4));
    } catch (_) {}
    _registeredToken = null;
  }

  /// Asks for permission to show notifications (Android 13+) — once, at a
  /// moment where it obviously helps: right after someone messages, makes
  /// an offer, orders or lists an item. Later calls do nothing.
  Future<void> askPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_askedKey) ?? false) return;
    await prefs.setBool(_askedKey, true);
    try {
      await messaging.requestPermission();
    } catch (_) {}
  }

  /// Whether notifications are allowed on this phone; null when push isn't
  /// available at all.
  Future<bool?> notificationsAllowed() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (_) {
      return null;
    }
  }

  /// Settings → Notifications: shows the system prompt again. Returns
  /// whether notifications are allowed afterwards (false when the person
  /// has blocked them and must turn them on in the phone's settings).
  Future<bool> requestFromSettings() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    await ref.read(sharedPreferencesProvider).setBool(_askedKey, true);
    try {
      final settings = await messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (_) {
      return false;
    }
  }

  /// Firebase shows notifications by itself only while the app is closed or
  /// in the background; while it's open, show them here — except a message
  /// in the chat that's already on screen.
  void _showWhileOpen(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final target = PushTarget.fromData(message.data);
    if (target is ChatTarget &&
        target.conversationId == OpenChat.conversationId) {
      return;
    }
    final channel = _channel;
    _local.show(
      id: (n.android?.tag ?? message.messageId ?? n.hashCode.toString())
          .hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: AppColors.rose,
          tag: n.android?.tag,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openPayload(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) _open(PushTarget.fromData(data));
    } catch (_) {}
  }

  void _open(PushTarget? target) {
    if (target == null) return;
    _pending = target;
    _openPending();
  }

  /// Opens the tapped notification's screen once the app is ready for it:
  /// the opening animation is over and someone is signed in.
  void _openPending() {
    final target = _pending;
    if (target == null ||
        !ref.read(introFinishedProvider) ||
        ref.read(currentAuthUserProvider) == null) {
      return;
    }
    _pending = null;

    // Let the router finish leaving the splash first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      final here = router.routerDelegate.currentConfiguration.uri.path;
      // Opened from a cold start: put Home underneath, so Back works.
      if (here == AppRoutes.splash) router.go(AppRoutes.home);
      switch (target) {
        case ChatTarget(:final conversationId):
          router.push(AppRoutes.chatPath(conversationId));
        case OrderTarget(:final orderId):
          router.push(AppRoutes.orderDetailPath(orderId));
        case ActivityTarget(:final selling):
          ref.read(activityTabRequestProvider.notifier).state = selling ? 1 : 0;
          router.go(AppRoutes.activity);
      }
    });
  }
}

final pushControllerProvider =
    NotifierProvider<PushController, bool>(PushController.new);

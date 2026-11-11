import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// The signed-in person, as Neon Auth knows them.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.emailVerified = false,
    this.name,
  });

  final String id;
  final String? email;
  final bool emailVerified;
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.emailVerified == emailVerified &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, email, emailVerified, name);
}

enum AuthEvent { restored, signedIn, signedOut, userUpdated }

@immutable
class AuthChange {
  const AuthChange(this.event, this.user);
  final AuthEvent event;
  final AppUser? user;
}

/// A sign-in request Neon Auth refused. [code] is Better Auth's error code
/// (e.g. `INVALID_EMAIL_OR_PASSWORD`, `USER_ALREADY_EXISTS`), or null for
/// network-level problems.
class NeonAuthException implements Exception {
  NeonAuthException(this.message, {this.code, this.status, this.sessionInvalid = false});
  final String message;
  final String? code;
  final int? status;

  /// The saved session was rejected (expired or revoked): sign out.
  final bool sessionInvalid;

  /// The person closed the Google sign-in tab.
  bool get cancelled => code == 'CANCELLED';

  @override
  String toString() => 'NeonAuthException($status ${code ?? ''}: $message)';
}

class _Response {
  _Response(this.status, this.body, this.cookies);
  final int status;
  final String body;
  final List<String> cookies;

  Map<String, dynamic> get json {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}

/// Sign-in for Neon Auth (managed Better Auth), written by hand because
/// Neon has no Flutter library.
///
/// The long-lived session lives in a cookie kept in the phone's secure
/// storage; the short-lived token (JWT) the Data API and our functions need
/// is fetched from it and renewed shortly before it expires. Guests get an
/// anonymous token instead, which only lets them read public data.
class NeonAuth {
  NeonAuth({required this.authUrl, required this.returnUrl});

  /// e.g. https://ep-….neonauth.….neon.tech/neondb/auth
  final String authUrl;

  /// Our `authbounce` function: where Neon sends the browser after Google,
  /// and which forwards it back into the app. A trusted domain in Neon Auth.
  final String returnUrl;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _cookieKey = 'neon_session_cookie';

  /// Google returns to the phone through this app link
  /// (see the CallbackActivity in AndroidManifest.xml).
  static const appScheme = 'mk.nosiva.app';
  static const _verifierParam = 'neon_auth_session_verifier';

  late final String _origin = Uri.parse(authUrl).origin;
  final _http = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final _changes = StreamController<AuthChange>.broadcast();

  Map<String, String> _cookies = {};
  String? _jwt;
  DateTime? _jwtExpiry;
  AppUser? _user;
  Future<void>? _renewing;

  String? _anonymousJwt;
  DateTime? _anonymousExpiry;
  Future<String>? _fetchingAnonymous;

  AppUser? get currentUser => _user;
  Stream<AuthChange> get changes => _changes.stream;

  /// Restores the saved session when the app starts.
  Future<void> restore() async {
    final saved = await _storage.read(key: _cookieKey);
    if (saved != null) {
      try {
        _cookies = Map<String, String>.from(jsonDecode(saved) as Map);
        await _renewToken();
      } on NeonAuthException catch (e) {
        // Only a rejected session signs out; being offline doesn't.
        if (e.sessionInvalid) await _clear();
      } catch (_) {
        // Offline at start: keep the session, renew on the next request.
      }
    }
    _emit(AuthEvent.restored);
  }

  /// The token for the Data API: the person's own when signed in, otherwise
  /// a guest token that can only read public data.
  Future<String> dataApiToken() async {
    if (_cookies.isNotEmpty) {
      try {
        return await userToken();
      } on NeonAuthException catch (e) {
        if (!e.sessionInvalid) rethrow;
        // Session gone (e.g. revoked elsewhere): carry on as a guest.
      }
    }
    return _guestToken();
  }

  /// The signed-in person's token, renewed when close to expiring.
  Future<String> userToken() async {
    if (_cookies.isEmpty) {
      throw NeonAuthException('Not signed in', sessionInvalid: true);
    }
    final exp = _jwtExpiry;
    if (_jwt == null ||
        exp == null ||
        DateTime.now().isAfter(exp.subtract(const Duration(seconds: 30)))) {
      await (_renewing ??= _renewToken().whenComplete(() => _renewing = null));
    }
    return _jwt!;
  }

  // ---------------------------------------------------------------------------
  // Signing in and out
  // ---------------------------------------------------------------------------

  /// Creates the account. [username] travels as Better Auth's `name`, which
  /// the database turns into the profile (migration 0020). Returns false
  /// when the address must be confirmed before a session starts.
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) =>
      _startSession('/sign-up/email', {
        'email': email,
        'password': password,
        'name': username,
      });

  Future<void> signIn({required String email, required String password}) async {
    await _startSession('/sign-in/email', {'email': email, 'password': password});
  }

  /// Google sign-in through Neon's browser flow.
  ///
  /// Neon only returns to web (https) addresses, not into apps, so:
  ///  1. The app asks Neon to start, and keeps the secret "challenge" cookie
  ///     Neon hands back — the browser never sees it.
  ///  2. Google runs in a secure browser tab.
  ///  3. Neon sends the browser to our small `authbounce` function
  ///     ([returnUrl]), which forwards it to mk.nosiva.app://neon-callback;
  ///     that closes the tab and hands the app a one-time verifier.
  ///  4. Verifier + challenge are exchanged for a session. A stolen verifier
  ///     is useless without the challenge, which never left the app.
  Future<void> signInWithGoogle() async {
    final returnOrigin = Uri.parse(returnUrl).origin;
    final start = await _send('POST', '/sign-in/social',
        body: {'provider': 'google', 'callbackURL': '$returnOrigin/'},
        withCookies: false,
        origin: returnOrigin);
    _check(start);
    final challenge = <String, String>{};
    _mergeCookies(start.cookies, challenge);
    final url = start.json['url'];
    if (challenge.isEmpty || url is! String) {
      throw NeonAuthException('Google sign-in could not start');
    }
    _trace('Neon started; opening the Google tab');

    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: appScheme,
      );
    } on PlatformException catch (e) {
      _trace('browser closed without a result (${e.code})');
      throw NeonAuthException(e.message ?? 'Browser error',
          code: e.code == 'CANCELED' ? 'CANCELLED' : 'BROWSER');
    }

    final params = Uri.parse(result).queryParameters;
    final verifier = params[_verifierParam];
    _trace('back in the app (verifier: ${verifier != null}, '
        'error: ${params['error'] ?? '-'})');
    if (verifier == null) {
      throw NeonAuthException('Google sign-in failed', code: params['error']);
    }

    final r = await _send(
      'GET',
      '/get-session?$_verifierParam=${Uri.encodeQueryComponent(verifier)}',
      cookies: challenge,
    );
    final session = <String, String>{};
    _mergeCookies(r.cookies, session);
    session.removeWhere((name, _) => name.contains('session_chall'));
    if (r.status >= 300 || session.isEmpty) {
      throw NeonAuthException('Google sign-in failed', status: r.status);
    }
    _cookies = session;
    await _renewToken();
    _trace('signed in');
    _emit(AuthEvent.signedIn);
  }

  Future<void> signOut() async {
    if (_cookies.isNotEmpty) {
      try {
        await _send('POST', '/sign-out', body: const {});
      } catch (_) {
        // Signed out on this phone regardless.
      }
    }
    await _clear();
    _emit(AuthEvent.signedOut);
  }

  /// Forgets the session on this phone only (after deleting the account,
  /// when the server-side session is already gone).
  Future<void> forgetLocalSession() async {
    await _clear();
    _emit(AuthEvent.signedOut);
  }

  // ---------------------------------------------------------------------------
  // Confirming the email address
  // ---------------------------------------------------------------------------

  /// Emails a new 6-digit code that confirms the address. (Neon also sends
  /// one by itself on sign-up, and when an unconfirmed account tries to
  /// sign in.)
  Future<void> sendVerificationCode(String email) async {
    _check(await _send('POST', '/email-otp/send-verification-otp',
        body: {'email': email, 'type': 'email-verification'}, withCookies: false));
  }

  /// Confirms the address with the emailed code. Neon then signs the person
  /// in straight away, so this starts their session.
  Future<void> verifyEmail({required String email, required String code}) async {
    final r = await _send('POST', '/email-otp/verify-email',
        body: {'email': email, 'otp': code}, withCookies: false);
    _check(r);
    _cookies = {};
    _mergeCookies(r.cookies);
    if (_cookies.isEmpty) return; // confirmed, but they still need to sign in
    await _renewToken();
    _emit(AuthEvent.signedIn);
  }

  // ---------------------------------------------------------------------------
  // Passwords
  // ---------------------------------------------------------------------------

  /// Emails a 6-digit password-reset code. Answers the same whether or not
  /// the address has an account, so it can't be used to discover who's
  /// registered.
  Future<void> sendPasswordResetCode(String email) async {
    _check(await _send('POST', '/email-otp/request-password-reset',
        body: {'email': email}, withCookies: false));
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _check(await _send('POST', '/email-otp/reset-password',
        body: {'email': email, 'otp': code, 'password': newPassword},
        withCookies: false));
  }

  /// Changes the password after checking the current one, and signs out
  /// every other device.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final r = await _send('POST', '/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'revokeOtherSessions': true,
    });
    _check(r);
    // Revoking other sessions issues this phone a fresh session cookie.
    _mergeCookies(r.cookies);
    await _renewToken();
  }

  /// Whether the account has a password (false for Google-only accounts).
  /// When it can't be checked, assumes yes.
  Future<bool> hasPassword() async {
    try {
      final r = await _send('GET', '/list-accounts');
      if (r.status >= 300) return true;
      final accounts = jsonDecode(r.body);
      if (accounts is! List) return true;
      return accounts.any((a) => a is Map && a['providerId'] == 'credential');
    } catch (_) {
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<bool> _startSession(String path, Map<String, String> body) async {
    final r = await _send('POST', path, body: body, withCookies: false);
    _check(r);
    _cookies = {};
    _mergeCookies(r.cookies);
    if (_cookies.isEmpty) return false; // email confirmation required
    await _renewToken();
    _emit(AuthEvent.signedIn);
    return true;
  }

  Future<void> _renewToken() async {
    final r = await _send('GET', '/token');
    if (r.status == 401 || r.status == 403) {
      throw NeonAuthException('Session expired', status: r.status, sessionInvalid: true);
    }
    _check(r);
    final jwt = r.json['token'];
    if (jwt is! String) throw NeonAuthException('No token in response');

    final payload = _payload(jwt);
    final previous = _user;
    _jwt = jwt;
    _jwtExpiry = DateTime.fromMillisecondsSinceEpoch(
        ((payload['exp'] as num?)?.toInt() ?? 0) * 1000);
    _user = AppUser(
      id: payload['sub'] as String,
      email: payload['email'] as String?,
      emailVerified: payload['emailVerified'] == true,
      name: payload['name'] as String?,
    );

    // The session cookie can be refreshed on any response; keep the newest.
    _mergeCookies(r.cookies);
    await _storage.write(key: _cookieKey, value: jsonEncode(_cookies));
    if (previous != null && previous != _user) _emit(AuthEvent.userUpdated);
  }

  Future<String> _guestToken() async {
    final exp = _anonymousExpiry;
    if (_anonymousJwt != null &&
        exp != null &&
        DateTime.now().isBefore(exp.subtract(const Duration(seconds: 30)))) {
      return _anonymousJwt!;
    }
    return _fetchingAnonymous ??= () async {
      try {
        final r = await _send('GET', '/token/anonymous', withCookies: false);
        _check(r);
        final token = r.json['token'];
        if (token is! String) throw NeonAuthException('No guest token');
        _anonymousJwt = token;
        _anonymousExpiry = DateTime.fromMillisecondsSinceEpoch(
            ((_payload(token)['exp'] as num?)?.toInt() ?? 0) * 1000);
        return token;
      } finally {
        _fetchingAnonymous = null;
      }
    }();
  }

  Future<void> _clear() async {
    _cookies = {};
    _jwt = null;
    _jwtExpiry = null;
    _user = null;
    await _storage.delete(key: _cookieKey);
  }

  void _emit(AuthEvent event) => _changes.add(AuthChange(event, _user));

  /// Step-by-step Google sign-in log, debug builds only (never tokens).
  static void _trace(String step) {
    if (kDebugMode) debugPrint('[google] $step');
  }

  void _check(_Response r) {
    if (r.status < 300) return;
    final body = r.json;
    final code = body['code'] ?? (r.status == 429 ? 'TOO_MANY_REQUESTS' : null);
    throw NeonAuthException(
      (body['message'] as String?) ?? 'HTTP ${r.status}',
      code: code is String ? code : null,
      status: r.status,
    );
  }

  void _mergeCookies(List<String> setCookies, [Map<String, String>? into]) {
    final jar = into ?? _cookies;
    for (final c in setCookies) {
      final pair = c.split(';').first;
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      final name = pair.substring(0, eq).trim();
      final value = pair.substring(eq + 1).trim();
      final expired = RegExp(r'max-age=0\b', caseSensitive: false).hasMatch(c);
      if (value.isEmpty || expired) {
        jar.remove(name);
      } else {
        jar[name] = value;
      }
    }
  }

  static Map<String, dynamic> _payload(String jwt) {
    final part = jwt.split('.')[1];
    return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(part))))
        as Map<String, dynamic>;
  }

  Future<_Response> _send(
    String method,
    String path, {
    Object? body,
    bool withCookies = true,
    Map<String, String>? cookies,
    String? origin,
  }) async {
    final req = await _http
        .openUrl(method, Uri.parse('$authUrl$path'))
        .timeout(const Duration(seconds: 20));
    // Neon refuses requests without a trusted Origin; its own address is
    // always trusted.
    req.headers.set('origin', origin ?? _origin);
    final jar = cookies ?? (withCookies ? _cookies : const <String, String>{});
    if (jar.isNotEmpty) {
      req.headers
          .set('cookie', jar.entries.map((e) => '${e.key}=${e.value}').join('; '));
    }
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final resp = await req.close().timeout(const Duration(seconds: 20));
    final text = await resp.transform(utf8.decoder).join();
    return _Response(
      resp.statusCode,
      text,
      resp.headers[HttpHeaders.setCookieHeader] ?? const [],
    );
  }
}

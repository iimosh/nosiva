import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Persists the Supabase session (including the long-lived refresh token) in
/// Android Keystore / iOS Keychain via flutter_secure_storage, instead of
/// supabase_flutter's default plain SharedPreferences.
class SecureSupabaseLocalStorage extends LocalStorage {
  const SecureSupabaseLocalStorage();

  static const _sessionKey = 'nosiva_supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.read(key: _sessionKey) != null;
  }

  @override
  Future<String?> accessToken() => _secureStorage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() =>
      _secureStorage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(key: _sessionKey, value: persistSessionString);
}

/// Same treatment for the PKCE code verifier used during the OAuth/email-link
/// exchange — short-lived, but there's no reason to leave it in plain storage
/// either.
class SecureSupabaseAsyncStorage extends GotrueAsyncStorage {
  const SecureSupabaseAsyncStorage();

  @override
  Future<String?> getItem({required String key}) =>
      _secureStorage.read(key: key);

  @override
  Future<void> removeItem({required String key}) =>
      _secureStorage.delete(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);
}

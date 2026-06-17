import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String get stripePublishableKey =>
      dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';

  static bool get isSupabaseConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-ref') &&
      supabaseAnonKey != 'your-anon-public-key';

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing env var "$key".',
      );
    }
    return value;
  }
}

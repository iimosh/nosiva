import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/storage/app_preferences.dart';
import 'core/supabase/supabase_providers.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the phone's launch screen (the white n) up until the in-app splash
  // has drawn the identical logo underneath — no blank frame in between.
  // The splash removes it; the timer is only a safety net.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  Timer(const Duration(seconds: 3), FlutterNativeSplash.remove);

  await Env.load();
  await initSupabase();
  final prefs = await SharedPreferences.getInstance();
  // Month names etc. for every app language ("3 јул" in Macedonian).
  await initializeDateFormatting();

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const NosivaApp(),
  ));
}

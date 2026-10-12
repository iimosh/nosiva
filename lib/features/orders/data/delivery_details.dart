import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../../../core/supabase/supabase_providers.dart';

/// The delivery address and phone from this account's last order or offer,
/// so repeat buyers don't retype them. Kept on this phone only, separately
/// per account.
class DeliveryDetails {
  DeliveryDetails(this._ref);
  final Ref _ref;

  String get _who => _ref.read(currentAuthUserProvider)?.id ?? 'guest';

  String get address =>
      _ref.read(sharedPreferencesProvider).getString('delivery_address_$_who') ?? '';

  String get phone =>
      _ref.read(sharedPreferencesProvider).getString('delivery_phone_$_who') ?? '';

  Future<void> save({required String address, required String phone}) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString('delivery_address_$_who', address.trim());
    await prefs.setString('delivery_phone_$_who', phone.trim());
  }
}

final deliveryDetailsProvider = Provider((ref) => DeliveryDetails(ref));

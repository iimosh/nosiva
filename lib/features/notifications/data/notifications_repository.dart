import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;
  static const _table = 'notifications';

  Stream<List<AppNotification>> stream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at')
        .map((rows) =>
            rows.reversed.map(AppNotification.fromJson).toList());
  }

  Future<void> markRead(String id) async {
    await _client.from(_table).update({'read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final uid = _client.auth.currentUser!.id;
    await _client.from(_table).update({'read': true}).eq('user_id', uid);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

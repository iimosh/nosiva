import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/report.dart';

/// Thrown when the same user reports the same target twice.
class AlreadyReportedException implements Exception {}

class SafetyRepository {
  SafetyRepository(this._client);
  final SupabaseClient _client;

  Future<Set<String>> fetchBlockedIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final data =
        await _client.from('blocks').select('blocked_id').eq('blocker_id', uid);
    return data.map<String>((e) => e['blocked_id'] as String).toSet();
  }

  Future<void> block(String userId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('blocks')
        .upsert({'blocker_id': uid, 'blocked_id': userId});
  }

  Future<void> unblock(String userId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', userId);
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) async {
    final uid = _client.auth.currentUser!.id;
    try {
      await _client.from('reports').insert({
        'reporter_id': uid,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason.value,
        'details': details,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw AlreadyReportedException();
      rethrow;
    }
  }

  /// Open reports, newest first. RLS only returns rows to admins.
  Future<List<Report>> fetchOpenReports() async {
    final data = await _client
        .from('reports')
        .select('*, reporter:profiles!reports_reporter_id_fkey(*)')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return data.map<Report>((e) => Report.fromJson(e)).toList();
  }

  Future<void> setReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }
}

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(ref.watch(supabaseClientProvider));
});

/// Ids of users the signed-in user has blocked. Rebuilds on every sign-in or
/// sign-out so one account's blocks never carry over to another.
class BlockedIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    ref.watch(currentAuthUserProvider);
    return ref.watch(safetyRepositoryProvider).fetchBlockedIds();
  }

  bool isBlocked(String userId) => state.valueOrNull?.contains(userId) ?? false;

  Future<void> block(String userId) async {
    await ref.read(safetyRepositoryProvider).block(userId);
    state = AsyncData({...(state.valueOrNull ?? <String>{}), userId});
  }

  Future<void> unblock(String userId) async {
    await ref.read(safetyRepositoryProvider).unblock(userId);
    state = AsyncData({...(state.valueOrNull ?? <String>{})}..remove(userId));
  }
}

final blockedIdsProvider =
    AsyncNotifierProvider<BlockedIdsController, Set<String>>(
        BlockedIdsController.new);

final adminReportsProvider = FutureProvider.autoDispose<List<Report>>((ref) {
  return ref.watch(safetyRepositoryProvider).fetchOpenReports();
});

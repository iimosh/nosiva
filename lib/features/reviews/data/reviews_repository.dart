import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/review.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'reviews';
  static const _select = '*, reviewer:profiles!reviews_reviewer_id_fkey(*)';

  /// Creates or edits the caller's review for [orderId]. RLS only allows this
  /// once the order is delivered and the caller is one of its two
  /// participants reviewing the other.
  Future<Review> upsertReview({
    required String orderId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .upsert({
          'order_id': orderId,
          'reviewer_id': uid,
          'reviewee_id': revieweeId,
          'rating': rating,
          'comment': comment,
        }, onConflict: 'order_id,reviewer_id')
        .select(_select)
        .single();
    return Review.fromJson(data);
  }

  /// The caller's own review for [orderId], if they've already left one.
  Future<Review?> fetchMyReviewForOrder(String orderId) async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('order_id', orderId)
        .eq('reviewer_id', uid)
        .maybeSingle();
    return data == null ? null : Review.fromJson(data);
  }

  /// Reviews a user has received, most recent first.
  Future<List<Review>> fetchForUser(String userId) async {
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);
    return data.map<Review>((e) => Review.fromJson(e)).toList();
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(supabaseClientProvider));
});

final myReviewForOrderProvider =
    FutureProvider.autoDispose.family<Review?, String>((ref, orderId) {
  return ref.watch(reviewsRepositoryProvider).fetchMyReviewForOrder(orderId);
});

final userReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>((ref, userId) {
  return ref.watch(reviewsRepositoryProvider).fetchForUser(userId);
});

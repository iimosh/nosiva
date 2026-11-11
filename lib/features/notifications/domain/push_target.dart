/// The screen a push notification opens when tapped, read from the
/// notification's data (written by supabase/functions/push).
///
/// Only these known screens, with well-formed ids, are accepted — anything
/// else in a notification is ignored rather than navigated to.
sealed class PushTarget {
  const PushTarget();

  static final _uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false);

  static PushTarget? fromData(Map<String, dynamic> data) {
    final id = data['id'];
    switch (data['target']) {
      case 'chat' when id is String && _uuid.hasMatch(id):
        return ChatTarget(id);
      case 'order' when id is String && _uuid.hasMatch(id):
        return OrderTarget(id);
      case 'activity':
        return ActivityTarget(selling: data['tab'] == 'selling');
      case 'reviews' when id is String && _uuid.hasMatch(id):
        return ReviewsTarget(id);
      case 'user' when id is String && _uuid.hasMatch(id):
        return UserTarget(id);
    }
    return null;
  }
}

class ChatTarget extends PushTarget {
  const ChatTarget(this.conversationId);
  final String conversationId;
}

class OrderTarget extends PushTarget {
  const OrderTarget(this.orderId);
  final String orderId;
}

/// Someone's reviews — yours, after someone reviewed you.
class ReviewsTarget extends PushTarget {
  const ReviewsTarget(this.userId);
  final String userId;
}

/// A person's profile — a new follower's.
class UserTarget extends PushTarget {
  const UserTarget(this.userId);
  final String userId;
}

/// Offers, which live in Activity under Buying or Selling.
class ActivityTarget extends PushTarget {
  const ActivityTarget({required this.selling});
  final bool selling;
}

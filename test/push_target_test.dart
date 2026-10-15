import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/features/notifications/domain/push_target.dart';

void main() {
  const id = '3f2b8c1e-1d2a-4c5b-9e8f-0a1b2c3d4e5f';

  test('known screens open with their id', () {
    final chat = PushTarget.fromData({'target': 'chat', 'id': id});
    expect(chat, isA<ChatTarget>());
    expect((chat as ChatTarget).conversationId, id);

    final order = PushTarget.fromData({'target': 'order', 'id': id});
    expect((order as OrderTarget).orderId, id);
  });

  test('offers open Activity on the right side', () {
    final selling =
        PushTarget.fromData({'target': 'activity', 'tab': 'selling'});
    expect((selling as ActivityTarget).selling, isTrue);
    final buying = PushTarget.fromData({'target': 'activity', 'tab': 'buying'});
    expect((buying as ActivityTarget).selling, isFalse);
  });

  test('anything else is ignored, never navigated to', () {
    expect(PushTarget.fromData({}), isNull);
    expect(PushTarget.fromData({'target': 'admin'}), isNull);
    expect(PushTarget.fromData({'target': 'chat'}), isNull);
    expect(PushTarget.fromData({'target': 'chat', 'id': '../admin'}), isNull);
    expect(PushTarget.fromData({'target': 'order', 'id': '$id/x'}), isNull);
    expect(PushTarget.fromData({'target': 'order', 'id': 42}), isNull);
  });
}

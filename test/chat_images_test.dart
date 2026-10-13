import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/features/messaging/data/chat_images.dart';

void main() {
  const convo = '3f2b8c1e-1d2a-4c5b-9e8f-0a1b2c3d4e5f';
  const user = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';
  const file = '0b1c2d3e-4f5a-4b6c-8d7e-9f0a1b2c3d4e.jpg';

  test('new messages store the private path, which is used as is', () {
    expect(chatImagePath('$convo/$user/$file'), '$convo/$user/$file');
  });

  test('old public links are turned into the private path', () {
    const old = 'https://abc.supabase.co/storage/v1/object/public/chat-images/'
        '$convo/$user/$file';
    expect(chatImagePath(old), '$convo/$user/$file');
  });

  test('anything else is never loaded', () {
    // Outside web addresses (would reveal the viewer's IP to that server).
    expect(chatImagePath('https://evil.example.com/pixel.png'), isNull);
    // Other buckets.
    expect(
        chatImagePath('https://abc.supabase.co/storage/v1/object/public/'
            'avatars/$user/a.jpg'),
        isNull);
    // Path tricks.
    expect(chatImagePath('$convo/$user/../../other/$file'), isNull);
    expect(chatImagePath('$convo/$file'), isNull);
    expect(chatImagePath(''), isNull);
  });
}

import 'package:bdo_event/core/common/profile_image/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores external profile image URLs during cleanup', () async {
    await expectLater(
      deleteStoredProfileImage('https://example.com/profile.jpg'),
      completes,
    );
  });

  test('ignores malformed profile image URLs during cleanup', () async {
    await expectLater(deleteStoredProfileImage('not a URL'), completes);
  });

  test('extracts a profile object path from its public URL', () {
    expect(
      profileImageStoragePathFromPublicUrl(
        'https://project.supabase.co/storage/v1/object/public/'
        'profile-images/user-1/avatar.jpg',
      ),
      'user-1/avatar.jpg',
    );
    expect(
      profileImageStoragePathFromPublicUrl(
        'https://project.supabase.co/storage/v1/object/public/event-images/'
        'user-1/avatar.jpg',
      ),
      isNull,
    );
  });
}

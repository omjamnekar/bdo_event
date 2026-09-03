import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/features/auth_screen/data/model/auth_user_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  supabase.User authUser({
    required String? email,
    required Map<String, dynamic> appMetadata,
    required Map<String, dynamic> userMetadata,
  }) => supabase.User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': email,
    'phone': '',
    'created_at': '2026-08-01T00:00:00Z',
    'app_metadata': appMetadata,
    'user_metadata': userMetadata,
    'identities': const [],
  })!;

  test('maps provider metadata, roles, and notification preference', () {
    final entity = AuthUserDto(
      user: authUser(
        email: 'asha@example.com',
        appMetadata: {
          'roles': ['admin', 'watcher'],
        },
        userMetadata: {
          'display_name': 'Asha',
          'photo_url': 'photo.png',
          'phone_number': '555-0100',
          'bio': 'Organizer',
          'locale': 'en-IN',
        },
      ),
      notificationsEnabled: false,
    ).toEntity();

    expect(entity.id, 'user-1');
    expect(entity.displayName, 'Asha');
    expect(entity.email, 'asha@example.com');
    expect(entity.roles, {UserRole.admin, UserRole.watcher});
    expect(entity.photoUrl, 'photo.png');
    expect(entity.phoneNumber, '555-0100');
    expect(entity.bio, 'Organizer');
    expect(entity.notificationsEnabled, isFalse);
  });

  test('accepts a scalar role and falls back to the email local part', () {
    final entity = AuthUserDto(
      user: authUser(
        email: 'dev@example.com',
        appMetadata: {'roles': 'watcher'},
        userMetadata: const {},
      ),
      notificationsEnabled: true,
    ).toEntity();

    expect(entity.displayName, 'dev');
    expect(entity.roles, {UserRole.watcher});
  });

  test('falls back to a standard user and User display name', () {
    final entity = AuthUserDto(
      user: authUser(
        email: null,
        appMetadata: const {},
        userMetadata: const {},
      ),
      notificationsEnabled: true,
    ).toEntity();

    expect(entity.displayName, 'User');
    expect(entity.email, isEmpty);
    expect(entity.roles, {UserRole.user});
  });
}

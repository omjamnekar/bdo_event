import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('returns empty registration counts without contacting Supabase',
      () async {
    final store = SupabaseStore(
      client: SupabaseClient('https://example.supabase.co', 'test-anon-key'),
    );

    expect(await store.loadRegistrationCounts(const []), isEmpty);
  });
}

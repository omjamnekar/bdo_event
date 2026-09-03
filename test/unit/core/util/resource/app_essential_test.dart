import 'package:bdo_event/core/util/resource/app_essential.dart';
import 'package:bdo_event/dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses separate Supabase environment variable names', () {
    expect(AppEssentials.supabaseURLKEY, 'SUPABASE_URL');
    expect(AppEssentials.supabaseAnonKEY, 'SUPABASE_ANON_KEY');
  });

  test('normalizes resolved Supabase configuration values', () {
    final configuration = DotEnvInitialization.fromValues(
      url: ' https://example.supabase.co ',
      anonKey: ' anon-key ',
    );

    expect(configuration?.supabaseUrl, 'https://example.supabase.co');
    expect(configuration?.supabaseAnonKey, 'anon-key');
    expect(
      DotEnvInitialization.fromValues(url: ' ', anonKey: 'anon-key'),
      isNull,
    );
  });
}

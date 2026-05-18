import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';
import '../presentation/controllers/profile_controller.dart';

class SupabaseProfileRepository implements ProfileDataSource {
  const SupabaseProfileRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Stream<UserProfile> watchProfile(String uid) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['uid'])
        .eq('uid', uid)
        .map(
          (rows) => rows.isEmpty
              ? UserProfile.empty(uid)
              : UserProfile.fromSupabaseMap(rows.first),
        );
  }

  @override
  Future<void> updateProfile(UserProfile profile) {
    return _client.from('profiles').upsert(profile.toSupabaseMap());
  }
}

import 'dart:io';

import 'package:image_picker/image_picker.dart';
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

  @override
  Future<String> uploadProfilePicture({
    required String uid,
    required XFile file,
  }) async {
    final nameParts = file.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : 'jpg';
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final path = '$uid/profile-picture-$timestamp.$extension';

    await _client.storage
        .from('post-media')
        .upload(
          path,
          File(file.path),
          fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
        );
    return _client.storage.from('post-media').getPublicUrl(path);
  }
}

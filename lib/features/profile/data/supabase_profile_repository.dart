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
        .asyncMap((rows) => _profileFromRows(uid, rows));
  }

  @override
  Future<void> updateProfile(UserProfile profile) {
    return _client.from('profiles').upsert(profile.toSupabaseMap());
  }

  Future<UserProfile> _profileFromRows(
    String uid,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isNotEmpty) {
      final profile = UserProfile.fromSupabaseMap(rows.first);
      if (!_isEmptyProfile(profile)) {
        return profile;
      }

      final fallback = _profileFromCurrentUser(uid);
      if (!_isEmptyProfile(fallback)) {
        await updateProfile(_mergeProfile(profile, fallback));
        return _mergeProfile(profile, fallback);
      }
      return profile;
    }

    final fallback = _profileFromCurrentUser(uid);
    await updateProfile(fallback);
    return fallback;
  }

  UserProfile _profileFromCurrentUser(String uid) {
    final user = _client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final email = user?.email ?? '';
    final username = metadata['username'] as String? ?? '';
    final fullName = metadata['full_name'] as String? ?? '';

    return UserProfile(
      uid: uid,
      profilePictureUrl: '',
      fullName: fullName.isNotEmpty ? fullName : email,
      studentId: metadata['student_id'] as String? ?? '',
      college: metadata['college'] as String? ?? '',
      department: metadata['department'] as String? ?? '',
      yearLevel: metadata['year_level'] as String? ?? '',
      username: username.isNotEmpty ? username : email.split('@').first,
      bio: '',
      skills: const [],
      portfolioGallery: const [],
      availabilityStatus: 'available',
    );
  }

  UserProfile _mergeProfile(UserProfile profile, UserProfile fallback) {
    return UserProfile(
      uid: profile.uid,
      profilePictureUrl: profile.profilePictureUrl,
      fullName: profile.fullName.isNotEmpty
          ? profile.fullName
          : fallback.fullName,
      studentId: profile.studentId.isNotEmpty
          ? profile.studentId
          : fallback.studentId,
      college: profile.college.isNotEmpty ? profile.college : fallback.college,
      department: profile.department.isNotEmpty
          ? profile.department
          : fallback.department,
      yearLevel: profile.yearLevel.isNotEmpty
          ? profile.yearLevel
          : fallback.yearLevel,
      username: profile.username.isNotEmpty
          ? profile.username
          : fallback.username,
      bio: profile.bio,
      skills: profile.skills,
      portfolioGallery: profile.portfolioGallery,
      availabilityStatus: profile.availabilityStatus,
    );
  }

  bool _isEmptyProfile(UserProfile profile) {
    return profile.fullName.isEmpty &&
        profile.studentId.isEmpty &&
        profile.college.isEmpty &&
        profile.department.isEmpty &&
        profile.yearLevel.isEmpty &&
        profile.username.isEmpty;
  }
}

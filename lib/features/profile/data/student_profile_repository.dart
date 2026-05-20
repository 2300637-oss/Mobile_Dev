import 'profile_models.dart';

abstract class StudentProfileRepository {
  Future<StudentProfileBundle> loadProfile({String? userId, String? email});

  Future<StudentProfile> updateProfile(StudentProfile profile);

  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
  });
}

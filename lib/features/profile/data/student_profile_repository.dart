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

  Future<ProfilePost> updatePost(ProfilePost post);

  Future<void> deletePost(ProfilePost post);

  Future<ProfilePost> updatePostVisibility({
    required ProfilePost post,
    required VisibilityType visibility,
  });

  Future<ProfilePost> pinPost({
    required ProfilePost post,
    required bool pinned,
  });

  Future<void> savePost({required String postId, required String userId});

  Future<void> unsavePost({required String postId, required String userId});

  Future<void> reportPost({required String postId, required String reporterId});

  Future<ProfileService> createService(ProfileService service);

  Future<ProfileService> updateService(ProfileService service);

  Future<void> deleteService(ProfileService service);

  Future<StudentProfile> updateCv({
    required StudentProfile profile,
    required String cvUrl,
  });

  Future<PortfolioItem> createPortfolioItem(PortfolioItem item);

  Future<PortfolioItem> updatePortfolioItem(PortfolioItem item);

  Future<void> deletePortfolioItem(PortfolioItem item);

  Future<ProfileReview> createReview({
    required ProfileReview review,
    required String profileOwnerId,
    required bool completedCommission,
  });

  Future<void> requestCommission({
    required ProfileService service,
    required String requesterId,
    required String profileOwnerId,
  });
}

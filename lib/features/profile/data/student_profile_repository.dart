import 'profile_models.dart';

abstract class StudentProfileRepository {
  Future<StudentProfileBundle> loadProfile({String? userId, String? email});

  Future<StudentProfile> updateProfile(StudentProfile profile);

  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
    ProfileAttachment? attachment,
  });

  Future<void> deletePost({required String profileId, required String postId});

  Future<String> uploadProfileFile({
    required String userId,
    required String path,
    required String fileName,
    required String bucket,
    String? contentType,
  });

  Future<PortfolioItem> createPortfolioItem({
    required String profileId,
    required String title,
    required String description,
  });

  Future<ProfileService> createService({
    required String profileId,
    required String title,
    required String description,
    required String category,
    required String priceRange,
    required String deliveryTime,
    required AvailabilityStatus availability,
  });

  Future<ProfileReview> createReview({
    required String profileId,
    required String reviewerId,
    required String reviewerName,
    required String serviceTitle,
    required int rating,
    required String comment,
  });
}

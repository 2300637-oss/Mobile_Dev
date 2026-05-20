import 'package:image_picker/image_picker.dart';

import '../domain/public_post.dart';

abstract class PublicPostDataSource {
  Stream<List<PublicPost>> watchPosts();

  Stream<List<PublicPost>> watchPostsByAuthor(String authorId);

  Stream<List<PublicPost>> watchSharedPostsByUser(String userId);

  Stream<bool> watchHearted({required String postId, required String userId});

  Stream<List<PostViewer>> watchViewers({required String postId});

  Future<String> createPost(CreatePostDraft draft);

  Future<String> uploadPostMedia({
    required String userId,
    required XFile file,
    required String mediaType,
  });

  Future<({String authorName, String authorDepartment})> getAuthorInfo(
    String userId,
  );

  Future<void> toggleHeart({required String postId, required String userId});

  Future<void> markViewed({required String postId, required String userId});

  Future<void> markShared({required String postId, required String userId});
}

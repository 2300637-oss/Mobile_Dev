import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/auth_user.dart';
import '../../data/public_post_repository.dart';
import '../../domain/public_post.dart';

class CreatePostController extends ChangeNotifier {
  CreatePostController({required PublicPostDataSource repository})
    : _repository = repository;

  final PublicPostDataSource _repository;
  final ImagePicker _imagePicker = ImagePicker();

  XFile? selectedFile;
  String mediaType = 'none';
  bool isSaving = false;
  String? errorMessage;

  Future<void> pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) {
      return;
    }
    selectedFile = file;
    mediaType = 'image';
    errorMessage = null;
    notifyListeners();
  }

  Future<void> pickVideo() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    selectedFile = file;
    mediaType = 'video';
    errorMessage = null;
    notifyListeners();
  }

  void clearMedia() {
    selectedFile = null;
    mediaType = 'none';
    notifyListeners();
  }

  Future<bool> createPost({
    required AuthUser user,
    required String postType,
    required String caption,
  }) async {
    final trimmedCaption = caption.trim();
    if (trimmedCaption.isEmpty && selectedFile == null) {
      errorMessage = 'Add a caption or attach an image/video.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final mediaUrls = <String>[];
      if (selectedFile != null) {
        mediaUrls.add(
          await _repository.uploadPostMedia(
            userId: user.id,
            file: selectedFile!,
            mediaType: mediaType,
          ),
        );
      }
      final authorInfo = await _repository.getAuthorInfo(user.id);

      await _repository.createPost(
        CreatePostDraft(
          authorId: user.id,
          authorName: authorInfo.authorName,
          authorEmail: user.email ?? '',
          authorDepartment: authorInfo.authorDepartment,
          type: postType,
          caption: trimmedCaption,
          mediaUrls: mediaUrls,
          mediaType: mediaType,
        ),
      );
      return true;
    } catch (error) {
      errorMessage = 'Unable to create post. Please try again.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}

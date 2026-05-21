import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/user_profile.dart';

abstract class ProfileDataSource {
  Stream<UserProfile> watchProfile(String uid);

  Future<void> updateProfile(UserProfile profile);
}

class ProfileController extends ChangeNotifier {
  ProfileController({
    required ProfileDataSource profileRepository,
    required String uid,
  }) : _profileRepository = profileRepository,
       _uid = uid;

  final ProfileDataSource _profileRepository;
  final String _uid;
  StreamSubscription<UserProfile>? _profileSubscription;

  UserProfile? profile;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  void start() {
    _profileSubscription = _profileRepository
        .watchProfile(_uid)
        .listen(
          (profile) {
            this.profile = profile;
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = _messageForError(error);
            isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> saveProfile(UserProfile profile) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.updateProfile(profile);
      return true;
    } catch (error) {
      errorMessage = _messageForError(error);
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

  String _messageForError(Object error) {
    return 'Unable to update profile. Please try again.';
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}

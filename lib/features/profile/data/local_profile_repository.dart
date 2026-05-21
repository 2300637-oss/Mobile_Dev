import 'dart:async';

import '../domain/user_profile.dart';
import '../presentation/controllers/profile_controller.dart';

class LocalProfileRepository implements ProfileDataSource {
  LocalProfileRepository({UserProfile? initialProfile}) {
    if (initialProfile != null) {
      _profiles[initialProfile.uid] = initialProfile;
    }
  }

  static final Map<String, UserProfile> _profiles = {};
  static final Map<String, StreamController<UserProfile>> _controllers = {};

  @override
  Stream<UserProfile> watchProfile(String uid) async* {
    final profile = _profiles.putIfAbsent(uid, () => UserProfile.empty(uid));
    yield profile;
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
    _controllerFor(profile.uid).add(profile);
  }

  static StreamController<UserProfile> _controllerFor(String uid) {
    return _controllers.putIfAbsent(
      uid,
      () => StreamController<UserProfile>.broadcast(),
    );
  }
}

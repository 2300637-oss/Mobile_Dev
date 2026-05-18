import 'package:cloud_firestore/cloud_firestore.dart';

import '../presentation/controllers/profile_controller.dart';
import '../domain/user_profile.dart';

class ProfileRepository implements ProfileDataSource {
  const ProfileRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile> watchProfile(String uid) {
    return _firestore
        .collection('profiles')
        .doc(uid)
        .snapshots()
        .map((snapshot) => UserProfile.fromMap(snapshot.id, snapshot.data()));
  }

  @override
  Future<void> updateProfile(UserProfile profile) {
    return _firestore.collection('profiles').doc(profile.uid).set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

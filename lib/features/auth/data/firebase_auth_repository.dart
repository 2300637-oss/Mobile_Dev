import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return _requireUser(credential.user);
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String fullName,
    required String studentId,
    required String collegeDepartment,
    required String username,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (!trimmedEmail.endsWith('@lnu.edu.ph')) {
      throw const AuthFailure('Only LNU email addresses can register.');
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    final user = _requireUser(credential.user);
    final trimmedName = fullName.trim();
    final trimmedStudentId = studentId.trim();
    final trimmedCollegeDepartment = collegeDepartment.trim();
    final trimmedUsername = username.trim();

    await credential.user!.updateDisplayName(trimmedName);
    await credential.user!.sendEmailVerification();
    await _firestore.collection('users').doc(user.id).set({
      'uid': user.id,
      'email': user.email,
      'fullName': trimmedName,
      'studentId': trimmedStudentId,
      'collegeDepartment': trimmedCollegeDepartment,
      'username': trimmedUsername,
      'role': 'user',
      'emailVerified': credential.user!.emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('profiles').doc(user.id).set({
      'uid': user.id,
      'profilePictureUrl': '',
      'fullName': trimmedName,
      'studentId': trimmedStudentId,
      'collegeDepartment': trimmedCollegeDepartment,
      'username': trimmedUsername,
      'bio': '',
      'skills': <String>[],
      'portfolioGallery': <String>[],
      'availabilityStatus': 'available',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return AuthUser(
      id: user.id,
      email: user.email,
      emailVerified: credential.user!.emailVerified,
      displayName: trimmedName,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sign in before requesting verification.');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<AuthUser?> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    await user.reload();
    return _mapFirebaseUser(_firebaseAuth.currentUser);
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  AuthUser _requireUser(User? user) {
    final mappedUser = _mapFirebaseUser(user);
    if (mappedUser == null) {
      throw const AuthFailure('Authentication completed without a user.');
    }
    return mappedUser;
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      id: user.uid,
      email: user.email,
      emailVerified: user.emailVerified,
      displayName: user.displayName,
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

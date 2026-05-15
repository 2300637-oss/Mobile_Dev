import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthUser> registerWithEmailAndPassword({
    required String fullName,
    required String studentId,
    required String collegeDepartment,
    required String username,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<AuthUser?> reloadCurrentUser();

  Future<void> signOut();
}

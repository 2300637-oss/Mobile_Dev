import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/firebase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthUser? currentUser;
  bool isInitializing = true;
  bool isBusy = false;
  String? errorMessage;

  void start() {
    _authSubscription = _authRepository.authStateChanges().listen(
      (user) {
        currentUser = user;
        isInitializing = false;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = _messageForError(error);
        isInitializing = false;
        notifyListeners();
      },
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(
      () => _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> register({
    required String fullName,
    required String studentId,
    required String collegeDepartment,
    required String username,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _authRepository.registerWithEmailAndPassword(
        fullName: fullName,
        studentId: studentId,
        collegeDepartment: collegeDepartment,
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return _runAuthAction(() => _authRepository.sendPasswordResetEmail(email));
  }

  Future<bool> sendEmailVerification() async {
    return _runAuthAction(_authRepository.sendEmailVerification);
  }

  Future<bool> reloadCurrentUser() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authRepository.reloadCurrentUser();
      return true;
    } catch (error) {
      errorMessage = _messageForError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _runAuthAction(_authRepository.signOut);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = _messageForError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String _messageForError(Object error) {
    if (error is FirebaseAuthException) {
      final message = error.message ?? '';
      if (message.contains('CONFIGURATION_NOT_FOUND')) {
        return 'Firebase Authentication is not enabled yet. In Firebase Console, open Authentication, click Get started, and enable Email/Password sign-in.';
      }

      return switch (error.code) {
        'email-already-in-use' => 'That email is already registered.',
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' => 'The email or password is incorrect.',
        'operation-not-allowed' =>
          'Email/password sign-in is disabled in Firebase Console.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' => 'No account was found for that email.',
        'weak-password' => 'Use a stronger password.',
        'wrong-password' => 'The email or password is incorrect.',
        _ =>
          message.isEmpty
              ? 'Authentication failed. Please try again.'
              : message,
      };
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firebase blocked this request. Check your Firestore security rules for users and profiles.';
      }
      return error.message ?? 'Firebase failed. Please try again.';
    }

    if (error is AuthFailure) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

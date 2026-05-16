import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

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
    required String college,
    required String department,
    required String yearLevel,
    required String username,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _authRepository.registerWithEmailAndPassword(
        fullName: fullName,
        studentId: studentId,
        college: college,
        department: department,
        yearLevel: yearLevel,
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
    if (error is AuthException) {
      final message = error.message.trim();
      final lowerMessage = message.toLowerCase();

      if (lowerMessage.contains('user already registered') ||
          lowerMessage.contains('already registered')) {
        return 'That email is already registered. Try logging in instead.';
      }
      if (lowerMessage.contains('signup') &&
          lowerMessage.contains('disabled')) {
        return 'Email signup is disabled in Supabase. Open Authentication > Providers > Email and enable signup.';
      }
      if (lowerMessage.contains('invalid login credentials')) {
        return 'The email or password is incorrect.';
      }
      if (lowerMessage.contains('email not confirmed')) {
        return 'Please verify your email first. Open the confirmation link sent to your LNU inbox.';
      }
      if (lowerMessage.contains('rate limit') ||
          lowerMessage.contains('too many')) {
        return 'Supabase is rate limiting email sends. Please wait a few minutes, then try again.';
      }
      if (lowerMessage.contains('invalid email')) {
        return 'Enter a valid LNU email address ending with @lnu.edu.ph.';
      }

      return message.isEmpty
          ? 'Supabase authentication failed. Please try again.'
          : message;
    }

    if (error is PostgrestException) {
      final message = error.message.trim();
      if (message.contains('relation') && message.contains('does not exist')) {
        return 'Supabase database tables are missing. Run supabase_schema.sql in the Supabase SQL Editor first.';
      }
      if (error.code == '42501' ||
          message.toLowerCase().contains('row-level security')) {
        return 'Supabase blocked this request with RLS. Check the policies from supabase_schema.sql.';
      }
      return message.isEmpty
          ? 'Supabase database request failed. Please try again.'
          : message;
    }

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

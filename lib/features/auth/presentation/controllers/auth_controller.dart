import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';
import '../../../profile/domain/user_profile.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._authRepository, {
    this.useStaticLogin = false,
    this.requireEmailVerification = false,
  });

  static const AuthUser _staticUser = AuthUser(
    id: '00000000-0000-4000-8000-000000000001',
    email: 'student@lnu.edu.ph',
    emailVerified: true,
    displayName: 'LNU Student',
  );

  final AuthRepository _authRepository;
  final bool useStaticLogin;
  final bool requireEmailVerification;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthUser? currentUser;
  bool isInitializing = true;
  bool isBusy = false;
  String? errorMessage;
  UserProfile? staticProfile;

  void start() {
    if (useStaticLogin) {
      currentUser = _staticUser;
      staticProfile = UserProfile.empty(_staticUser.id);
      isInitializing = false;
      notifyListeners();
      return;
    }

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
    if (useStaticLogin) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();

      currentUser = _staticUser;
      staticProfile ??= UserProfile.empty(_staticUser.id);
      isBusy = false;
      notifyListeners();
      return true;
    }

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
    if (useStaticLogin) {
      final user = AuthUser(
        id: _staticIdFromEmail(email),
        email: email.trim().toLowerCase(),
        emailVerified: true,
        displayName: username.trim().isEmpty
            ? fullName.trim()
            : username.trim(),
      );

      currentUser = user;
      staticProfile = UserProfile(
        uid: user.id,
        profilePictureUrl: '',
        fullName: fullName.trim(),
        studentId: studentId.trim(),
        college: college.trim(),
        department: department.trim(),
        yearLevel: yearLevel.trim(),
        username: username.trim(),
        bio: '',
        skills: const [],
        portfolioGallery: const [],
        availabilityStatus: 'available',
      );
      errorMessage = null;
      notifyListeners();
      return true;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final registeredUser = await _authRepository.registerWithEmailAndPassword(
        fullName: fullName,
        studentId: studentId,
        college: college,
        department: department,
        yearLevel: yearLevel,
        username: username,
        email: email,
        password: password,
      );
      if (!requireEmailVerification) {
        currentUser = registeredUser;
      }
      return true;
    } catch (error) {
      errorMessage = _messageForError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
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
    if (useStaticLogin) {
      currentUser = null;
      staticProfile = null;
      errorMessage = null;
      notifyListeners();
      return;
    }

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

  String _staticIdFromEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return _staticUser.id;
    }

    final hash = normalizedEmail.codeUnits.fold<int>(
      0,
      (value, codeUnit) => ((value * 31) + codeUnit) & 0x7fffffff,
    );
    final suffix = hash.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
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

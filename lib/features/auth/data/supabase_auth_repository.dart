import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _mapSupabaseUser(_client.auth.currentUser);
    yield* _client.auth.onAuthStateChange.map(
      (state) => _mapSupabaseUser(state.session?.user),
    );
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    return _requireUser(response.user);
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String fullName,
    required String studentId,
    required String college,
    required String department,
    required String yearLevel,
    required String username,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (!trimmedEmail.endsWith('@lnu.edu.ph')) {
      throw const AuthFailure('Only LNU email addresses can register.');
    }

    final response = await _client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'username': username.trim(),
        'student_id': studentId.trim(),
        'college': college.trim(),
        'department': department.trim(),
        'year_level': yearLevel.trim(),
      },
    );
    final user = _requireUser(response.user);

    try {
      await _client.from('users').upsert({
        'uid': user.id,
        'email': user.email,
        'full_name': fullName.trim(),
        'student_id': studentId.trim(),
        'college': college.trim(),
        'department': department.trim(),
        'year_level': yearLevel.trim(),
        'username': username.trim(),
        'role': 'user',
        'email_verified': user.emailVerified,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _client.from('profiles').upsert({
        'uid': user.id,
        'profile_picture_url': '',
        'full_name': fullName.trim(),
        'student_id': studentId.trim(),
        'college': college.trim(),
        'department': department.trim(),
        'year_level': yearLevel.trim(),
        'username': username.trim(),
        'bio': '',
        'skills': <String>[],
        'portfolio_gallery': <String>[],
        'availability_status': 'available',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Supabase may not create a session until email confirmation. The SQL
      // trigger in supabase_schema.sql creates these rows server-side.
    }

    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  @override
  Future<void> sendEmailVerification() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw const AuthFailure('Sign in before requesting verification.');
    }
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<AuthUser?> reloadCurrentUser() async {
    final response = await _client.auth.getUser();
    return _mapSupabaseUser(response.user);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  AuthUser _requireUser(User? user) {
    final mappedUser = _mapSupabaseUser(user);
    if (mappedUser == null) {
      throw const AuthFailure('Authentication completed without a user.');
    }
    return mappedUser;
  }

  AuthUser? _mapSupabaseUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      id: user.id,
      email: user.email,
      emailVerified: user.emailConfirmedAt != null,
      displayName:
          user.userMetadata?['username'] as String? ??
          user.userMetadata?['full_name'] as String?,
    );
  }
}

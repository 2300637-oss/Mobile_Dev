import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield await _mapAndEnsureSupabaseUser(_client.auth.currentUser);
    yield* _client.auth.onAuthStateChange.asyncMap(
      (state) => _mapAndEnsureSupabaseUser(state.session?.user),
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
    try {
      await _ensureUserRows(response.user);
    } catch (_) {
      // Profile row repair must not block a valid Supabase Auth sign-in.
      // The user can still enter the app; profile screens have safe fallbacks.
    }
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
      emailRedirectTo: _emailRedirectTo,
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
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _emailRedirectTo,
    );
  }

  String? get _emailRedirectTo {
    if (!kIsWeb) {
      return null;
    }
    return '${Uri.base.origin}/auth/callback';
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

  Future<AuthUser?> _mapAndEnsureSupabaseUser(User? user) async {
    if (user == null) {
      return null;
    }

    try {
      await _ensureUserRows(user);
    } catch (_) {
      // Keep auth state usable even if public.users/profiles RLS or FK setup
      // needs repair in Supabase.
    }
    return _mapSupabaseUser(user);
  }

  Future<void> _ensureUserRows(User? user) async {
    if (user == null) {
      return;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = metadata['full_name'] as String? ?? '';
    final username = metadata['username'] as String? ?? '';
    final studentId = metadata['student_id'] as String? ?? '';
    final college = metadata['college'] as String? ?? '';
    final department = metadata['department'] as String? ?? '';
    final yearLevel = metadata['year_level'] as String? ?? '';

    final users = await _client
        .from('users')
        .select('uid')
        .eq('uid', user.id)
        .limit(1);
    if (users.isEmpty) {
      await _client.from('users').insert({
        'uid': user.id,
        'email': user.email ?? '',
        'full_name': fullName,
        'student_id': studentId,
        'college': college,
        'department': department,
        'year_level': yearLevel,
        'username': username,
        'role': 'user',
        'email_verified': user.emailConfirmedAt != null,
      });
    }

    final profiles = await _client
        .from('profiles')
        .select(
          'uid, full_name, username, student_id, college, department, year_level',
        )
        .eq('uid', user.id)
        .limit(1);
    if (profiles.isEmpty) {
      await _client.from('profiles').insert({
        'uid': user.id,
        'profile_picture_url': '',
        'full_name': fullName,
        'student_id': studentId,
        'college': college,
        'department': department,
        'year_level': yearLevel,
        'username': username,
        'bio': '',
        'skills': <String>[],
        'portfolio_gallery': <String>[],
        'availability_status': 'available',
      });
      return;
    }

    final profile = profiles.first;
    final isMostlyEmpty =
        (profile['full_name'] as String? ?? '').isEmpty &&
        (profile['username'] as String? ?? '').isEmpty &&
        (profile['student_id'] as String? ?? '').isEmpty &&
        (profile['college'] as String? ?? '').isEmpty &&
        (profile['department'] as String? ?? '').isEmpty &&
        (profile['year_level'] as String? ?? '').isEmpty;
    final hasMetadata = [
      fullName,
      username,
      studentId,
      college,
      department,
      yearLevel,
    ].any((value) => value.isNotEmpty);
    if (isMostlyEmpty && hasMetadata) {
      await _client
          .from('profiles')
          .update({
            'full_name': fullName,
            'student_id': studentId,
            'college': college,
            'department': department,
            'year_level': yearLevel,
            'username': username,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);
    }
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

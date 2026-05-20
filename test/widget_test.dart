import 'package:commission_app/app/app.dart';
import 'package:commission_app/features/auth/domain/auth_repository.dart';
import 'package:commission_app/features/auth/domain/auth_user.dart';
import 'package:commission_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen for signed out users', (tester) async {
    await tester.pumpWidget(
      CommissionApp(
        authRepository: _FakeAuthRepository(),
        useStaticLogin: false,
        requireEmailVerification: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  test('validates auth form values', () {
    expect(AuthValidators.email('bad-email'), isNotNull);
    expect(AuthValidators.email('artist@example.com'), isNull);
    expect(AuthValidators.lnuEmail('artist@example.com'), isNotNull);
    expect(AuthValidators.lnuEmail('artist@lnu.edu.ph'), isNull);
    expect(AuthValidators.password('12345'), isNotNull);
    expect(AuthValidators.password('123456'), isNull);
    expect(AuthValidators.username('ab'), isNotNull);
    expect(AuthValidators.username('artist_01'), isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> reloadCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}

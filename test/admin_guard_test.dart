import 'package:commission_app/features/admin/admin_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin access service allows role admin records', () async {
    final service = AdminAccessService(
      currentUserIdLoader: () => 'user-1',
      roleLookup: (_) async => const [
        AdminRoleRecord(table: 'profiles', data: {'role': 'admin'}),
      ],
    );

    final decision = await service.load();

    expect(decision.status, AdminAccessStatus.allowed);
  });

  test('admin access service allows snake-case admin flags', () async {
    final service = AdminAccessService(
      currentUserIdLoader: () => 'user-1',
      roleLookup: (_) async => const [
        AdminRoleRecord(table: 'profiles', data: {'is_admin': true}),
      ],
    );

    final decision = await service.load();

    expect(decision.status, AdminAccessStatus.allowed);
  });

  test('admin access service denies non-admin records', () async {
    final service = AdminAccessService(
      currentUserIdLoader: () => 'user-1',
      roleLookup: (_) async => const [
        AdminRoleRecord(table: 'profiles', data: {'role': 'student'}),
      ],
    );

    final decision = await service.load();

    expect(decision.status, AdminAccessStatus.denied);
  });

  testWidgets('admin guard renders child for admin users', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminGuard(
          loadAccess: () async => const AdminAccessDecision.allowed(),
          child: const Text('Admin dashboard content'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Admin dashboard content'), findsOneWidget);
    expect(find.text('Access Denied'), findsNothing);
  });

  testWidgets('admin guard denies authenticated non-admin users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminGuard(
          loadAccess: () async => const AdminAccessDecision.denied(),
          child: const Text('Admin dashboard content'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Admin dashboard content'), findsNothing);
  });

  testWidgets('admin guard redirects signed-out users to login', (
    tester,
  ) async {
    var redirected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AdminGuard(
          loadAccess: () async => const AdminAccessDecision.signedOut(),
          onLoginRequired: () => redirected = true,
          child: const Text('Admin dashboard content'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(redirected, isTrue);
    expect(find.text('Admin dashboard content'), findsNothing);
  });
}

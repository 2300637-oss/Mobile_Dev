import 'package:commission_app/features/admin/admin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard renders and switches sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboardPage()));

    expect(find.text('Dashboard overview'), findsWidgets);
    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);

    await tester.tap(find.text('Reports').first);
    await tester.pumpAndSettle();

    expect(find.text('Reports & Moderation'), findsWidgets);
    expect(find.text('Scam/Fraud'), findsOneWidget);
  });

  testWidgets('admin dashboard notification panel toggles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboardPage()));

    expect(find.text('Notifications'), findsNothing);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.textContaining('student verifications'), findsOneWidget);
  });
}

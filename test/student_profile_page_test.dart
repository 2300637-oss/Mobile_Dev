import 'package:commission_app/features/profile/data/mock_profile_data.dart';
import 'package:commission_app/features/profile/data/profile_models.dart';
import 'package:commission_app/features/profile/presentation/student_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StudentProfile uses safe defaults for missing Supabase fields', () {
    final profile = StudentProfile.fromMap(const {
      'id': 'profile-1',
      'full_name': 'Ana Reyes',
      'skills': ['Digital Art'],
      'verified': true,
    });

    expect(profile.id, 'profile-1');
    expect(profile.fullName, 'Ana Reyes');
    expect(profile.username, '@student');
    expect(profile.skills, ['Digital Art']);
    expect(profile.availability, AvailabilityStatus.open);
    expect(profile.visibility, VisibilityType.lnuPublic);
    expect(profile.stats.posts, 0);
    expect(profile.toMap()['profile_visibility'], 'lnu_public');
  });

  testWidgets('student profile renders prototype sections and tabs', (
    tester,
  ) async {
    await tester.pumpWidget(_profileHarness());
    await tester.pumpAndSettle();

    expect(find.text('LNU SKILLHUB'), findsOneWidget);
    expect(find.text('Ana Reyes'), findsWidgets);
    expect(find.text('Verified LNU Student'), findsWidgets);
    expect(find.text('Open for Commissions'), findsWidgets);
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Average Rating'), findsOneWidget);
    expect(
      find.text('What skill update do you want to share?'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.byKey(const Key('profile-tab-services')));
    await tester.pumpAndSettle();
    expect(find.text('Commission Services'), findsOneWidget);
    expect(find.text('Digital Portrait Illustration'), findsOneWidget);
    expect(find.text('Request Commission'), findsWidgets);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-portfolio')));
    await tester.pumpAndSettle();
    expect(find.text('Curriculum Vitae'), findsOneWidget);
    expect(find.text('View CV'), findsOneWidget);
    expect(find.text('Featured Work'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-reviews')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Only verified students who have completed a commission can leave a review.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mark Villanueva'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-about')));
    await tester.pumpAndSettle();
    expect(find.text('Academic Profile'), findsOneWidget);
    expect(find.text('Profile Visibility'), findsOneWidget);
  });

  testWidgets('student profile supports local post creation, like, and save', (
    tester,
  ) async {
    await tester.pumpWidget(_profileHarness());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-post-input')),
      'New capstone poster slots are open this week.',
    );
    await tester.ensureVisible(
      find.byKey(const Key('profile-post-visibility')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-post-visibility')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-post-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-post-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('New capstone poster slots are open this week.'),
      findsOneWidget,
    );
    expect(find.text('Private'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('post-heart-post-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-heart-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('35'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('post-save-post-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-save-post-1')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsWidgets);
  });

  testWidgets('edit profile sheet updates local profile state', (tester) async {
    await tester.pumpWidget(_profileHarness());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-profile-name')),
      'Ana Marie Reyes',
    );
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Ana Marie Reyes'), findsWidgets);
  });
}

Widget _profileHarness() {
  return MaterialApp(
    home: StudentProfilePage(repository: MockProfileRepository()),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    420,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
}

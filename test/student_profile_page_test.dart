import 'package:commission_app/features/profile/data/mock_profile_data.dart';
import 'package:commission_app/features/profile/data/profile_models.dart';
import 'package:commission_app/features/profile/data/student_profile_repository.dart';
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

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Ana Reyes'), findsWidgets);
    expect(find.text('Open for Commissions'), findsWidgets);
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(
      find.text('What skill update do you want to share?'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.byKey(const Key('profile-tab-services')));
    await tester.pumpAndSettle();
    expect(find.text('Commission Services'), findsOneWidget);
    expect(find.text('Digital Portrait Illustration'), findsOneWidget);
    expect(find.text('Owner tools'), findsWidgets);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-portfolio')));
    await tester.pumpAndSettle();
    expect(find.text('Curriculum Vitae'), findsOneWidget);
    expect(find.text('No CV uploaded yet'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
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

  testWidgets('owner cannot request commission or review themselves', (
    tester,
  ) async {
    await tester.pumpWidget(
      _profileHarness(currentUserId: mockStudentProfile.userId),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('profile-tab-services')));
    await tester.pumpAndSettle();

    expect(find.text('Request Commission'), findsNothing);
    expect(find.text('Owner tools'), findsWidgets);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-reviews')));
    await tester.pumpAndSettle();

    expect(find.text('You cannot review your own profile.'), findsOneWidget);
  });

  testWidgets('visitor can request commission and only sees report post menu', (
    tester,
  ) async {
    await tester.pumpWidget(_profileHarness(currentUserId: 'visitor-user-id'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-profile-button')), findsNothing);
    expect(find.text('Message'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-services')));
    await tester.pumpAndSettle();
    expect(find.text('Request Commission'), findsWidgets);

    await _tapVisible(tester, find.byKey(const Key('profile-tab-posts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-menu-post-1')));
    await tester.pumpAndSettle();

    expect(find.text('Report post'), findsOneWidget);
    expect(find.text('Edit post'), findsNothing);
    expect(find.text('Delete post'), findsNothing);
  });

  testWidgets('owner sees owner post menu actions', (tester) async {
    await tester.pumpWidget(
      _profileHarness(currentUserId: mockStudentProfile.userId),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('post-menu-post-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-menu-post-1')));
    await tester.pumpAndSettle();

    expect(find.text('Pin post'), findsOneWidget);
    expect(find.text('Save post'), findsOneWidget);
    expect(find.text('Edit post'), findsOneWidget);
    expect(find.text('Edit audience'), findsOneWidget);
    expect(find.text('Delete post'), findsOneWidget);
    expect(find.text('Report post'), findsNothing);
  });

  testWidgets('search icon expands into a focused field', (tester) async {
    await tester.pumpWidget(_profileHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-search-field')), findsNothing);
    await tester.tap(find.byKey(const Key('profile-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-search-field')), findsOneWidget);
    expect(find.byKey(const Key('profile-search-close')), findsOneWidget);
  });

  testWidgets('student profile supports local post creation, like, and save', (
    tester,
  ) async {
    final repository = RecordingProfileRepository();
    await tester.pumpWidget(
      _profileHarness(
        currentUserId: mockStudentProfile.userId,
        repository: repository,
      ),
    );
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
    expect(repository.createdPosts.last.visibility, VisibilityType.private);

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

  testWidgets(
    'default public profile post creation uses feed-compatible path',
    (tester) async {
      final repository = RecordingProfileRepository();
      await tester.pumpWidget(
        _profileHarness(
          currentUserId: mockStudentProfile.userId,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('profile-post-input')),
        'This public profile update should appear in the newsfeed.',
      );
      await tester.ensureVisible(find.byKey(const Key('profile-post-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-post-submit')));
      await tester.pumpAndSettle();

      expect(repository.publicFeedCreateCount, 1);
      expect(repository.createdPosts.last.visibility, VisibilityType.lnuPublic);
    },
  );

  testWidgets('edit profile sheet updates local profile state', (tester) async {
    await tester.pumpWidget(
      _profileHarness(currentUserId: mockStudentProfile.userId),
    );
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

Widget _profileHarness({
  String? currentUserId,
  String? profileUserId,
  StudentProfileRepository? repository,
}) {
  return MaterialApp(
    home: StudentProfilePage(
      currentUserId: currentUserId ?? mockStudentProfile.userId,
      currentUserEmail: 'student@lnu.edu.ph',
      profileUserId: profileUserId ?? mockStudentProfile.userId,
      repository: repository ?? MockProfileRepository(),
      onHomeRequested: () {},
      onLogout: () {},
    ),
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

class RecordingProfileRepository extends MockProfileRepository {
  final List<ProfilePost> createdPosts = [];
  int publicFeedCreateCount = 0;

  @override
  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
  }) async {
    final post = await super.createPost(
      profileId: profileId,
      authorId: authorId,
      content: content,
      visibility: visibility,
    );
    createdPosts.add(post);
    if (visibility == VisibilityType.lnuPublic) {
      publicFeedCreateCount += 1;
    }
    return post;
  }
}

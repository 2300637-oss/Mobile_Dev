import 'package:flutter/material.dart';

import '../data/mock_profile_data.dart';
import '../data/profile_models.dart';
import '../data/student_profile_repository.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/portfolio_card.dart';
import 'widgets/post_composer.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';
import 'widgets/profile_style.dart';
import 'widgets/profile_tabs.dart';
import 'widgets/review_card.dart';
import 'widgets/service_card.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    StudentProfileRepository? repository,
    this.currentUserId,
    this.currentUserEmail,
  }) : repository = repository ?? const _DefaultMockRepository();

  final StudentProfileRepository repository;
  final String? currentUserId;
  final String? currentUserEmail;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  StudentProfileBundle? _bundle;
  ProfileTab _activeTab = ProfileTab.posts;
  final Set<String> _likedPostIds = {};
  final Set<String> _savedPostIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkillHubProfileColors.grayBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bundle == null
            ? _EmptyProfileState(message: _errorMessage)
            : _buildProfile(context, _bundle!),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, StudentProfileBundle bundle) {
    final profile = bundle.profile;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                ProfileHeader(
                  profile: profile,
                  onEditProfile: _showEditProfileSheet,
                  onMessage: () => _showSnack('Messaging opens from chat.'),
                  onShare: () => _showSnack('Profile share link copied.'),
                ),
                const SizedBox(height: 14),
                ProfileTabs(
                  activeTab: _activeTab,
                  onChanged: (tab) => setState(() => _activeTab = tab),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 840;
                    final main = _MainTabContent(
                      activeTab: _activeTab,
                      bundle: bundle,
                      likedPostIds: _likedPostIds,
                      savedPostIds: _savedPostIds,
                      onCreatePost: _createPost,
                      onToggleLike: _toggleLike,
                      onToggleSave: _toggleSave,
                      onSnack: _showSnack,
                    );
                    final side = _SideProfilePanels(
                      profile: profile,
                      onRequest: () =>
                          _showSnack('Commission request started.'),
                    );

                    if (!wide) {
                      return Column(
                        children: [main, const SizedBox(height: 12), side],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: main),
                        const SizedBox(width: 14),
                        SizedBox(width: 288, child: side),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bundle = await widget.repository.loadProfile(
        userId: widget.currentUserId,
        email: widget.currentUserEmail,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = mockStudentProfileBundle;
        _isLoading = false;
        _errorMessage = 'Unable to load live profile data. Showing mock data.';
      });
    }
  }

  Future<void> _createPost(String content, VisibilityType visibility) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final profile = bundle.profile;
    final post = await widget.repository.createPost(
      profileId: profile.id,
      authorId: widget.currentUserId ?? profile.userId,
      content: content,
      visibility: visibility,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _bundle = bundle.copyWith(
        profile: profile.copyWith(
          stats: profile.stats.copyWith(posts: profile.stats.posts + 1),
        ),
        posts: [post, ...bundle.posts],
      );
    });
  }

  Future<void> _showEditProfileSheet() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: .92,
          child: EditProfileSheet(
            profile: bundle.profile,
            onSave: (profile) => _saveProfile(bundle, profile),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(
    StudentProfileBundle bundle,
    StudentProfile profile,
  ) async {
    setState(() => _bundle = bundle.copyWith(profile: profile));
    try {
      await widget.repository.updateProfile(profile);
      _showSnack('Profile saved.');
    } catch (_) {
      _showSnack('Profile saved locally. Live sync is unavailable.');
    }
  }

  void _toggleLike(String postId) {
    setState(() {
      if (!_likedPostIds.add(postId)) {
        _likedPostIds.remove(postId);
      }
    });
  }

  void _toggleSave(String postId) {
    setState(() {
      if (!_savedPostIds.add(postId)) {
        _savedPostIds.remove(postId);
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DefaultMockRepository implements StudentProfileRepository {
  const _DefaultMockRepository();

  @override
  Future<ProfilePost> createPost({
    required String profileId,
    required String authorId,
    required String content,
    required VisibilityType visibility,
  }) {
    return MockProfileRepository().createPost(
      profileId: profileId,
      authorId: authorId,
      content: content,
      visibility: visibility,
    );
  }

  @override
  Future<StudentProfileBundle> loadProfile({String? userId, String? email}) {
    return MockProfileRepository().loadProfile(userId: userId, email: email);
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) {
    return MockProfileRepository().updateProfile(profile);
  }
}

class _MainTabContent extends StatelessWidget {
  const _MainTabContent({
    required this.activeTab,
    required this.bundle,
    required this.likedPostIds,
    required this.savedPostIds,
    required this.onCreatePost,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onSnack,
  });

  final ProfileTab activeTab;
  final StudentProfileBundle bundle;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return switch (activeTab) {
      ProfileTab.posts => _PostsTab(
        bundle: bundle,
        likedPostIds: likedPostIds,
        savedPostIds: savedPostIds,
        onCreatePost: onCreatePost,
        onToggleLike: onToggleLike,
        onToggleSave: onToggleSave,
        onSnack: onSnack,
      ),
      ProfileTab.services => _ServicesTab(bundle: bundle, onSnack: onSnack),
      ProfileTab.portfolio => PortfolioSection(
        profile: bundle.profile,
        items: bundle.portfolioItems,
        onViewCv: () =>
            onSnack('CV viewer will open when file storage is wired.'),
        onDownloadCv: () =>
            onSnack('CV download will be available after storage setup.'),
        onAddLink: () =>
            onSnack('Portfolio link editor will open from profile editing.'),
      ),
      ProfileTab.reviews => ReviewsSection(
        profile: bundle.profile,
        reviews: bundle.reviews,
        ratingDistribution: bundle.ratingDistribution,
      ),
      ProfileTab.about => _AboutTab(profile: bundle.profile),
    };
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.bundle,
    required this.likedPostIds,
    required this.savedPostIds,
    required this.onCreatePost,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onSnack,
  });

  final StudentProfileBundle bundle;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PostComposer(
          profile: bundle.profile,
          onPost: onCreatePost,
          onToolPressed: (label) =>
              onSnack('$label is ready for storage wiring.'),
        ),
        const SizedBox(height: 12),
        for (final post in bundle.posts) ...[
          ProfilePostCard(
            post: post,
            profile: bundle.profile,
            liked: likedPostIds.contains(post.id),
            saved: savedPostIds.contains(post.id),
            onToggleLike: () => onToggleLike(post.id),
            onToggleSave: () => onToggleSave(post.id),
            onComment: () =>
                onSnack('Comments will open from the post thread.'),
            onShare: () => onSnack('Post share link copied.'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.bundle, required this.onSnack});

  final StudentProfileBundle bundle;
  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Commission Services',
                        style: profileSectionTitleStyle(),
                      ),
                    ),
                    Chip(
                      label: Text('${bundle.services.length} offers'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse available services and request a commission. Payment and delivery details are shown per offer.',
                  style: TextStyle(
                    color: SkillHubProfileColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth > 560;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: bundle.services.map((service) {
                    return SizedBox(
                      width: twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: ServiceCard(
                        service: service,
                        onRequest: () => onSnack(
                          'Commission request for ${service.title} started.',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutSection(
            title: 'About',
            icon: Icons.person_outline,
            child: Text(
              profile.bio,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
          ),
          _AboutSection(
            title: 'Academic Profile',
            icon: Icons.school_outlined,
            child: Column(
              children: [
                _AboutRow(label: 'College', value: profile.college),
                _AboutRow(label: 'Department', value: profile.department),
                _AboutRow(label: 'Year Level', value: profile.yearLevel),
                _AboutRow(label: 'Joined SkillHub', value: profile.joinedLabel),
              ],
            ),
          ),
          _AboutSection(
            title: 'Skills & Expertise',
            icon: Icons.layers_outlined,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.skills
                  .map((skill) => Chip(label: Text(skill)))
                  .toList(),
            ),
          ),
          _AboutSection(
            title: 'Contact',
            icon: Icons.mail_outline,
            child: Column(
              children: [
                _AboutRow(label: 'LNU Email', value: profile.email),
                _AboutRow(
                  label: 'Contact Pref.',
                  value: profile.contactPreference,
                ),
                _AboutRow(
                  label: 'Portfolio',
                  value: profile.portfolioLinks.join(', '),
                ),
              ],
            ),
          ),
          _AboutSection(
            title: 'Profile Visibility',
            icon: Icons.visibility_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VisibilitySummary(visibility: profile.visibility),
                const SizedBox(height: 10),
                const _InfoNote(
                  text:
                      'This profile is visible only to verified LNU students on SkillHub. External access is not permitted.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideProfilePanels extends StatelessWidget {
  const _SideProfilePanels({required this.profile, required this.onRequest});

  final StudentProfile profile;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SideCard(
          title: 'Quick Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SideRow(icon: Icons.school_outlined, text: profile.college),
              _SideRow(
                icon: Icons.workspace_premium_outlined,
                text: profile.yearLevel,
              ),
              _SideRow(
                icon: Icons.calendar_today_outlined,
                text: 'Joined ${profile.joinedLabel}',
              ),
              if (profile.verified)
                const _SideRow(
                  icon: Icons.verified_user_outlined,
                  text: 'Verified Student',
                  color: Color(0xFF059669),
                ),
              const Divider(height: 20),
              const _SideRow(
                icon: Icons.public,
                text: 'LNU Public profile',
                color: SkillHubProfileColors.textSub,
              ),
              const Text(
                'Only verified LNU students can view this profile.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ),
        _SideCard(
          title: 'Rating Summary',
          child: Row(
            children: [
              Text(
                profile.stats.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: SkillHubProfileColors.yellow,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${profile.stats.reviews} reviews\n${profile.stats.completed} commissions completed',
                  style: const TextStyle(
                    color: SkillHubProfileColors.textSub,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        _SideCard(
          title: 'Portfolio Links',
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: profile.portfolioLinks
                .map(
                  (link) => Chip(
                    avatar: const Icon(Icons.open_in_new, size: 13),
                    label: Text(link),
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                )
                .toList(),
          ),
        ),
        _SideCard(
          title: 'Skills',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.skills
                .map((skill) => Chip(label: Text(skill)))
                .toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFF059669), size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open for Commissions',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ana is currently accepting commission requests. Check the Services tab for pricing and delivery details.',
                style: TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 15),
                  label: const Text('Request Commission'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SkillHubProfileColors.navy, size: 15),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: SkillHubProfileColors.midBlue,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: SkillHubProfileColors.textSub,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(
                color: SkillHubProfileColors.textMain,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilitySummary extends StatelessWidget {
  const _VisibilitySummary({required this.visibility});

  final VisibilityType visibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 14, color: SkillHubProfileColors.navy),
          const SizedBox(width: 6),
          Text(
            '${visibility.label} - ${visibility.description}',
            style: const TextStyle(
              color: SkillHubProfileColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SkillHubProfileColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: SkillHubProfileColors.textSub,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: SkillHubProfileColors.textSub,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: profileSectionTitleStyle()),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({
    required this.icon,
    required this.text,
    this.color = SkillHubProfileColors.textMain,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: SkillHubProfileColors.textSub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_person_outlined,
              size: 54,
              color: SkillHubProfileColors.navy,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in with a verified LNU account to view profiles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SkillHubProfileColors.textSub),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

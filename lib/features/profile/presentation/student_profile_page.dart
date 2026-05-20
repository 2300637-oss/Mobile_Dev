import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_profile_data.dart';
import '../data/profile_models.dart';
import '../data/student_profile_repository.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/portfolio_card.dart';
import 'widgets/post_composer.dart';
import 'widgets/profile_edit_sheets.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';
import 'widgets/profile_style.dart';
import 'widgets/profile_tabs.dart';
import 'widgets/review_card.dart';
import 'widgets/service_card.dart';

class StudentProfilePage extends StatefulWidget {
  StudentProfilePage({
    super.key,
    StudentProfileRepository? repository,
    this.currentUserId,
    this.currentUserEmail,
    this.profileUserId,
    this.onHomeRequested,
    this.onLogout,
  }) : repository = repository ?? MockProfileRepository();

  final StudentProfileRepository repository;
  final String? currentUserId;
  final String? currentUserEmail;
  final String? profileUserId;
  final VoidCallback? onHomeRequested;
  final VoidCallback? onLogout;

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
    final isOwner =
        widget.currentUserId != null && widget.currentUserId == profile.userId;

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
                  isOwner: isOwner,
                  onHome: _goHome,
                  onMyProfile: _goMyProfile,
                  onEditProfile: _showEditProfileSheet,
                  onMessage: _startMessage,
                  onShare: () => _showSnack('Profile share link copied.'),
                  onLogout: widget.onLogout,
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
                      isOwner: isOwner,
                      currentUserId: widget.currentUserId,
                      likedPostIds: _likedPostIds,
                      savedPostIds: _savedPostIds,
                      onCreatePost: _createPost,
                      onToggleLike: _toggleLike,
                      onToggleSave: _toggleSave,
                      onTogglePin: _togglePin,
                      onEditPost: _showEditPostSheet,
                      onEditPostAudience: _showEditAudienceSheet,
                      onDeletePost: _confirmDeletePost,
                      onReportPost: _reportPost,
                      onRequestCommission: _requestCommission,
                      onCreateService: _showServiceSheet,
                      onEditService: _showServiceSheet,
                      onDeleteService: _confirmDeleteService,
                      onEditCv: _showCvSheet,
                      onAddPortfolioItem: _showPortfolioItemSheet,
                      onEditPortfolioItem: _showPortfolioItemSheet,
                      onDeletePortfolioItem: _confirmDeletePortfolioItem,
                      onSnack: _showSnack,
                    );
                    ProfileService? requestableService;
                    for (final service in bundle.services) {
                      if (service.availability.canRequest) {
                        requestableService = service;
                        break;
                      }
                    }
                    final side = _SideProfilePanels(
                      profile: profile,
                      isOwner: isOwner,
                      canRequestCommission: requestableService != null,
                      onRequest: requestableService == null
                          ? null
                          : () => _requestCommission(requestableService!),
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
        userId: widget.profileUserId ?? widget.currentUserId,
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
        posts: _orderedPosts([post, ...bundle.posts]),
      );
    });
  }

  void _goHome() {
    if (widget.onHomeRequested != null) {
      widget.onHomeRequested!();
      return;
    }
    // TODO: Home feed currently refreshes through its Supabase stream. If a
    // manual refresh hook is added later, trigger it here before navigation.
    context.go('/home');
  }

  void _goMyProfile() {
    context.go('/profile');
  }

  void _startMessage() {
    final bundle = _bundle;
    if (bundle == null || widget.currentUserId == bundle.profile.userId) {
      return;
    }
    _showSnack('Messaging will be available soon.');
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

  Future<void> _toggleSave(String postId) async {
    final userId = widget.currentUserId;
    setState(() {
      if (!_savedPostIds.add(postId)) {
        _savedPostIds.remove(postId);
      }
    });
    if (userId == null) {
      return;
    }
    try {
      if (_savedPostIds.contains(postId)) {
        await widget.repository.savePost(postId: postId, userId: userId);
      } else {
        await widget.repository.unsavePost(postId: postId, userId: userId);
      }
    } catch (_) {
      _showSnack('Saved locally. Live sync is unavailable.');
    }
  }

  Future<void> _togglePin(ProfilePost post) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    final updated = post.copyWith(isPinned: !post.isPinned);
    _replacePost(updated);
    try {
      await widget.repository.pinPost(post: post, pinned: updated.isPinned);
    } catch (_) {
      _showSnack('Pin updated locally. Live sync is unavailable.');
    }
  }

  Future<void> _showEditPostSheet(ProfilePost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EditPostSheet(
        post: post,
        onSave: (updated) async {
          _replacePost(updated);
          try {
            await widget.repository.updatePost(updated);
          } catch (_) {
            _showSnack('Post updated locally. Live sync is unavailable.');
          }
        },
      ),
    );
  }

  Future<void> _showEditAudienceSheet(ProfilePost post) async {
    final selected = await showModalBottomSheet<VisibilityType>(
      context: context,
      showDragHandle: true,
      builder: (context) => AudienceSheet(selected: post.visibility),
    );
    if (selected == null) {
      return;
    }
    final updated = post.copyWith(visibility: selected);
    _replacePost(updated);
    try {
      await widget.repository.updatePostVisibility(
        post: post,
        visibility: selected,
      );
    } catch (_) {
      _showSnack('Audience updated locally. Live sync is unavailable.');
    }
  }

  Future<void> _confirmDeletePost(ProfilePost post) async {
    final confirmed = await _confirm(
      title: 'Delete post?',
      message: 'This removes the post from your profile.',
    );
    if (!confirmed) {
      return;
    }
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    setState(() {
      _bundle = bundle.copyWith(
        posts: bundle.posts.where((item) => item.id != post.id).toList(),
      );
    });
    try {
      await widget.repository.deletePost(post);
    } catch (_) {
      _showSnack('Post deleted locally. Live sync is unavailable.');
    }
  }

  Future<void> _reportPost(ProfilePost post) async {
    final reporterId = widget.currentUserId;
    if (reporterId == null) {
      _showSnack('Sign in to report posts.');
      return;
    }
    try {
      await widget.repository.reportPost(
        postId: post.id,
        reporterId: reporterId,
      );
      _showSnack('Post reported for moderation.');
    } catch (_) {
      _showSnack('Unable to report this post right now.');
    }
  }

  Future<void> _requestCommission(ProfileService service) async {
    final bundle = _bundle;
    final requesterId = widget.currentUserId;
    if (bundle == null || requesterId == null) {
      _showSnack('Sign in to request a commission.');
      return;
    }
    try {
      await widget.repository.requestCommission(
        service: service,
        requesterId: requesterId,
        profileOwnerId: bundle.profile.userId,
      );
      _showSnack('Commission request started.');
    } on ProfileActionBlocked catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Commission requests will be available soon.');
    }
  }

  Future<void> _showServiceSheet([ProfileService? service]) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ServiceEditSheet(
        service: service,
        profileId: bundle.profile.id,
        onSave: (saved) async {
          final isNew = service == null;
          final localService = saved.copyWith(
            id: saved.id.isEmpty
                ? 'local-service-${DateTime.now().microsecondsSinceEpoch}'
                : saved.id,
          );
          setState(() {
            _bundle = bundle.copyWith(
              services: isNew
                  ? [localService, ...bundle.services]
                  : bundle.services
                        .map(
                          (item) =>
                              item.id == localService.id ? localService : item,
                        )
                        .toList(),
            );
          });
          try {
            if (isNew) {
              await widget.repository.createService(localService);
            } else {
              await widget.repository.updateService(localService);
            }
          } catch (_) {
            _showSnack('Service saved locally. Live sync is unavailable.');
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteService(ProfileService service) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    final confirmed = await _confirm(
      title: 'Delete service?',
      message: 'Students will no longer see this commission offer.',
    );
    if (!confirmed) {
      return;
    }
    setState(() {
      _bundle = bundle.copyWith(
        services: bundle.services
            .where((item) => item.id != service.id)
            .toList(),
      );
    });
    try {
      await widget.repository.deleteService(service);
    } catch (_) {
      _showSnack('Service deleted locally. Live sync is unavailable.');
    }
  }

  Future<void> _showCvSheet() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CvEditSheet(
        profile: bundle.profile,
        onSave: (cvUrl) async {
          final profile = bundle.profile.copyWith(cvUrl: cvUrl);
          setState(() => _bundle = bundle.copyWith(profile: profile));
          try {
            await widget.repository.updateCv(
              profile: bundle.profile,
              cvUrl: cvUrl,
            );
          } catch (_) {
            _showSnack('CV updated locally. File upload is still pending.');
          }
        },
      ),
    );
  }

  Future<void> _showPortfolioItemSheet([PortfolioItem? item]) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => PortfolioItemEditSheet(
        item: item,
        profileId: bundle.profile.id,
        onSave: (saved) async {
          final isNew = item == null;
          final localItem = saved.copyWith(
            id: saved.id.isEmpty
                ? 'local-portfolio-${DateTime.now().microsecondsSinceEpoch}'
                : saved.id,
          );
          setState(() {
            _bundle = bundle.copyWith(
              portfolioItems: isNew
                  ? [localItem, ...bundle.portfolioItems]
                  : bundle.portfolioItems
                        .map(
                          (entry) =>
                              entry.id == localItem.id ? localItem : entry,
                        )
                        .toList(),
            );
          });
          try {
            if (isNew) {
              await widget.repository.createPortfolioItem(localItem);
            } else {
              await widget.repository.updatePortfolioItem(localItem);
            }
          } catch (_) {
            _showSnack(
              'Portfolio saved locally. File upload is still pending.',
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeletePortfolioItem(PortfolioItem item) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    final confirmed = await _confirm(
      title: 'Delete portfolio item?',
      message: 'This removes the project from your profile.',
    );
    if (!confirmed) {
      return;
    }
    setState(() {
      _bundle = bundle.copyWith(
        portfolioItems: bundle.portfolioItems
            .where((entry) => entry.id != item.id)
            .toList(),
      );
    });
    try {
      await widget.repository.deletePortfolioItem(item);
    } catch (_) {
      _showSnack('Portfolio item deleted locally. Live sync is unavailable.');
    }
  }

  void _replacePost(ProfilePost updated) {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    setState(() {
      _bundle = bundle.copyWith(
        posts: _orderedPosts(
          bundle.posts
              .map((post) => post.id == updated.id ? updated : post)
              .toList(),
        ),
      );
    });
  }

  List<ProfilePost> _orderedPosts(List<ProfilePost> posts) {
    final sorted = [...posts];
    sorted.sort((left, right) {
      if (left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
    return sorted;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
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

class _MainTabContent extends StatelessWidget {
  const _MainTabContent({
    required this.activeTab,
    required this.bundle,
    required this.isOwner,
    required this.currentUserId,
    required this.likedPostIds,
    required this.savedPostIds,
    required this.onCreatePost,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onTogglePin,
    required this.onEditPost,
    required this.onEditPostAudience,
    required this.onDeletePost,
    required this.onReportPost,
    required this.onRequestCommission,
    required this.onCreateService,
    required this.onEditService,
    required this.onDeleteService,
    required this.onEditCv,
    required this.onAddPortfolioItem,
    required this.onEditPortfolioItem,
    required this.onDeletePortfolioItem,
    required this.onSnack,
  });

  final ProfileTab activeTab;
  final StudentProfileBundle bundle;
  final bool isOwner;
  final String? currentUserId;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<ProfilePost> onTogglePin;
  final ValueChanged<ProfilePost> onEditPost;
  final ValueChanged<ProfilePost> onEditPostAudience;
  final ValueChanged<ProfilePost> onDeletePost;
  final ValueChanged<ProfilePost> onReportPost;
  final ValueChanged<ProfileService> onRequestCommission;
  final VoidCallback onCreateService;
  final ValueChanged<ProfileService> onEditService;
  final ValueChanged<ProfileService> onDeleteService;
  final VoidCallback onEditCv;
  final VoidCallback onAddPortfolioItem;
  final ValueChanged<PortfolioItem> onEditPortfolioItem;
  final ValueChanged<PortfolioItem> onDeletePortfolioItem;
  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return switch (activeTab) {
      ProfileTab.posts => _PostsTab(
        bundle: bundle,
        isOwner: isOwner,
        currentUserId: currentUserId,
        likedPostIds: likedPostIds,
        savedPostIds: savedPostIds,
        onCreatePost: onCreatePost,
        onToggleLike: onToggleLike,
        onToggleSave: onToggleSave,
        onTogglePin: onTogglePin,
        onEditPost: onEditPost,
        onEditPostAudience: onEditPostAudience,
        onDeletePost: onDeletePost,
        onReportPost: onReportPost,
        onSnack: onSnack,
      ),
      ProfileTab.services => _ServicesTab(
        bundle: bundle,
        isOwner: isOwner,
        onRequestCommission: onRequestCommission,
        onCreateService: onCreateService,
        onEditService: onEditService,
        onDeleteService: onDeleteService,
        onSnack: onSnack,
      ),
      ProfileTab.portfolio => PortfolioSection(
        profile: bundle.profile,
        items: bundle.portfolioItems,
        isOwner: isOwner,
        onViewCv: () =>
            onSnack('CV viewer will open when file storage is wired.'),
        onDownloadCv: () =>
            onSnack('CV download will be available after storage setup.'),
        onEditCv: onEditCv,
        onAddLink: () => onSnack('Portfolio link editor is a TODO.'),
        onAddProject: onAddPortfolioItem,
        onEditItem: onEditPortfolioItem,
        onDeleteItem: onDeletePortfolioItem,
      ),
      ProfileTab.reviews => ReviewsSection(
        profile: bundle.profile,
        reviews: bundle.reviews,
        ratingDistribution: bundle.ratingDistribution,
        isOwner: isOwner,
      ),
      ProfileTab.about => _AboutTab(profile: bundle.profile),
    };
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.bundle,
    required this.isOwner,
    required this.currentUserId,
    required this.likedPostIds,
    required this.savedPostIds,
    required this.onCreatePost,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onTogglePin,
    required this.onEditPost,
    required this.onEditPostAudience,
    required this.onDeletePost,
    required this.onReportPost,
    required this.onSnack,
  });

  final StudentProfileBundle bundle;
  final bool isOwner;
  final String? currentUserId;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<ProfilePost> onTogglePin;
  final ValueChanged<ProfilePost> onEditPost;
  final ValueChanged<ProfilePost> onEditPostAudience;
  final ValueChanged<ProfilePost> onDeletePost;
  final ValueChanged<ProfilePost> onReportPost;
  final ValueChanged<String> onSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isOwner) ...[
          PostComposer(
            profile: bundle.profile,
            onPost: onCreatePost,
            onToolPressed: (label) =>
                onSnack('$label is ready for storage wiring.'),
          ),
          const SizedBox(height: 12),
        ],
        for (final post in bundle.posts) ...[
          ProfilePostCard(
            post: post,
            profile: bundle.profile,
            liked: likedPostIds.contains(post.id),
            saved: savedPostIds.contains(post.id),
            isOwner: currentUserId != null && currentUserId == post.authorId,
            onToggleLike: () => onToggleLike(post.id),
            onToggleSave: () => onToggleSave(post.id),
            onComment: () =>
                onSnack('Comments will open from the post thread.'),
            onShare: () => onSnack('Post share link copied.'),
            onPinToggle: () => onTogglePin(post),
            onEdit: () => onEditPost(post),
            onEditAudience: () => onEditPostAudience(post),
            onDelete: () => onDeletePost(post),
            onReport: () => onReportPost(post),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.bundle,
    required this.isOwner,
    required this.onRequestCommission,
    required this.onCreateService,
    required this.onEditService,
    required this.onDeleteService,
    required this.onSnack,
  });

  final StudentProfileBundle bundle;
  final bool isOwner;
  final ValueChanged<ProfileService> onRequestCommission;
  final VoidCallback onCreateService;
  final ValueChanged<ProfileService> onEditService;
  final ValueChanged<ProfileService> onDeleteService;
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
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onCreateService,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Add Service'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner
                      ? 'Manage the services students can request from your SkillHub profile.'
                      : 'Browse available services and request a commission. Payment and delivery details are shown per offer.',
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
                        isOwner: isOwner,
                        onRequest: () => onRequestCommission(service),
                        onEdit: () => onEditService(service),
                        onDelete: () => onDeleteService(service),
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
  const _SideProfilePanels({
    required this.profile,
    required this.isOwner,
    required this.canRequestCommission,
    required this.onRequest,
  });

  final StudentProfile profile;
  final bool isOwner;
  final bool canRequestCommission;
  final VoidCallback? onRequest;

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
        if (profile.availability.canRequest)
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
                Text(
                  '${profile.fullName} is currently accepting commission requests. Check the Services tab for pricing and delivery details.',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (!isOwner && canRequestCommission) ...[
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

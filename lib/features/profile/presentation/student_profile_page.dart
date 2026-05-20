import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../posts/data/public_post_repository.dart';
import '../../posts/data/supabase_public_post_repository.dart';
import '../../posts/domain/public_post.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
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
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  onEditProfile: _showEditProfileSheet,
                  onEditAvatar: _pickAvatarImage,
                  onEditCover: _pickCoverImage,
                  onNotifications: () => context.go('/notifications'),
                  onMenu: _showProfileMenu,
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
                      onDeletePost: _deletePost,
                      onSnack: _showSnack,
                      onUploadCv: _pickCvFile,
                      onAddPortfolioLink: _showAddPortfolioLinkDialog,
                      onAddProject: _showAddProjectDialog,
                      onCreateService: _showAddServiceDialog,
                      onCreateReview: null,
                      currentUserId: widget.currentUserId,
                      publicPostsRepository: SupabasePublicPostRepository(
                        client: Supabase.instance.client,
                      ),
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
      final savedProfile = await widget.repository.updateProfile(profile);
      if (!mounted) {
        return;
      }
      setState(() => _bundle = bundle.copyWith(profile: savedProfile));
      _showSnack('Profile saved.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(_friendlyProfileError(error, 'Profile saved locally only.'));
    }
  }

  Future<void> _pickCoverImage() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !mounted) {
      return;
    }

    try {
      final url = await widget.repository.uploadProfileFile(
        userId: bundle.profile.userId,
        path: image.path,
        fileName: image.name,
        bucket: 'profile-media',
        contentType: image.mimeType ?? 'image/jpeg',
      );
      final profile = bundle.profile.copyWith(coverUrl: url);
      await _saveProfile(bundle, profile);
    } catch (error) {
      _showSnack(_friendlyProfileError(error, 'Could not upload cover photo.'));
    }
  }

  Future<void> _pickAvatarImage() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !mounted) {
      return;
    }

    try {
      final url = await widget.repository.uploadProfileFile(
        userId: bundle.profile.userId,
        path: image.path,
        fileName: image.name,
        bucket: 'profile-media',
        contentType: image.mimeType ?? 'image/jpeg',
      );
      final profile = bundle.profile.copyWith(avatarUrl: url);
      await _saveProfile(bundle, profile);
    } catch (error) {
      _showSnack(
        _friendlyProfileError(error, 'Could not upload profile photo.'),
      );
    }
  }

  Future<void> _pickCvFile() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final file = await file_selector.openFile(
      acceptedTypeGroups: const [
        file_selector.XTypeGroup(
          label: 'Documents',
          extensions: ['pdf', 'doc', 'docx'],
        ),
      ],
    );
    if (file == null || !mounted) {
      return;
    }

    try {
      final url = await widget.repository.uploadProfileFile(
        userId: bundle.profile.userId,
        path: file.path,
        fileName: file.name,
        bucket: 'profile-documents',
        contentType: file.mimeType ?? 'application/octet-stream',
      );
      final profile = bundle.profile.copyWith(cvUrl: url);
      await _saveProfile(bundle, profile);
    } catch (error) {
      _showSnack(_friendlyProfileError(error, 'Could not upload CV.'));
    }
  }

  Future<void> _showAddPortfolioLinkDialog() async {
    final link = await showDialog<String>(
      context: context,
      builder: (context) => const _PortfolioLinkDialog(),
    );

    final bundle = _bundle;
    final normalizedLink = _normalizePortfolioLink(link);
    if (bundle == null || normalizedLink.isEmpty) {
      return;
    }

    final links = {
      ...bundle.profile.portfolioLinks,
      normalizedLink,
    }.toList(growable: false);
    await _saveProfile(bundle, bundle.profile.copyWith(portfolioLinks: links));
    _showSnack('Portfolio link added.');
  }

  String _normalizePortfolioLink(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '';
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    return 'https://$text';
  }

  Future<void> _showAddProjectDialog() async {
    final result = await showDialog<_FeaturedWorkDraft>(
      context: context,
      builder: (context) => const _FeaturedWorkDialog(),
    );

    final bundle = _bundle;
    if (bundle == null || result == null || result.title.isEmpty) {
      return;
    }

    try {
      final project = await widget.repository.createPortfolioItem(
        profileId: bundle.profile.id,
        title: result.title,
        description: result.description.isEmpty
            ? 'Featured portfolio project'
            : result.description,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle.copyWith(
          portfolioItems: [project, ...bundle.portfolioItems],
        );
      });
      _showSnack('Featured work added.');
    } catch (error) {
      _showSnack(_friendlyProfileError(error, 'Could not add featured work.'));
    }
  }

  Future<void> _showAddServiceDialog() async {
    final result = await showDialog<_ServiceOfferDraft>(
      context: context,
      builder: (context) => const _ServiceOfferDialog(),
    );

    final bundle = _bundle;
    if (bundle == null || result == null || result.title.isEmpty) {
      return;
    }

    try {
      final service = await widget.repository.createService(
        profileId: bundle.profile.id,
        title: result.title,
        description: result.description.isEmpty
            ? 'Message me to discuss the commission details.'
            : result.description,
        category: result.category.isEmpty ? 'General' : result.category,
        priceRange: result.priceRange.isEmpty
            ? 'Price negotiable'
            : result.priceRange,
        deliveryTime: result.deliveryTime.isEmpty
            ? 'To be discussed'
            : result.deliveryTime,
        availability: AvailabilityStatus.open,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle.copyWith(services: [service, ...bundle.services]);
      });
      _showSnack('Service offer created.');
    } catch (error) {
      _showSnack(
        _friendlyProfileError(error, 'Could not create service offer.'),
      );
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chat'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/chat');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/notifications');
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Create Post'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/create-post');
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _deletePost(String postId) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This removes the post from your profile.'),
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
    if (confirmed != true) {
      return;
    }

    setState(() {
      _bundle = bundle.copyWith(
        posts: bundle.posts.where((post) => post.id != postId).toList(),
        profile: bundle.profile.copyWith(
          stats: bundle.profile.stats.copyWith(
            posts: (bundle.profile.stats.posts - 1).clamp(0, 1 << 31),
          ),
        ),
      );
    });
    await widget.repository.deletePost(
      profileId: bundle.profile.id,
      postId: postId,
    );
    _showSnack('Post deleted.');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyProfileError(Object error, String fallback) {
    if (error is StorageException) {
      final message = error.message.toLowerCase();
      if (message.contains('row-level security') ||
          message.contains('not authorized') ||
          message.contains('unauthorized')) {
        return '$fallback Check Supabase storage policies for profile-media/profile-documents.';
      }
      return '$fallback ${error.message}';
    }
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('row-level security') ||
          message.contains('permission denied')) {
        return '$fallback Check Supabase RLS policies.';
      }
      return '$fallback ${error.message}';
    }
    return fallback;
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

  @override
  Future<void> deletePost({required String profileId, required String postId}) {
    return MockProfileRepository().deletePost(
      profileId: profileId,
      postId: postId,
    );
  }

  @override
  Future<PortfolioItem> createPortfolioItem({
    required String profileId,
    required String title,
    required String description,
  }) {
    return MockProfileRepository().createPortfolioItem(
      profileId: profileId,
      title: title,
      description: description,
    );
  }

  @override
  Future<ProfileService> createService({
    required String profileId,
    required String title,
    required String description,
    required String category,
    required String priceRange,
    required String deliveryTime,
    required AvailabilityStatus availability,
  }) {
    return MockProfileRepository().createService(
      profileId: profileId,
      title: title,
      description: description,
      category: category,
      priceRange: priceRange,
      deliveryTime: deliveryTime,
      availability: availability,
    );
  }

  @override
  Future<ProfileReview> createReview({
    required String profileId,
    required String reviewerId,
    required String reviewerName,
    required String serviceTitle,
    required int rating,
    required String comment,
  }) {
    return MockProfileRepository().createReview(
      profileId: profileId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      serviceTitle: serviceTitle,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<String> uploadProfileFile({
    required String userId,
    required String path,
    required String fileName,
    required String bucket,
    String? contentType,
  }) {
    return MockProfileRepository().uploadProfileFile(
      userId: userId,
      path: path,
      fileName: fileName,
      bucket: bucket,
      contentType: contentType,
    );
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
    required this.onDeletePost,
    required this.onSnack,
    required this.onUploadCv,
    required this.onAddPortfolioLink,
    required this.onAddProject,
    required this.onCreateService,
    required this.onCreateReview,
    required this.currentUserId,
    required this.publicPostsRepository,
  });

  final ProfileTab activeTab;
  final StudentProfileBundle bundle;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<String> onDeletePost;
  final ValueChanged<String> onSnack;
  final VoidCallback onUploadCv;
  final VoidCallback onAddPortfolioLink;
  final VoidCallback onAddProject;
  final VoidCallback onCreateService;
  final VoidCallback? onCreateReview;
  final String? currentUserId;
  final PublicPostDataSource publicPostsRepository;

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
        onDeletePost: onDeletePost,
        onSnack: onSnack,
        currentUserId: currentUserId,
        publicPostsRepository: publicPostsRepository,
      ),
      ProfileTab.services => _ServicesTab(
        bundle: bundle,
        onSnack: onSnack,
        onCreateService: onCreateService,
      ),
      ProfileTab.portfolio => PortfolioSection(
        profile: bundle.profile,
        items: bundle.portfolioItems,
        onViewCv: () =>
            _openExternalLink(context, bundle.profile.cvUrl, onSnack),
        onDownloadCv: () => _shareExternalLink(
          bundle.profile.cvUrl,
          onSnack,
          emptyMessage: 'Upload your CV first.',
        ),
        onUploadCv: onUploadCv,
        onAddLink: onAddPortfolioLink,
        onAddProject: onAddProject,
      ),
      ProfileTab.reviews => ReviewsSection(
        profile: bundle.profile,
        reviews: bundle.reviews,
        ratingDistribution: bundle.ratingDistribution,
        onAddReview: onCreateReview,
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
    required this.onDeletePost,
    required this.onSnack,
    required this.currentUserId,
    required this.publicPostsRepository,
  });

  final StudentProfileBundle bundle;
  final Set<String> likedPostIds;
  final Set<String> savedPostIds;
  final void Function(String content, VisibilityType visibility) onCreatePost;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleSave;
  final ValueChanged<String> onDeletePost;
  final ValueChanged<String> onSnack;
  final String? currentUserId;
  final PublicPostDataSource publicPostsRepository;

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
        if (currentUserId != null && currentUserId!.isNotEmpty) ...[
          _SharedPublicPostsPanel(
            userId: currentUserId!,
            repository: publicPostsRepository,
          ),
          const SizedBox(height: 12),
        ],
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
            onShare: () =>
                _shareProfilePost(profile: bundle.profile, post: post),
            onDelete: () => onDeletePost(post.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _shareProfilePost({
    required StudentProfile profile,
    required ProfilePost post,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        text:
            '${profile.fullName} on LNU Student Skills Commission: ${post.content}',
      ),
    );
  }
}

Future<void> _openExternalLink(
  BuildContext context,
  String link,
  ValueChanged<String> onSnack,
) async {
  final uri = _uriFor(link);
  if (uri == null) {
    onSnack('No link available yet.');
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    onSnack('Could not open link.');
  }
}

Future<void> _shareExternalLink(
  String link,
  ValueChanged<String> onSnack, {
  required String emptyMessage,
}) async {
  if (link.trim().isEmpty) {
    onSnack(emptyMessage);
    return;
  }
  await SharePlus.instance.share(ShareParams(text: link));
}

Uri? _uriFor(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  return Uri.tryParse(
    text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text',
  );
}

class _SharedPublicPostsPanel extends StatelessWidget {
  const _SharedPublicPostsPanel({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final PublicPostDataSource repository;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      child: StreamBuilder<List<PublicPost>>(
        stream: repository.watchSharedPostsByUser(userId),
        builder: (context, snapshot) {
          final posts = snapshot.data ?? const <PublicPost>[];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_outlined,
                      color: SkillHubProfileColors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Shared posts',
                        style: TextStyle(
                          color: SkillHubProfileColors.textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go('/users/$userId/shared-posts'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Posts you share from the homepage will appear here.',
                    style: TextStyle(
                      color: SkillHubProfileColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      for (final post in posts.take(3)) ...[
                        _SharedPublicPostTile(post: post),
                        if (post != posts.take(3).last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SharedPublicPostTile extends StatelessWidget {
  const _SharedPublicPostTile({required this.post});

  final PublicPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SkillHubProfileColors.blueAccent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
              image: post.mediaUrls.isNotEmpty && !post.hasVideo
                  ? DecorationImage(
                      image: NetworkImage(post.mediaUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.mediaUrls.isEmpty || post.hasVideo
                ? Icon(
                    post.hasVideo
                        ? Icons.play_circle_outline
                        : Icons.article_outlined,
                    color: SkillHubProfileColors.blueAccent,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkillHubProfileColors.textMain,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SkillHubProfileColors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TinyPublicPostStat(
                      icon: Icons.favorite,
                      value: post.heartCount,
                    ),
                    const SizedBox(width: 10),
                    _TinyPublicPostStat(
                      icon: Icons.share_outlined,
                      value: post.shareCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPublicPostStat extends StatelessWidget {
  const _TinyPublicPostStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SkillHubProfileColors.textSub),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: SkillHubProfileColors.textSub,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PortfolioLinkDialog extends StatefulWidget {
  const _PortfolioLinkDialog();

  @override
  State<_PortfolioLinkDialog> createState() => _PortfolioLinkDialogState();
}

class _PortfolioLinkDialogState extends State<_PortfolioLinkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Portfolio Link'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Portfolio URL',
          hintText: 'https://behance.net/your-name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _FeaturedWorkDraft {
  const _FeaturedWorkDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _FeaturedWorkDialog extends StatefulWidget {
  const _FeaturedWorkDialog();

  @override
  State<_FeaturedWorkDialog> createState() => _FeaturedWorkDialogState();
}

class _FeaturedWorkDialogState extends State<_FeaturedWorkDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Featured Work'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Project title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Short description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _FeaturedWorkDraft(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ServiceOfferDraft {
  const _ServiceOfferDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priceRange,
    required this.deliveryTime,
  });

  final String title;
  final String description;
  final String category;
  final String priceRange;
  final String deliveryTime;
}

class _ServiceOfferDialog extends StatefulWidget {
  const _ServiceOfferDialog();

  @override
  State<_ServiceOfferDialog> createState() => _ServiceOfferDialogState();
}

class _ServiceOfferDialogState extends State<_ServiceOfferDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Offer a Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Service title',
                hintText: 'Digital portrait illustration',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What will the client receive?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Digital Art, Logo, Poster Layout',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price range',
                hintText: 'PHP 250 - PHP 600',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryController,
              decoration: const InputDecoration(
                labelText: 'Delivery time',
                hintText: '5-7 days',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ServiceOfferDraft(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                category: _categoryController.text.trim(),
                priceRange: _priceController.text.trim(),
                deliveryTime: _deliveryController.text.trim(),
              ),
            );
          },
          child: const Text('Create Offer'),
        ),
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.bundle,
    required this.onSnack,
    required this.onCreateService,
  });

  final StudentProfileBundle bundle;
  final ValueChanged<String> onSnack;
  final VoidCallback onCreateService;

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
                    IconButton.filledTonal(
                      tooltip: 'Offer service',
                      onPressed: onCreateService,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 8),
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
          if (bundle.services.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: FilledButton.icon(
                onPressed: onCreateService,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Create your first service offer'),
              ),
            )
          else
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
                'This student is currently accepting commission requests. Check the Services tab for pricing and delivery details.',
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

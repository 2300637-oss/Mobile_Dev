import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../../posts/data/public_post_repository.dart';
import '../../../posts/data/supabase_public_post_repository.dart';
import '../../../posts/domain/public_post.dart';
import '../../domain/user_profile.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  String _availabilityStatus = 'available';
  String? _loadedUid;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _yearLevelController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;
    final postsRepository = SupabasePublicPostRepository(
      client: Supabase.instance.client,
    );

    if (profile != null && _loadedUid != profile.uid) {
      _syncControllers(profile);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Save profile',
            onPressed: controller.isSaving || controller.isLoading
                ? null
                : _saveProfile,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.errorMessage != null) ...[
                        AuthErrorBanner(
                          message: controller.errorMessage!,
                          onDismissed: controller.clearError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _ProfileHeader(profile: profile),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: _required('Full name'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: _required('Student ID'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _collegeController,
                        decoration: const InputDecoration(
                          labelText: 'College',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        validator: _required('College'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        validator: _required('Department'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearLevelController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Year level',
                          prefixIcon: Icon(Icons.stacked_line_chart_outlined),
                        ),
                        validator: _required('Year level'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: _required('Username'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Bio/About',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          labelText: 'Skills/categories',
                          hintText: 'Portraits, logos, character art',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _availabilityStatus,
                        decoration: const InputDecoration(
                          labelText: 'Availability status',
                          prefixIcon: Icon(Icons.event_available_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(value: 'busy', child: Text('Busy')),
                          DropdownMenuItem(
                            value: 'unavailable',
                            child: Text('Unavailable'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _availabilityStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: controller.isSaving ? null : _saveProfile,
                        icon: controller.isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save profile'),
                      ),
                      const SizedBox(height: 16),
                      const _PortfolioPlaceholder(),
                      if (profile != null) ...[
                        const SizedBox(height: 24),
                        _PersonalPostsSection(
                          profile: profile,
                          postsRepository: postsRepository,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _syncControllers(UserProfile profile) {
    _loadedUid = profile.uid;
    _fullNameController.text = profile.fullName;
    _studentIdController.text = profile.studentId;
    _collegeController.text = profile.college;
    _departmentController.text = profile.department;
    _yearLevelController.text = profile.yearLevel;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio;
    _skillsController.text = profile.skills.join(', ');
    _availabilityStatus = profile.availabilityStatus;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<ProfileController>();
    final profile = controller.profile;
    if (profile == null) {
      return;
    }

    final saved = await controller.saveProfile(
      UserProfile(
        uid: profile.uid,
        profilePictureUrl: profile.profilePictureUrl,
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        college: _collegeController.text.trim(),
        department: _departmentController.text.trim(),
        yearLevel: _yearLevelController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skillsController.text
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList(),
        portfolioGallery: profile.portfolioGallery,
        availabilityStatus: _availabilityStatus,
      ),
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    }
  }

  String? Function(String?) _required(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required.';
      }
      return null;
    };
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: profile?.profilePictureUrl.isNotEmpty == true
              ? NetworkImage(profile!.profilePictureUrl)
              : null,
          child: profile?.profilePictureUrl.isNotEmpty == true
              ? null
              : Icon(
                  Icons.person_outline,
                  color: colorScheme.onPrimaryContainer,
                  size: 40,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName
                    : 'Your profile',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                profile?.department.isNotEmpty == true
                    ? '${profile!.college} - ${profile!.department} - ${profile!.yearLevel}'
                    : 'Add your college, department, and year level',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.photo_library_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text('Portfolio gallery upload will be added next.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalPostsSection extends StatelessWidget {
  const _PersonalPostsSection({
    required this.profile,
    required this.postsRepository,
  });

  final UserProfile profile;
  final PublicPostDataSource postsRepository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostListSection(
          title: 'Shared posts',
          emptyMessage: 'Open all posts you shared.',
          stream: postsRepository.watchSharedPostsByUser(profile.uid),
          summaryOnly: true,
          onOpen: () => context.go('/users/${profile.uid}/shared-posts'),
        ),
        const SizedBox(height: 20),
        _PostListSection(
          title: 'My posts',
          emptyMessage: 'Posts you create will appear here.',
          stream: postsRepository.watchPostsByAuthor(profile.uid),
        ),
      ],
    );
  }
}

class _PostListSection extends StatelessWidget {
  const _PostListSection({
    required this.title,
    required this.emptyMessage,
    required this.stream,
    this.summaryOnly = false,
    this.onOpen,
  });

  final String title;
  final String emptyMessage;
  final Stream<List<PublicPost>> stream;
  final bool summaryOnly;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PublicPost>>(
      stream: stream,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <PublicPost>[];
        final countLabel = snapshot.connectionState == ConnectionState.waiting
            ? 'Loading...'
            : posts.length == 1
            ? '1 post'
            : '${posts.length} posts';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (summaryOnly)
              _OpenSharedPostsTile(
                countLabel: countLabel,
                emptyMessage: emptyMessage,
                onOpen: onOpen,
              )
            else if (posts.isEmpty)
              _EmptyProfilePosts(message: emptyMessage)
            else
              ...posts.map((post) => _ProfilePostTile(post: post)),
          ],
        );
      },
    );
  }
}

class _OpenSharedPostsTile extends StatelessWidget {
  const _OpenSharedPostsTile({
    required this.countLabel,
    required this.emptyMessage,
    required this.onOpen,
  });

  final String countLabel;
  final String emptyMessage;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.share_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(emptyMessage),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({required this.post});

  final PublicPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
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
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.type,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  post.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(icon: Icons.favorite, value: post.heartCount),
                    const SizedBox(width: 12),
                    _MiniStat(
                      icon: Icons.remove_red_eye_outlined,
                      value: post.viewCount,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyProfilePosts extends StatelessWidget {
  const _EmptyProfilePosts({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

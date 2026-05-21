import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../posts/data/public_post_repository.dart';
import '../../../posts/domain/public_post.dart';
import '../../data/follow_store.dart';
import '../../data/profile_models.dart';
import '../../domain/user_profile.dart';
import '../controllers/profile_controller.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({
    super.key,
    required this.postsRepository,
    required this.chatRepository,
    required this.currentUser,
  });

  final PublicPostDataSource postsRepository;
  final ChatDataSource chatRepository;
  final AuthUser currentUser;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;
    if (profile != null) {
      FollowStore.loadForUser(currentUser.id);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Profile'),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                    _PublicProfileHeader(
                      profile: profile,
                      currentUser: currentUser,
                      chatRepository: chatRepository,
                    ),
                    const SizedBox(height: 16),
                    _ProfileInfo(profile: profile),
                    if (profile != null) ...[
                      const SizedBox(height: 20),
                      _PublicProfilePostsSection(
                        profile: profile,
                        currentUserId: currentUser.id,
                      ),
                      const SizedBox(height: 20),
                      _PublicPortfolioSection(profile: profile),
                      const SizedBox(height: 20),
                      _SharedPostsLink(
                        profile: profile,
                        postsRepository: postsRepository,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _OffersSection(
                      profile: profile,
                      currentUser: currentUser,
                      chatRepository: chatRepository,
                    ),
                    if (profile != null && profile.uid != currentUser.id) ...[
                      const SizedBox(height: 20),
                      _ReviewOtherUserCard(
                        profile: profile,
                        currentUser: currentUser,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ReviewOtherUserCard extends StatefulWidget {
  const _ReviewOtherUserCard({
    required this.profile,
    required this.currentUser,
  });

  final UserProfile profile;
  final AuthUser currentUser;

  @override
  State<_ReviewOtherUserCard> createState() => _ReviewOtherUserCardState();
}

class _ReviewOtherUserCardState extends State<_ReviewOtherUserCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Review this student',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Leave a review after a completed commission.',
              style: TextStyle(color: AppColors.regalNavy, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _showReviewDialog,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: const Text('Write a Review'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewDialog() async {
    final result =
        await showDialog<({String serviceTitle, String comment, int rating})>(
          context: context,
          builder: (context) => const _PublicReviewDialog(),
        );

    if (result == null ||
        result.serviceTitle.isEmpty ||
        result.comment.isEmpty ||
        !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profileId = await _profileIdForUid(widget.profile.uid);
      await Supabase.instance.client.from('profile_reviews').insert({
        'profile_id': profileId,
        'reviewer_id': widget.currentUser.id,
        'reviewer_name':
            widget.currentUser.displayName ??
            widget.currentUser.email ??
            'LNU student',
        'reviewer_initials': _initialsFor(
          widget.currentUser.displayName ?? widget.currentUser.email ?? '',
        ),
        'service_title': result.serviceTitle,
        'rating': result.rating,
        'comment': result.comment,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review submitted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit review. Check Supabase setup.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _initialsFor(String name) {
    final parts = name
        .split(RegExp(r'[\s@.]+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'LS';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _PublicReviewDialog extends StatefulWidget {
  const _PublicReviewDialog();

  @override
  State<_PublicReviewDialog> createState() => _PublicReviewDialogState();
}

class _PublicReviewDialogState extends State<_PublicReviewDialog> {
  final _serviceController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _serviceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Completed service',
                hintText: 'Logo design, portrait, poster layout',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                for (var index = 1; index <= 5; index++)
                  SizedBox.square(
                    dimension: 30,
                    child: IconButton(
                      tooltip: '$index star',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 30,
                        height: 30,
                      ),
                      iconSize: 18,
                      onPressed: () {
                        if (mounted) {
                          setState(() => _rating = index);
                        }
                      },
                      icon: Icon(
                        index <= _rating ? Icons.star : Icons.star_border,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Review',
                hintText: 'Tell other students about the work.',
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
          onPressed: () => Navigator.of(context).pop((
            serviceTitle: _serviceController.text.trim(),
            comment: _commentController.text.trim(),
            rating: _rating,
          )),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _SharedPostsLink extends StatelessWidget {
  const _SharedPostsLink({
    required this.profile,
    required this.postsRepository,
  });

  final UserProfile profile;
  final PublicPostDataSource postsRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PublicPost>>(
      stream: postsRepository.watchSharedPostsByUser(profile.uid),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <PublicPost>[];
        final label = snapshot.connectionState == ConnectionState.waiting
            ? 'Loading shared posts...'
            : posts.length == 1
            ? '1 shared post'
            : '${posts.length} shared posts';

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/users/${profile.uid}/shared-posts'),
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
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PublicProfileHeader extends StatelessWidget {
  const _PublicProfileHeader({
    required this.profile,
    required this.currentUser,
    required this.chatRepository,
  });

  final UserProfile? profile;
  final AuthUser currentUser;
  final ChatDataSource chatRepository;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : profile?.username.isNotEmpty == true
        ? profile!.username
        : 'LNU student';
    final detail = [
      profile?.college ?? '',
      profile?.department ?? '',
      if (profile?.yearLevel.isNotEmpty == true) 'Year ${profile!.yearLevel}',
    ].where((value) => value.isNotEmpty).join(' - ');
    final canChat = profile != null && profile!.uid != currentUser.id;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.schoolBusYellow,
              backgroundImage: profile?.profilePictureUrl.isNotEmpty == true
                  ? NetworkImage(profile!.profilePictureUrl)
                  : null,
              child: profile?.profilePictureUrl.isNotEmpty == true
                  ? null
                  : Text(
                      name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.isEmpty ? 'LNU student' : detail,
                    style: const TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _AvailabilityPill(
                        status: profile?.availabilityStatus ?? 'available',
                      ),
                      if (canChat)
                        _FollowButton(
                          currentUserId: currentUser.id,
                          targetUserId: profile!.uid,
                        ),
                      if (canChat)
                        FilledButton.icon(
                          onPressed: () => _startChat(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.regalNavy,
                            foregroundColor: AppColors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Chat'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final targetProfile = profile;
    if (targetProfile == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversationId = await chatRepository.startConversation(
        currentUser: currentUser,
        peer: ChatContact(
          id: targetProfile.uid,
          name: targetProfile.username.isNotEmpty
              ? targetProfile.username
              : targetProfile.fullName.isNotEmpty
              ? targetProfile.fullName
              : 'LNU student',
          detail: [
            targetProfile.college,
            targetProfile.department,
            if (targetProfile.yearLevel.isNotEmpty)
              'Year ${targetProfile.yearLevel}',
          ].where((value) => value.isNotEmpty).join(' - '),
          avatarUrl: targetProfile.profilePictureUrl,
        ),
      );

      if (context.mounted) {
        context.go('/chat/$conversationId');
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to start chat right now.')),
        );
    }
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.currentUserId,
    required this.targetUserId,
  });

  final String currentUserId;
  final String targetUserId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FollowStore.version,
      builder: (context, value, child) {
        final following = FollowStore.isFollowing(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        );
        return OutlinedButton.icon(
          onPressed: () {
            FollowStore.toggleFollow(
              currentUserId: currentUserId,
              targetUserId: targetUserId,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            side: const BorderSide(color: Color(0x66FFFFFF)),
            visualDensity: VisualDensity.compact,
          ),
          icon: Icon(following ? Icons.check : Icons.person_add_alt, size: 16),
          label: Text(following ? 'Following' : 'Follow'),
        );
      },
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'busy' => 'Busy',
      'unavailable' => 'Unavailable',
      _ => 'Available',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.schoolBusYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.inkBlack,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final bio = profile?.bio.trim() ?? '';
    final skills = profile?.skills ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'About',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          bio.isEmpty ? 'No bio added yet.' : bio,
          style: const TextStyle(color: AppColors.inkBlack),
        ),
        const SizedBox(height: 16),
        const Text(
          'Skills',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (skills.isEmpty)
          const Text('No skills listed yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (skill) => Chip(
                    label: Text(skill),
                    backgroundColor: const Color(0xFFFFFFFF),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _PublicProfilePostsSection extends StatelessWidget {
  const _PublicProfilePostsSection({
    required this.profile,
    required this.currentUserId,
  });

  final UserProfile profile;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _profileIdForUid(profile.uid),
      builder: (context, idSnapshot) {
        final profileId = idSnapshot.data ?? profile.uid;

        return ValueListenableBuilder<int>(
          valueListenable: FollowStore.version,
          builder: (context, value, child) {
            final canSeeConnections =
                currentUserId == profile.uid ||
                FollowStore.isFollowing(
                  currentUserId: currentUserId,
                  targetUserId: profile.uid,
                );

            return StreamBuilder<List<ProfilePost>>(
              stream: Supabase.instance.client
                  .from('profile_posts')
                  .stream(primaryKey: ['id'])
                  .eq('profile_id', profileId)
                  .order('created_at', ascending: false)
                  .map(
                    (rows) => rows
                        .map(ProfilePost.fromMap)
                        .where(
                          (post) =>
                              post.visibility == VisibilityType.lnuPublic ||
                              (post.visibility == VisibilityType.connections &&
                                  canSeeConnections),
                        )
                        .toList(growable: false),
                  ),
              builder: (context, snapshot) {
                final posts = snapshot.data ?? const <ProfilePost>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (posts.isEmpty)
                      const _EmptyPanel(
                        message: 'No public posts from this user yet.',
                      )
                    else
                      ...posts.map((post) => _PublicPostTile(post: post)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PublicPostTile extends StatelessWidget {
  const _PublicPostTile({required this.post});

  final ProfilePost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                post.visibility == VisibilityType.connections
                    ? Icons.group_outlined
                    : Icons.public,
                size: 16,
                color: AppColors.regalNavy,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.visibility.label,
                  style: const TextStyle(
                    color: AppColors.regalNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _shortDate(post.createdAt),
                style: const TextStyle(
                  color: AppColors.regalNavy,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content),
          if (post.attachment != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openUrl(context, post.attachment!.url),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.attachment!.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicPortfolioSection extends StatelessWidget {
  const _PublicPortfolioSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PublicPortfolioData>(
      future: _loadPublicPortfolio(profile.uid),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _PublicPortfolioData.empty();
        final hasContent =
            data.cvUrl.isNotEmpty ||
            data.links.isNotEmpty ||
            data.items.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CV / Portfolio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (!hasContent)
              const _EmptyPanel(message: 'No public portfolio added yet.')
            else ...[
              if (data.cvUrl.isNotEmpty)
                _PortfolioActionTile(
                  icon: Icons.description_outlined,
                  title: 'View CV',
                  subtitle: 'Open this student\'s uploaded CV.',
                  onTap: () => _openUrl(context, data.cvUrl),
                ),
              if (data.links.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.links
                      .map(
                        (link) => ActionChip(
                          avatar: const Icon(Icons.link, size: 16),
                          label: Text(
                            _shortLinkLabel(link),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _openUrl(context, link),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              ...data.items.map((item) => _PortfolioItemTile(item: item)),
            ],
          ],
        );
      },
    );
  }
}

class _PortfolioActionTile extends StatelessWidget {
  const _PortfolioActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        leading: Icon(icon, color: AppColors.regalNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new),
      ),
    );
  }
}

class _PortfolioItemTile extends StatelessWidget {
  const _PortfolioItemTile({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final link = item.externalUrl.isNotEmpty ? item.externalUrl : item.fileUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_outline, color: AppColors.regalNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (link.isNotEmpty)
            IconButton(
              tooltip: 'Open work',
              onPressed: () => _openUrl(context, link),
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
    );
  }
}

class _OffersSection extends StatelessWidget {
  const _OffersSection({
    required this.profile,
    required this.currentUser,
    required this.chatRepository,
  });

  final UserProfile? profile;
  final AuthUser currentUser;
  final ChatDataSource chatRepository;

  @override
  Widget build(BuildContext context) {
    final targetProfile = profile;
    if (targetProfile == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: _profileIdForUid(targetProfile.uid),
      builder: (context, idSnapshot) {
        final profileId = idSnapshot.data ?? targetProfile.uid;

        return StreamBuilder<List<ProfileService>>(
          stream: Supabase.instance.client
              .from('profile_services')
              .stream(primaryKey: ['id'])
              .eq('profile_id', profileId)
              .order('created_at', ascending: false)
              .map(
                (rows) =>
                    rows.map(ProfileService.fromMap).toList(growable: false),
              ),
          builder: (context, snapshot) {
            final offers = snapshot.data ?? const <ProfileService>[];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Offers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (offers.isEmpty)
                  const _EmptyOffers()
                else
                  ...offers.map(
                    (service) => _OfferTile(
                      service: service,
                      profile: targetProfile,
                      currentUser: currentUser,
                      chatRepository: chatRepository,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.service,
    required this.profile,
    required this.currentUser,
    required this.chatRepository,
  });

  final ProfileService service;
  final UserProfile profile;
  final AuthUser currentUser;
  final ChatDataSource chatRepository;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showOfferDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                color: AppColors.schoolBusYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      color: AppColors.regalNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MiniOfferChip(service.category),
                      _MiniOfferChip(service.priceRange),
                      _MiniOfferChip(service.deliveryTime),
                    ].where((chip) => chip.label.isNotEmpty).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.regalNavy),
          ],
        ),
      ),
    );
  }

  Future<void> _showOfferDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                service.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(service.description),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniOfferChip(service.category),
                  _MiniOfferChip(service.priceRange),
                  _MiniOfferChip(service.deliveryTime),
                  _MiniOfferChip(service.availability.label),
                ].where((chip) => chip.label.isNotEmpty).toList(),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: profile.uid == currentUser.id
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _requestCommission(context);
                      },
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Request commission'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: profile.uid == currentUser.id
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _startOfferChat(context);
                      },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message about this offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestCommission(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = <String, dynamic>{
        'service_title': service.title,
        'client_id': currentUser.id,
        'client_name':
            currentUser.displayName ?? currentUser.email ?? 'LNU student',
        'provider_id': profile.uid,
        'provider_name': profile.fullName.isNotEmpty
            ? profile.fullName
            : profile.username.isNotEmpty
            ? profile.username
            : 'LNU student',
        'status': 'pending',
      };
      if (_isUuid(service.id)) {
        payload['service_id'] = service.id;
      }
      await Supabase.instance.client
          .from('commission_requests')
          .insert(payload);
      if (context.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Commission request sent.')),
          );
      }
    } catch (error) {
      final message = _friendlyCommissionRequestError(error);
      if (context.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _startOfferChat(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversationId = await chatRepository.startConversation(
        currentUser: currentUser,
        peer: ChatContact(
          id: profile.uid,
          name: profile.username.isNotEmpty
              ? profile.username
              : profile.fullName.isNotEmpty
              ? profile.fullName
              : 'LNU student',
          detail: service.title,
          avatarUrl: profile.profilePictureUrl,
        ),
      );

      if (context.mounted) {
        context.go('/chat/$conversationId');
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to start chat right now.')),
        );
    }
  }
}

class _MiniOfferChip extends StatelessWidget {
  const _MiniOfferChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      backgroundColor: const Color(0xFFFFFFFF),
      side: BorderSide.none,
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('This user has not posted any offers yet.'),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

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

class _PublicPortfolioData {
  const _PublicPortfolioData({
    required this.cvUrl,
    required this.links,
    required this.items,
  });

  final String cvUrl;
  final List<String> links;
  final List<PortfolioItem> items;

  factory _PublicPortfolioData.empty() {
    return const _PublicPortfolioData(
      cvUrl: '',
      links: <String>[],
      items: <PortfolioItem>[],
    );
  }
}

Future<String> _profileIdForUid(String uid) async {
  if (uid.isEmpty) {
    return uid;
  }

  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('id, uid')
        .eq('uid', uid)
        .maybeSingle();
    final id = row?['id'] ?? row?['uid'];
    final text = id?.toString().trim() ?? '';
    return text.isEmpty ? uid : text;
  } catch (_) {
    return uid;
  }
}

Future<_PublicPortfolioData> _loadPublicPortfolio(String uid) async {
  if (uid.isEmpty) {
    return _PublicPortfolioData.empty();
  }

  try {
    final profileRow = await Supabase.instance.client
        .from('profiles')
        .select('id, uid, cv_url, portfolio_links')
        .eq('uid', uid)
        .maybeSingle();
    Map<String, dynamic>? extrasRow;
    try {
      extrasRow = await Supabase.instance.client
          .from('profile_extras')
          .select('cv_url, portfolio_links')
          .eq('user_id', uid)
          .maybeSingle();
    } catch (_) {
      extrasRow = null;
    }
    final profileId = (profileRow?['id'] ?? profileRow?['uid'] ?? uid)
        .toString()
        .trim();
    final itemRows = await Supabase.instance.client
        .from('profile_portfolio_items')
        .select()
        .eq('profile_id', profileId.isEmpty ? uid : profileId)
        .order('created_at', ascending: false);

    return _PublicPortfolioData(
      cvUrl: (extrasRow?['cv_url'] ?? profileRow?['cv_url'] ?? '')
          .toString()
          .trim(),
      links: _stringList(
        extrasRow?['portfolio_links'] ?? profileRow?['portfolio_links'],
      ),
      items: itemRows.map(PortfolioItem.fromMap).toList(growable: false),
    );
  } catch (_) {
    return _PublicPortfolioData.empty();
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

Future<void> _openUrl(BuildContext context, String value) async {
  final text = value.trim();
  if (text.isEmpty) {
    return;
  }

  final uri = Uri.tryParse(
    text.startsWith(RegExp(r'https?://')) ? text : 'https://$text',
  );
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }
}

String _shortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}

String _shortLinkLabel(String value) {
  final uri = Uri.tryParse(value);
  final host = uri?.host ?? '';
  if (host.isNotEmpty) {
    return host.replaceFirst('www.', '');
  }
  return value.replaceFirst(RegExp(r'https?://'), '');
}

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

String _friendlyCommissionRequestError(Object error) {
  final text = error.toString();
  if (text.contains('commission_requests') ||
      text.contains('relation') ||
      text.contains('schema cache')) {
    return 'Commission requests table is missing. Run supabase_lnu_profile_notifications_setup.sql again.';
  }
  if (text.contains('row-level security') || text.contains('42501')) {
    return 'Supabase blocked this request with RLS. Run the latest setup SQL policies.';
  }
  if (text.contains('foreign key') || text.contains('23503')) {
    return 'This offer is not linked correctly in Supabase. Refresh and try again.';
  }
  return 'Unable to request commission: $text';
}

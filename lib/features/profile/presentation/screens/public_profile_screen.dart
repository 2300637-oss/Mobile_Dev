import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../posts/data/public_post_repository.dart';
import '../../../posts/domain/public_post.dart';
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
                      _SharedPostsLink(
                        profile: profile,
                        postsRepository: postsRepository,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _OffersSection(
                      authorId: profile?.uid ?? '',
                      postsRepository: postsRepository,
                    ),
                  ],
                ),
              ),
            ),
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
                    style: const TextStyle(color: Color(0xFFDDE7FF)),
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
                        FilledButton.icon(
                          onPressed: () => _startChat(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.royalAzure,
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
                    backgroundColor: const Color(0xFFE9EEF9),
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

class _OffersSection extends StatelessWidget {
  const _OffersSection({required this.authorId, required this.postsRepository});

  final String authorId;
  final PublicPostDataSource postsRepository;

  @override
  Widget build(BuildContext context) {
    if (authorId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<PublicPost>>(
      stream: postsRepository.watchPostsByAuthor(authorId),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <PublicPost>[];
        final offers = posts.where(_isOfferPost).toList(growable: false);

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
              ...offers.map((post) => _OfferTile(post: post)),
          ],
        );
      },
    );
  }

  bool _isOfferPost(PublicPost post) {
    final type = post.type.toLowerCase();
    return type.contains('commission') || type.contains('service');
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.post});

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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
              image: post.mediaUrls.isNotEmpty && !post.hasVideo
                  ? DecorationImage(
                      image: NetworkImage(post.mediaUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.mediaUrls.isEmpty || post.hasVideo
                ? const Icon(
                    Icons.design_services_outlined,
                    color: AppColors.schoolBusYellow,
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
                  style: const TextStyle(
                    color: AppColors.regalNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../posts/data/public_post_repository.dart';
import '../../../posts/domain/public_post.dart';

class SharedPostsScreen extends StatelessWidget {
  const SharedPostsScreen({
    super.key,
    required this.userId,
    required this.postsRepository,
  });

  final String userId;
  final PublicPostDataSource postsRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/users/$userId');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Shared posts'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<PublicPost>>(
          stream: postsRepository.watchSharedPostsByUser(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data ?? const <PublicPost>[];
            if (posts.isEmpty) {
              return const _EmptySharedPosts();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _SharedPostCard(post: posts[index]),
            );
          },
        ),
      ),
    );
  }
}

class _SharedPostCard extends StatelessWidget {
  const _SharedPostCard({required this.post});

  final PublicPost post;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    post.authorName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.schoolBusYellow,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        post.type,
                        style: const TextStyle(
                          color: AppColors.regalNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.mediaUrls.isNotEmpty && !post.hasVideo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _SharedPostMediaFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              post.caption,
              style: const TextStyle(
                color: AppColors.inkBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _PostMetric(icon: Icons.favorite, value: post.heartCount),
                const SizedBox(width: 16),
                _PostMetric(
                  icon: Icons.remove_red_eye_outlined,
                  value: post.viewCount,
                ),
                const SizedBox(width: 16),
                _PostMetric(icon: Icons.share_outlined, value: post.shareCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedPostMediaFallback extends StatelessWidget {
  const _SharedPostMediaFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.navy,
      child: Center(
        child: Icon(
          Icons.article_outlined,
          color: AppColors.schoolBusYellow,
          size: 36,
        ),
      ),
    );
  }
}

class _PostMetric extends StatelessWidget {
  const _PostMetric({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.regalNavy),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.regalNavy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptySharedPosts extends StatelessWidget {
  const _EmptySharedPosts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No shared posts yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

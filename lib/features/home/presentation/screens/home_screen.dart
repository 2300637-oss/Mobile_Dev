import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../posts/data/public_post_repository.dart';
import '../../../posts/data/supabase_public_post_repository.dart';
import '../../../posts/domain/public_post.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final repository = SupabasePublicPostRepository(
      client: Supabase.instance.client,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FeedHeader(
                email: user?.email,
                onLogout: authController.isBusy ? null : authController.signOut,
              ),
            ),
            const SliverToBoxAdapter(child: _FeedTabs()),
            StreamBuilder<List<PublicPost>>(
              stream: repository.watchPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final posts = snapshot.data ?? const <PublicPost>[];
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFeed(),
                  );
                }

                return SliverList.separated(
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => _PostCard(
                    post: posts[index],
                    currentUserId: user?.id,
                    repository: repository,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
      bottomNavigationBar: const _SkillHubBottomBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-post'),
        backgroundColor: AppColors.schoolBusYellow,
        foregroundColor: AppColors.inkBlack,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.email, required this.onLogout});

  final String? email;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _MiniLnuMark(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'LNU '),
                      TextSpan(
                        text: 'SKILLHUB',
                        style: TextStyle(color: AppColors.schoolBusYellow),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.white,
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                color: AppColors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            email ?? 'LNU student',
            style: const TextStyle(color: Color(0xFFDDE7FF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: const [
          _FeedChip(label: 'For You', selected: true),
          _FeedChip(label: 'Following'),
          _FeedChip(label: 'Art Showcase'),
          _FeedChip(label: 'Open Comms'),
        ],
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? AppColors.schoolBusYellow
            : const Color(0xFFE9EEF9),
        labelStyle: TextStyle(
          color: selected ? AppColors.inkBlack : AppColors.navy,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.repository,
  });

  final PublicPost post;
  final String? currentUserId;
  final PublicPostDataSource repository;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _markedViewed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markViewed());
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _markedViewed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _markViewed());
    }
  }

  Future<void> _markViewed() async {
    if (_markedViewed ||
        widget.currentUserId == null ||
        widget.currentUserId == widget.post.authorId) {
      return;
    }
    _markedViewed = true;
    try {
      await widget.repository.markViewed(
        postId: widget.post.id,
        userId: widget.currentUserId!,
      );
    } catch (_) {
      _markedViewed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthor(
            post: widget.post,
            onPressed: () => context.go('/users/${widget.post.authorId}'),
          ),
          if (widget.post.hasMedia)
            _MediaPostPreview(post: widget.post)
          else
            const _ArtworkPreview(
              colors: [AppColors.regalNavy, AppColors.navy, AppColors.gold],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.caption,
                  style: const TextStyle(
                    color: AppColors.inkBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.post.type,
                  style: const TextStyle(
                    color: AppColors.regalNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _PostStats(
            post: widget.post,
            currentUserId: widget.currentUserId,
            repository: widget.repository,
          ),
        ],
      ),
    );
  }
}

class _PostAuthor extends StatelessWidget {
  const _PostAuthor({required this.post, required this.onPressed});

  final PublicPost post;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Row(
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkBlack,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    post.authorDepartment.isEmpty
                        ? post.authorEmail
                        : post.authorDepartment,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              _relativeTime(post.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            IconButton(
              tooltip: 'More',
              onPressed: () {},
              icon: const Icon(Icons.more_horiz, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'now';
    }
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}

class _MediaPostPreview extends StatelessWidget {
  const _MediaPostPreview({required this.post});

  final PublicPost post;

  @override
  Widget build(BuildContext context) {
    if (post.hasVideo) {
      return AspectRatio(
        aspectRatio: 1.55,
        child: Container(
          color: AppColors.navy,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: AppColors.schoolBusYellow,
              size: 64,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.55,
      child: Image.network(
        post.mediaUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _ArtworkPreview(
          colors: [AppColors.regalNavy, AppColors.navy, AppColors.gold],
        ),
      ),
    );
  }
}

class _ArtworkPreview extends StatelessWidget {
  const _ArtworkPreview({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: CustomPaint(
        painter: _ArtworkPainter(colors),
        child: Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0x66000011),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.schoolBusYellow, width: 2),
            ),
            child: const Icon(
              Icons.brush_outlined,
              color: AppColors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final sunPaint = Paint()..color = AppColors.schoolBusYellow.withAlpha(210);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .18),
      size.width * .08,
      sunPaint,
    );

    final cloudPaint = Paint()..color = const Color(0x99FFFFFF);
    for (final offset in [0.18, 0.34, 0.62]) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * offset,
          size.height * .18,
          size.width * .28,
          size.height * .08,
        ),
        cloudPaint,
      );
    }

    final mountainPaint = Paint()..color = const Color(0xCC000011);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * .25, size.height * .55)
      ..lineTo(size.width * .42, size.height * .77)
      ..lineTo(size.width * .62, size.height * .48)
      ..lineTo(size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, mountainPaint);

    final foregroundPaint = Paint()..color = const Color(0xE6000011);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .82, size.width, size.height * .18),
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _PostStats extends StatefulWidget {
  const _PostStats({
    required this.post,
    required this.currentUserId,
    required this.repository,
  });

  final PublicPost post;
  final String? currentUserId;
  final PublicPostDataSource repository;

  @override
  State<_PostStats> createState() => _PostStatsState();
}

class _PostStatsState extends State<_PostStats> {
  bool _isHeartBusy = false;
  bool _isViewBusy = false;
  bool _isShareBusy = false;
  int _heartDelta = 0;
  int _viewDelta = 0;
  int _shareDelta = 0;

  int get _heartCount =>
      (widget.post.heartCount + _heartDelta).clamp(0, 1 << 31);
  int get _viewCount => (widget.post.viewCount + _viewDelta).clamp(0, 1 << 31);
  int get _shareCount =>
      (widget.post.shareCount + _shareDelta).clamp(0, 1 << 31);

  @override
  void didUpdateWidget(covariant _PostStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.heartCount != widget.post.heartCount) {
      _heartDelta = 0;
    }
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.viewCount != widget.post.viewCount) {
      _viewDelta = 0;
    }
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.shareCount != widget.post.shareCount) {
      _shareDelta = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor =
        widget.currentUserId != null &&
        widget.currentUserId == widget.post.authorId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          if (widget.currentUserId == null)
            _StatIcon(
              icon: Icons.favorite_border,
              label: '$_heartCount',
              color: AppColors.cinnabar,
            )
          else
            StreamBuilder<bool>(
              stream: widget.repository.watchHearted(
                postId: widget.post.id,
                userId: widget.currentUserId!,
              ),
              builder: (context, snapshot) {
                final hearted = snapshot.data ?? false;
                return _StatIconButton(
                  icon: hearted ? Icons.favorite : Icons.favorite_border,
                  label: '$_heartCount',
                  color: AppColors.cinnabar,
                  isBusy: _isHeartBusy,
                  tooltip: hearted ? 'Remove heart' : 'Heart post',
                  onPressed: () => _toggleHeart(hearted),
                );
              },
            ),
          const SizedBox(width: 18),
          _StatIconButton(
            icon: Icons.remove_red_eye_outlined,
            label: _formatCount(_viewCount),
            color: AppColors.inkBlack,
            isBusy: _isViewBusy,
            tooltip: isAuthor ? 'View seen by' : 'Mark as viewed',
            onPressed: widget.currentUserId == null
                ? null
                : isAuthor
                ? _showViewers
                : _markViewedFromButton,
          ),
          const Spacer(),
          _StatIconButton(
            icon: Icons.share_outlined,
            label: '$_shareCount',
            color: AppColors.inkBlack,
            isBusy: _isShareBusy,
            tooltip: 'Share post',
            onPressed: widget.currentUserId == null ? null : _sharePost,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHeart(bool currentlyHearted) async {
    if (_isHeartBusy || widget.currentUserId == null) {
      return;
    }
    setState(() => _isHeartBusy = true);
    try {
      await widget.repository.toggleHeart(
        postId: widget.post.id,
        userId: widget.currentUserId!,
      );
      if (mounted) {
        setState(() => _heartDelta += currentlyHearted ? -1 : 1);
      }
    } catch (_) {
      _showMessage('Could not update heart. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isHeartBusy = false);
      }
    }
  }

  Future<void> _markViewedFromButton() async {
    if (_isViewBusy || widget.currentUserId == null) {
      return;
    }
    setState(() => _isViewBusy = true);
    try {
      await widget.repository.markViewed(
        postId: widget.post.id,
        userId: widget.currentUserId!,
      );
      if (mounted && _viewDelta == 0) {
        setState(() => _viewDelta = 1);
      }
      _showMessage('Marked as viewed.');
    } catch (_) {
      _showMessage('Could not mark this post as viewed.');
    } finally {
      if (mounted) {
        setState(() => _isViewBusy = false);
      }
    }
  }

  Future<void> _sharePost() async {
    if (_isShareBusy || widget.currentUserId == null) {
      return;
    }
    setState(() => _isShareBusy = true);
    try {
      await widget.repository.markShared(
        postId: widget.post.id,
        userId: widget.currentUserId!,
      );
      if (mounted) {
        setState(() => _shareDelta += 1);
      }
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${widget.post.authorName} on LNU SkillHub: ${widget.post.caption}',
        ),
      );
    } catch (_) {
      _showMessage('Could not share this post. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isShareBusy = false);
      }
    }
  }

  void _showViewers() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _PostViewersSheet(post: widget.post, repository: widget.repository),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCount(int value) {
    return value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
  }
}

class _StatIconButton extends StatelessWidget {
  const _StatIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.tooltip,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isBusy ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isBusy ? .55 : 1,
            child: _StatIcon(icon: icon, label: label, color: color),
          ),
        ),
      ),
    );
  }
}

class _PostViewersSheet extends StatelessWidget {
  const _PostViewersSheet({required this.post, required this.repository});

  final PublicPost post;
  final PublicPostDataSource repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seen by',
              style: TextStyle(
                color: AppColors.inkBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: StreamBuilder<List<PostViewer>>(
                stream: repository.watchViewers(postId: post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final viewers = snapshot.data ?? const <PostViewer>[];
                  if (viewers.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Center(
                        child: Text('No one has viewed this post yet.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: viewers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final viewer = viewers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.navy,
                          child: Text(
                            viewer.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.schoolBusYellow,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          viewer.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          viewer.detail.isEmpty ? 'LNU student' : viewer.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _shortViewedTime(viewer.viewedAt),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortViewedTime(DateTime? viewedAt) {
    if (viewedAt == null) {
      return '';
    }
    final diff = DateTime.now().difference(viewedAt);
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No public posts yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create the first artwork, commission, service, progress, or announcement post.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatIcon extends StatelessWidget {
  const _StatIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkBlack,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SkillHubBottomBar extends StatelessWidget {
  const _SkillHubBottomBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.navy,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 66,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home,
              label: 'Home',
              active: true,
              onPressed: () {},
            ),
            _BottomItem(
              icon: Icons.search,
              label: 'Search',
              onPressed: () => context.go('/services'),
            ),
            const SizedBox(width: 48),
            _BottomItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onPressed: () => context.go('/chat'),
            ),
            _BottomItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.schoolBusYellow : AppColors.white;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLnuMark extends StatelessWidget {
  const _MiniLnuMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.inkBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.schoolBusYellow),
      ),
      child: const Icon(
        Icons.school_outlined,
        color: AppColors.schoolBusYellow,
        size: 20,
      ),
    );
  }
}

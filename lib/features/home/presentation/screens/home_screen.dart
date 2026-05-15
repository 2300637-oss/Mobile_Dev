import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _posts = [
    _FeedPost(
      author: 'ari.arts',
      department: 'College of Arts and Sciences',
      caption: 'Sunset vibes. Digital painting I did yesterday.',
      tags: '#digitalart #artwork #lnuart',
      hearts: 128,
      views: 1200,
      shares: 56,
      minutesAgo: 3,
      palette: [Color(0xFF182958), Color(0xFFFF8F3D), Color(0xFF5C223A)],
    ),
    _FeedPost(
      author: 'pixel.migs',
      department: 'College of Computer Studies',
      caption: 'Commission samples for UI character icons.',
      tags: '#commissionopen #characterart',
      hearts: 84,
      views: 640,
      shares: 22,
      minutesAgo: 48,
      palette: [Color(0xFF001D3D), Color(0xFF2A57DF), Color(0xFFFFC20A)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

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
            SliverList.separated(
              itemCount: _posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _PostCard(post: _posts[index]),
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
        color: AppColors.midnightBlue,
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
          color: selected ? AppColors.inkBlack : AppColors.midnightBlue,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final _FeedPost post;

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
          _PostAuthor(post: post),
          _ArtworkPreview(colors: post.palette),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption,
                  style: const TextStyle(
                    color: AppColors.inkBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  post.tags,
                  style: const TextStyle(
                    color: AppColors.royalAzure,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _PostStats(post: post),
        ],
      ),
    );
  }
}

class _PostAuthor extends StatelessWidget {
  const _PostAuthor({required this.post});

  final _FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.midnightBlue,
            child: Text(
              post.author.characters.first.toUpperCase(),
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
                  post.author,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  post.department,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            '${post.minutesAgo}m',
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, size: 20),
          ),
        ],
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

class _PostStats extends StatelessWidget {
  const _PostStats({required this.post});

  final _FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          _StatIcon(
            icon: Icons.favorite,
            label: '${post.hearts}',
            color: AppColors.mahoganyRed,
          ),
          const SizedBox(width: 18),
          _StatIcon(
            icon: Icons.remove_red_eye_outlined,
            label: post.views >= 1000
                ? '${(post.views / 1000).toStringAsFixed(1)}k'
                : '${post.views}',
            color: AppColors.inkBlack,
          ),
          const Spacer(),
          _StatIcon(
            icon: Icons.share_outlined,
            label: '${post.shares}',
            color: AppColors.inkBlack,
          ),
        ],
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
      color: AppColors.midnightBlue,
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

class _FeedPost {
  const _FeedPost({
    required this.author,
    required this.department,
    required this.caption,
    required this.tags,
    required this.hearts,
    required this.views,
    required this.shares,
    required this.minutesAgo,
    required this.palette,
  });

  final String author;
  final String department;
  final String caption;
  final String tags;
  final int hearts;
  final int views;
  final int shares;
  final int minutesAgo;
  final List<Color> palette;
}

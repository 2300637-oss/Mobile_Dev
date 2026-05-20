import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
  });

  final StudentProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopHeader(profile: profile),
        _CoverSection(onCamera: onEditProfile),
        _ProfileCard(
          profile: profile,
          onEditProfile: onEditProfile,
          onMessage: onMessage,
          onShare: onShare,
        ),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: SkillHubProfileColors.navy,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000088),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final title = Row(
            children: [
              const _LogoMark(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'LNU SKILLHUB',
                  style: TextStyle(
                    color: SkillHubProfileColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                color: SkillHubProfileColors.white,
                icon: const Icon(Icons.notifications_outlined),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: SkillHubProfileColors.yellow,
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: SkillHubProfileColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );

          final search = const _SearchBox();
          if (compact) {
            return Column(
              children: [title, const SizedBox(height: 12), search],
            );
          }

          return Row(
            children: [
              SizedBox(width: 230, child: title),
              const SizedBox(width: 18),
              Expanded(child: search),
            ],
          );
        },
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SkillHubProfileColors.yellow,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: const Text(
        'SH',
        style: TextStyle(
          color: SkillHubProfileColors.navy,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        readOnly: true,
        style: const TextStyle(color: SkillHubProfileColors.white),
        decoration: InputDecoration(
          hintText: 'Search verified students, services, posts...',
          hintStyle: TextStyle(
            color: SkillHubProfileColors.white.withValues(alpha: .58),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: SkillHubProfileColors.white.withValues(alpha: .58),
            size: 19,
          ),
          filled: true,
          fillColor: SkillHubProfileColors.white.withValues(alpha: .13),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: SkillHubProfileColors.white.withValues(alpha: .22),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: SkillHubProfileColors.white.withValues(alpha: .35),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.onCamera});

  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SkillHubProfileColors.inkBlack,
            SkillHubProfileColors.navy,
            SkillHubProfileColors.blueAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CoverPatternPainter())),
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: SkillHubProfileColors.yellow.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: OutlinedButton.icon(
              onPressed: onCamera,
              style: OutlinedButton.styleFrom(
                foregroundColor: SkillHubProfileColors.white,
                backgroundColor: const Color(0x66000000),
                side: BorderSide(
                  color: SkillHubProfileColors.white.withValues(alpha: .26),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Edit Cover'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPatternPainter extends CustomPainter {
  const _CoverPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SkillHubProfileColors.white.withValues(alpha: .08);
    for (double x = 0; x < size.width; x += 26) {
      for (double y = 0; y < size.height; y += 26) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
  });

  final StudentProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final avatar = _ProfileAvatar(
                  profile: profile,
                  onEditProfile: onEditProfile,
                );
                final info = _ProfileInfo(profile: profile);
                final actions = _ProfileActions(
                  onEditProfile: onEditProfile,
                  onMessage: onMessage,
                  onShare: onShare,
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(width: 14),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: 14),
                      actions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 18),
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _StatsRow(profile: profile),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.onEditProfile});

  final StudentProfile profile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -42),
      child: SizedBox(
        width: 96,
        height: 106,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: SkillHubProfileColors.white,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: SkillHubProfileColors.yellow,
                backgroundImage: profile.avatarUrl.isNotEmpty
                    ? NetworkImage(profile.avatarUrl)
                    : null,
                child: profile.avatarUrl.isNotEmpty
                    ? null
                    : Text(
                        profile.initials,
                        style: const TextStyle(
                          color: SkillHubProfileColors.navy,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 18,
              child: IconButton.filled(
                onPressed: onEditProfile,
                style: IconButton.styleFrom(
                  backgroundColor: SkillHubProfileColors.navy,
                  foregroundColor: SkillHubProfileColors.white,
                  minimumSize: const Size.square(28),
                  fixedSize: const Size.square(28),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.edit, size: 14),
                tooltip: 'Edit photo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                profile.fullName,
                style: const TextStyle(
                  color: SkillHubProfileColors.midBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (profile.verified)
                const _Badge(
                  icon: Icons.verified,
                  text: 'Verified LNU Student',
                  color: SkillHubProfileColors.navy,
                  background: Color(0xFFEEF2FF),
                ),
              _Badge(
                icon: profile.availability.canRequest
                    ? Icons.bolt
                    : Icons.lock_outline,
                text: profile.availability.label,
                color: profile.availability.canRequest
                    ? const Color(0xFF047857)
                    : SkillHubProfileColors.red,
                background: profile.availability.canRequest
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF1F2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.username,
            style: const TextStyle(
              color: SkillHubProfileColors.textSub,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaItem(icon: Icons.school_outlined, label: profile.college),
              _MetaItem(
                icon: Icons.account_balance_outlined,
                label: profile.department,
              ),
              _MetaItem(
                icon: Icons.workspace_premium_outlined,
                label: profile.yearLevel,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            profile.bio,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.skills.map((skill) => _SkillChip(skill)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          FilledButton.icon(
            key: const Key('edit-profile-button'),
            onPressed: onEditProfile,
            style: FilledButton.styleFrom(
              backgroundColor: SkillHubProfileColors.navy,
              foregroundColor: SkillHubProfileColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
          ),
          OutlinedButton.icon(
            onPressed: onMessage,
            style: OutlinedButton.styleFrom(
              foregroundColor: SkillHubProfileColors.textMain,
              side: const BorderSide(color: SkillHubProfileColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Message'),
          ),
          IconButton.outlined(
            tooltip: 'Share profile',
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _StatItem(value: '${profile.stats.posts}', label: 'Posts'),
          _StatItem(value: '${profile.stats.completed}', label: 'Completed'),
          _StatItem(value: '${profile.stats.reviews}', label: 'Reviews'),
          _StatItem(
            value: profile.stats.rating.toStringAsFixed(1),
            label: 'Average Rating',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: SkillHubProfileColors.midBlue,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: SkillHubProfileColors.textSub),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: SkillHubProfileColors.textSub,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(
        color: SkillHubProfileColors.blueAccent,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFFF0F4FF),
      side: const BorderSide(color: Color(0xFFC7D2FE)),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

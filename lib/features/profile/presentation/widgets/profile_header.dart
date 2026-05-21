import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/follow_store.dart';
import '../../data/profile_models.dart';
import 'profile_style.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onEditProfile,
    required this.onEditAvatar,
    required this.onEditCover,
    required this.onNotifications,
    required this.onMenu,
    required this.onMessage,
    required this.onShare,
  });

  final StudentProfile profile;
  final VoidCallback onBack;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditCover;
  final VoidCallback onNotifications;
  final VoidCallback onMenu;
  final VoidCallback onMessage;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SkillHubProfileColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CoverPatternPainter())),
          if (profile.coverUrl.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(image: _coverImage(profile.coverUrl)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      color: SkillHubProfileColors.white,
                      icon: const Icon(Icons.arrow_back, size: 18),
                    ),
                    const Expanded(
                      child: Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: SkillHubProfileColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      onPressed: onMenu,
                      color: SkillHubProfileColors.white,
                      icon: const Icon(Icons.more_horiz, size: 20),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactAvatar(
                        profile: profile,
                        onEditAvatar: onEditAvatar,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _CompactStats(profile: profile)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _CompactBio(profile: profile),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: const Key('edit-profile-button'),
                          onPressed: onEditProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: SkillHubProfileColors.blueAccent,
                            foregroundColor: SkillHubProfileColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: 'Edit cover',
                        onPressed: onEditCover,
                        color: SkillHubProfileColors.white,
                        style: IconButton.styleFrom(
                          side: BorderSide(
                            color: SkillHubProfileColors.white.withValues(
                              alpha: .35,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAvatar extends StatelessWidget {
  const _CompactAvatar({required this.profile, required this.onEditAvatar});

  final StudentProfile profile;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: SkillHubProfileColors.yellow,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: SkillHubProfileColors.navy,
            backgroundImage: _avatarImage(profile.avatarUrl),
            child: profile.avatarUrl.isEmpty
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      color: SkillHubProfileColors.yellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: InkWell(
            onTap: onEditAvatar,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: SkillHubProfileColors.yellow,
                shape: BoxShape.circle,
                border: Border.all(color: SkillHubProfileColors.navy, width: 2),
              ),
              child: const Icon(
                Icons.add,
                size: 14,
                color: SkillHubProfileColors.navy,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactStats extends StatelessWidget {
  const _CompactStats({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    FollowStore.loadForUser(profile.userId);
    return ValueListenableBuilder<int>(
      valueListenable: FollowStore.version,
      builder: (context, value, child) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CompactStat(value: '${profile.stats.posts}', label: 'Posts'),
            _CompactStat(
              value: '${FollowStore.followers(profile.userId)}',
              label: 'Followers',
            ),
            _CompactStat(
              value: '${FollowStore.following(profile.userId)}',
              label: 'Following',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: SkillHubProfileColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompactBio extends StatelessWidget {
  const _CompactBio({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SkillHubProfileColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '@${profile.username.replaceFirst('@', '')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
        ),
        const SizedBox(height: 7),
        Text(
          profile.bio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SkillHubProfileColors.white,
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: profile.availability.canRequest
                    ? const Color(0xFF00E200)
                    : SkillHubProfileColors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                profile.availability.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.profile,
    required this.onBack,
    required this.onNotifications,
    required this.onMenu,
  });

  final StudentProfile profile;
  final VoidCallback onBack;
  final VoidCallback onNotifications;
  final VoidCallback onMenu;

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
          final title = Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                color: SkillHubProfileColors.white,
                icon: const Icon(Icons.arrow_back),
              ),
              const _LogoMark(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'LNU Student Skills Commission',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SkillHubProfileColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                color: SkillHubProfileColors.white,
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                color: SkillHubProfileColors.white,
                icon: const Icon(Icons.menu),
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

          return title;
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

// ignore: unused_element
class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.profile, required this.onCamera});

  final StudentProfile profile;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        image: _coverImage(profile.coverUrl),
        gradient: const LinearGradient(
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

DecorationImage? _coverImage(String value) {
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('http')) {
    return DecorationImage(image: NetworkImage(value), fit: BoxFit.cover);
  }
  if (!kIsWeb) {
    return DecorationImage(image: FileImage(File(value)), fit: BoxFit.cover);
  }
  return null;
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

// ignore: unused_element
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEditProfile,
    required this.onEditAvatar,
    required this.onMessage,
    required this.onShare,
  });

  final StudentProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;
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
                  onEditProfile: onEditAvatar,
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
          const Divider(height: 1, color: Color(0xFFFFFFFF)),
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
                backgroundImage: _avatarImage(profile.avatarUrl),
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

ImageProvider? _avatarImage(String value) {
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('http')) {
    return NetworkImage(value);
  }
  if (!kIsWeb) {
    return FileImage(File(value));
  }
  return null;
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
                  background: Color(0xFFFFFFFF),
                ),
              _Badge(
                icon: profile.availability.canRequest
                    ? Icons.bolt
                    : Icons.lock_outline,
                text: profile.availability.label,
                color: profile.availability.canRequest
                    ? const Color(0xFF00E200)
                    : SkillHubProfileColors.red,
                background: profile.availability.canRequest
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFFFFFFF),
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
              color: Color(0xFF003566),
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
              color: Color(0xFF003566),
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
      backgroundColor: const Color(0xFFFFFFFF),
      side: const BorderSide(color: Color(0xFF003566)),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

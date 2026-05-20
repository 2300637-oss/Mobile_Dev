import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwner,
    required this.onHome,
    required this.onMyProfile,
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
    this.onLogout,
  });

  final StudentProfile profile;
  final bool isOwner;
  final VoidCallback onHome;
  final VoidCallback onMyProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopHeader(
          profile: profile,
          onHome: onHome,
          onMyProfile: onMyProfile,
          onLogout: onLogout,
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _CoverSection(showEdit: isOwner, onCamera: onEditProfile),
            Positioned(
              bottom: -54,
              child: _ProfileAvatar(
                profile: profile,
                showEdit: isOwner,
                onEditProfile: onEditProfile,
              ),
            ),
          ],
        ),
        _ProfileSummaryCard(
          profile: profile,
          isOwner: isOwner,
          onEditProfile: onEditProfile,
          onMessage: onMessage,
          onShare: onShare,
        ),
      ],
    );
  }
}

class _TopHeader extends StatefulWidget {
  const _TopHeader({
    required this.profile,
    required this.onHome,
    required this.onMyProfile,
    required this.onLogout,
  });

  final StudentProfile profile;
  final VoidCallback onHome;
  final VoidCallback onMyProfile;
  final VoidCallback? onLogout;

  @override
  State<_TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<_TopHeader> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
      child: _searchOpen ? _buildSearchRow() : _buildDefaultRow(),
    );
  }

  Widget _buildDefaultRow() {
    return Row(
      children: [
        InkWell(
          key: const Key('profile-logo-home'),
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onHome,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LogoMark(),
                SizedBox(width: 9),
                Text(
                  'LNU SKILLHUB',
                  style: TextStyle(
                    color: SkillHubProfileColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          key: const Key('profile-search-button'),
          tooltip: 'Search',
          onPressed: _openSearch,
          color: SkillHubProfileColors.white,
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          color: SkillHubProfileColors.white,
          icon: const Icon(Icons.notifications_outlined),
        ),
        PopupMenuButton<_ProfileMenuAction>(
          key: const Key('profile-menu-button'),
          tooltip: 'Profile menu',
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ProfileMenuAction.myProfile,
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('My Profile'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (widget.onLogout != null)
              const PopupMenuItem(
                value: _ProfileMenuAction.logout,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
          child: CircleAvatar(
            radius: 18,
            backgroundColor: SkillHubProfileColors.yellow,
            child: Text(
              widget.profile.initials,
              style: const TextStyle(
                color: SkillHubProfileColors.navy,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              key: const Key('profile-search-field'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: SkillHubProfileColors.white),
              decoration: InputDecoration(
                hintText: 'Search verified students, services, posts...',
                hintStyle: TextStyle(
                  color: SkillHubProfileColors.white.withValues(alpha: .65),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: SkillHubProfileColors.white.withValues(alpha: .7),
                  size: 20,
                ),
                filled: true,
                fillColor: SkillHubProfileColors.white.withValues(alpha: .14),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: SkillHubProfileColors.white.withValues(alpha: .25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: SkillHubProfileColors.white.withValues(alpha: .25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: SkillHubProfileColors.white.withValues(alpha: .45),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('profile-search-close'),
          tooltip: 'Close search',
          onPressed: _closeSearch,
          color: SkillHubProfileColors.white,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _searchOpen = false);
  }

  void _handleMenuAction(_ProfileMenuAction action) {
    switch (action) {
      case _ProfileMenuAction.myProfile:
        widget.onMyProfile();
      case _ProfileMenuAction.logout:
        widget.onLogout?.call();
    }
  }
}

enum _ProfileMenuAction { myProfile, logout }

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

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.showEdit, required this.onCamera});

  final bool showEdit;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
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
          if (showEdit)
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.showEdit,
    required this.onEditProfile,
  });

  final StudentProfile profile;
  final bool showEdit;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: SkillHubProfileColors.white,
            child: CircleAvatar(
              radius: 51,
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
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          if (showEdit)
            Positioned(
              right: 9,
              bottom: 9,
              child: IconButton.filled(
                onPressed: onEditProfile,
                style: IconButton.styleFrom(
                  backgroundColor: SkillHubProfileColors.navy,
                  foregroundColor: SkillHubProfileColors.white,
                  minimumSize: const Size.square(30),
                  fixedSize: const Size.square(30),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.edit, size: 15),
                tooltip: 'Edit photo',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profile,
    required this.isOwner,
    required this.onEditProfile,
    required this.onMessage,
    required this.onShare,
  });

  final StudentProfile profile;
  final bool isOwner;
  final VoidCallback onEditProfile;
  final VoidCallback onMessage;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 66, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SkillHubProfileColors.midBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SkillHubProfileColors.textSub,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
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
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: profile.skills.map((skill) => _SkillChip(skill)).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (isOwner)
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
                )
              else
                FilledButton.icon(
                  onPressed: onMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: SkillHubProfileColors.navy,
                    foregroundColor: SkillHubProfileColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                ),
              OutlinedButton.icon(
                onPressed: onShare,
                style: OutlinedButton.styleFrom(
                  foregroundColor: SkillHubProfileColors.textMain,
                  side: const BorderSide(color: SkillHubProfileColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _StatsRow(profile: profile),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          overflow: TextOverflow.ellipsis,
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
      constraints: const BoxConstraints(maxWidth: 220),
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

import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _AdminSection _activeSection = _AdminSection.overview;
  bool _sidebarCollapsed = false;
  bool _notificationsOpen = false;
  String _userFilter = 'all';
  String _userSearch = '';
  String _reportFilter = 'all';

  late List<_AdminUser> _users;
  late List<_VerificationRequest> _verifications;
  late List<_ReportItem> _reports;
  late List<_PostItem> _posts;
  late List<_CommissionItem> _commissions;

  @override
  void initState() {
    super.initState();
    _users = List<_AdminUser>.from(_mockUsers);
    _verifications = List<_VerificationRequest>.from(_mockVerifications);
    _reports = List<_ReportItem>.from(_mockReports);
    _posts = List<_PostItem>.from(_mockPosts);
    _commissions = List<_CommissionItem>.from(_mockCommissions);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final autoCompact = constraints.maxWidth < 760;
        final collapsed = autoCompact || _sidebarCollapsed;

        return Scaffold(
          backgroundColor: _AdminColors.grayBg,
          body: SafeArea(
            child: Row(
              children: [
                _AdminSidebar(
                  activeSection: _activeSection,
                  collapsed: collapsed,
                  canToggle: !autoCompact,
                  onToggle: () {
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                  },
                  onSectionSelected: (section) {
                    setState(() {
                      _activeSection = section;
                      _notificationsOpen = false;
                    });
                  },
                  pendingVerificationCount: _verifications.length,
                  pendingReportCount: _reports
                      .where((report) => report.status == 'pending')
                      .length,
                  flaggedPostCount: _posts.where((post) => post.flagged).length,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _AdminTopBar(
                            section: _activeSection,
                            notificationsOpen: _notificationsOpen,
                            onNotificationsPressed: () {
                              setState(
                                () => _notificationsOpen = !_notificationsOpen,
                              );
                            },
                          ),
                          Expanded(
                            child: _AdminContentShell(
                              child: _buildActiveSection(),
                            ),
                          ),
                        ],
                      ),
                      if (_notificationsOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() => _notificationsOpen = false);
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                      if (_notificationsOpen)
                        const Positioned(
                          top: 58,
                          right: 20,
                          child: _NotificationPanel(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSection() {
    return switch (_activeSection) {
      _AdminSection.overview => _OverviewSection(
        users: _users,
        verifications: _verifications,
        reports: _reports,
        posts: _posts,
        commissions: _commissions,
      ),
      _AdminSection.users => _UserManagementSection(
        users: _filteredUsers,
        selectedFilter: _userFilter,
        searchValue: _userSearch,
        totalUsers: _users.length,
        onFilterChanged: (value) => setState(() => _userFilter = value),
        onSearchChanged: (value) => setState(() => _userSearch = value),
        onStatusChanged: _updateUserStatus,
      ),
      _AdminSection.verifications => _VerificationQueueSection(
        verifications: _verifications,
        onResolve: (id) {
          setState(
            () => _verifications.removeWhere((request) => request.id == id),
          );
        },
      ),
      _AdminSection.reports => _ReportsModerationSection(
        reports: _filteredReports,
        selectedFilter: _reportFilter,
        totalReports: _reports.length,
        pendingReports: _reports
            .where((report) => report.status == 'pending')
            .length,
        onFilterChanged: (value) => setState(() => _reportFilter = value),
        onStatusChanged: _updateReportStatus,
        onUserStatusChanged: (username, status) {
          final user = _users
              .where((candidate) => candidate.username == username)
              .firstOrNull;
          if (user != null) {
            _updateUserStatus(user.id, status);
          }
        },
      ),
      _AdminSection.posts => _PostsReviewSection(
        posts: _posts,
        onApprove: (id) => setState(() {
          _posts = _posts
              .map(
                (post) => post.id == id
                    ? post.copyWith(status: 'approved', flagged: false)
                    : post,
              )
              .toList();
        }),
        onRemove: (id) =>
            setState(() => _posts.removeWhere((post) => post.id == id)),
      ),
      _AdminSection.commissions => _CommissionMonitoringSection(
        commissions: _commissions,
      ),
      _AdminSection.analytics => _AnalyticsSection(
        users: _users,
        reports: _reports,
        commissions: _commissions,
      ),
      _AdminSection.settings => const _SettingsSection(),
    };
  }

  List<_AdminUser> get _filteredUsers {
    final query = _userSearch.trim().toLowerCase();
    return _users.where((user) {
      final statusMatches = _userFilter == 'all' || user.status == _userFilter;
      final queryMatches =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.studentId.toLowerCase().contains(query);
      return statusMatches && queryMatches;
    }).toList();
  }

  List<_ReportItem> get _filteredReports {
    if (_reportFilter == 'all') {
      return _reports;
    }
    return _reports.where((report) => report.status == _reportFilter).toList();
  }

  void _updateUserStatus(String id, String status) {
    setState(() {
      _users = _users
          .map((user) => user.id == id ? user.copyWith(status: status) : user)
          .toList();
    });
  }

  void _updateReportStatus(String id, String status) {
    setState(() {
      _reports = _reports
          .map(
            (report) =>
                report.id == id ? report.copyWith(status: status) : report,
          )
          .toList();
    });
  }
}

enum _AdminSection {
  overview,
  users,
  verifications,
  reports,
  posts,
  commissions,
  analytics,
  settings,
}

extension _AdminSectionInfo on _AdminSection {
  String get label {
    return switch (this) {
      _AdminSection.overview => 'Overview',
      _AdminSection.users => 'User Management',
      _AdminSection.verifications => 'Verifications',
      _AdminSection.reports => 'Reports',
      _AdminSection.posts => 'Posts Review',
      _AdminSection.commissions => 'Commissions',
      _AdminSection.analytics => 'Analytics',
      _AdminSection.settings => 'Settings',
    };
  }

  String get title {
    return switch (this) {
      _AdminSection.overview => 'Dashboard overview',
      _AdminSection.users => 'User Management',
      _AdminSection.verifications => 'Student Verification Queue',
      _AdminSection.reports => 'Reports & Moderation',
      _AdminSection.posts => 'Posts Review',
      _AdminSection.commissions => 'Commission Monitoring',
      _AdminSection.analytics => 'Analytics',
      _AdminSection.settings => 'Settings',
    };
  }

  IconData get icon {
    return switch (this) {
      _AdminSection.overview => Icons.dashboard_outlined,
      _AdminSection.users => Icons.groups_outlined,
      _AdminSection.verifications => Icons.verified_user_outlined,
      _AdminSection.reports => Icons.flag_outlined,
      _AdminSection.posts => Icons.image_outlined,
      _AdminSection.commissions => Icons.work_outline,
      _AdminSection.analytics => Icons.bar_chart_outlined,
      _AdminSection.settings => Icons.settings_outlined,
    };
  }
}

class _AdminColors {
  const _AdminColors._();

  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF000088);
  static const midBlue = Color(0xFF000088);
  static const inkBlack = Color(0xFF000011);
  static const yellow = Color(0xFFFFC300);
  static const gold = Color(0xFFFFD60A);
  static const red = Color(0xFFFF3838);
  static const darkRed = Color(0xFFFF3838);
  static const regalNavy = Color(0xFF003566);
  static const blueAccent = Color(0xFF003566);
  static const green = Color(0xFF00E200);
  static const grayBg = Color(0xFFFFFFFF);
  static const border = Color(0xFF003566);
  static const textMain = Color(0xFF000011);
  static const textSub = Color(0xFF003566);
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.activeSection,
    required this.collapsed,
    required this.canToggle,
    required this.onToggle,
    required this.onSectionSelected,
    required this.pendingVerificationCount,
    required this.pendingReportCount,
    required this.flaggedPostCount,
  });

  final _AdminSection activeSection;
  final bool collapsed;
  final bool canToggle;
  final VoidCallback onToggle;
  final ValueChanged<_AdminSection> onSectionSelected;
  final int pendingVerificationCount;
  final int pendingReportCount;
  final int flaggedPostCount;

  @override
  Widget build(BuildContext context) {
    final sections = _AdminSection.values
        .where((section) => section != _AdminSection.settings)
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 68 : 236,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AdminColors.inkBlack,
            _AdminColors.regalNavy,
            _AdminColors.midBlue,
            _AdminColors.navy,
          ],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _SidebarBrand(collapsed: collapsed),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  children: [
                    _SidebarLabel(label: 'Main', collapsed: collapsed),
                    for (final section in sections)
                      _SidebarItem(
                        section: section,
                        active: activeSection == section,
                        collapsed: collapsed,
                        badge: _badgeFor(section),
                        onTap: () => onSectionSelected(section),
                      ),
                    const SizedBox(height: 10),
                    _SidebarLabel(label: 'System', collapsed: collapsed),
                    _SidebarItem(
                      section: _AdminSection.settings,
                      active: activeSection == _AdminSection.settings,
                      collapsed: collapsed,
                      onTap: () => onSectionSelected(_AdminSection.settings),
                    ),
                    const SizedBox(height: 6),
                    _SidebarAction(collapsed: collapsed),
                  ],
                ),
              ),
              _SidebarAdmin(collapsed: collapsed),
            ],
          ),
          if (canToggle)
            Positioned(
              right: -2,
              bottom: 82,
              child: _SidebarToggle(collapsed: collapsed, onPressed: onToggle),
            ),
        ],
      ),
    );
  }

  int? _badgeFor(_AdminSection section) {
    return switch (section) {
      _AdminSection.verifications => pendingVerificationCount,
      _AdminSection.reports => pendingReportCount,
      _AdminSection.posts => flaggedPostCount,
      _ => null,
    };
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _AdminColors.white.withAlpha(24)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _AdminColors.yellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _AdminColors.inkBlack,
              size: 22,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LNU SkillHub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AdminColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin Console',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({required this.label, required this.collapsed});

  final String label;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _AdminColors.white.withAlpha(82),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.active,
    required this.collapsed,
    required this.onTap,
    this.badge,
  });

  final _AdminSection section;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? _AdminColors.yellow
        : _AdminColors.white.withAlpha(178);

    return Tooltip(
      message: collapsed ? section.label : '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
          decoration: BoxDecoration(
            color: active
                ? _AdminColors.yellow.withAlpha(34)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(section.icon, size: 19, color: foreground),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  _MiniBadge(value: badge.toString()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
      alignment: collapsed ? Alignment.center : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const Icon(Icons.logout, color: Color(0xCCFF7777), size: 19),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xCCFF7777),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarAdmin extends StatelessWidget {
  const _SidebarAdmin({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _AdminColors.white.withAlpha(24)),
        ),
      ),
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const _Avatar(initials: 'AD', size: 34),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AdminColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Super Admin',
                    style: TextStyle(color: Color(0x88FFFFFF), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  const _SidebarToggle({required this.collapsed, required this.onPressed});

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: _AdminColors.navy,
        foregroundColor: _AdminColors.white,
        fixedSize: const Size(28, 28),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      icon: Icon(
        collapsed ? Icons.chevron_right : Icons.chevron_left,
        size: 18,
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.section,
    required this.notificationsOpen,
    required this.onNotificationsPressed,
  });

  final _AdminSection section;
  final bool notificationsOpen;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _AdminColors.white,
        border: Border(bottom: BorderSide(color: _AdminColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000088),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final tight = constraints.maxWidth < 500;

          return Row(
            children: [
              if (compact)
                Expanded(child: _TopBarTitle(title: section.title))
              else
                Flexible(child: _TopBarTitle(title: section.title)),
              if (!compact) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: const _SearchBox(
                        hint: 'Search users, reports, posts',
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              if (!tight) ...[
                _TopIconButton(
                  tooltip: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
              _TopIconButton(
                tooltip: 'Notifications',
                icon: notificationsOpen
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_outlined,
                showDot: true,
                onPressed: onNotificationsPressed,
              ),
              const SizedBox(width: 10),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _AdminColors.white,
                  border: Border.all(color: _AdminColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Avatar(initials: 'AD', size: 28),
                    if (!compact) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          color: _AdminColors.textMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: _AdminColors.textSub,
                        size: 16,
                      ),
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

class _TopBarTitle extends StatelessWidget {
  const _TopBarTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _AdminColors.navy,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    final notifications = [
      (
        color: _AdminColors.red,
        text: 'Miguel Tan has 3 open reports - action needed',
        time: '2 min ago',
      ),
      (
        color: _AdminColors.yellow,
        text: '5 new student verifications awaiting review',
        time: '14 min ago',
      ),
      (
        color: _AdminColors.blueAccent,
        text: 'Commission dispute filed: jose.fx vs ana.draws',
        time: '1 hr ago',
      ),
      (
        color: _AdminColors.green,
        text: 'Ana Reyes was successfully verified',
        time: '3 hr ago',
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: _AdminColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AdminColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000088),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _AdminColors.textMain,
                      ),
                    ),
                  ),
                  Text(
                    'Mark all read',
                    style: TextStyle(
                      color: _AdminColors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _AdminColors.border),
            for (final item in notifications)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.text,
                            style: const TextStyle(
                              color: _AdminColors.textMain,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.time,
                            style: const TextStyle(
                              color: _AdminColors.textSub,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminContentShell extends StatefulWidget {
  const _AdminContentShell({required this.child});

  final Widget child;

  @override
  State<_AdminContentShell> createState() => _AdminContentShellState();
}

class _AdminContentShellState extends State<_AdminContentShell> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: widget.child,
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.users,
    required this.verifications,
    required this.reports,
    required this.posts,
    required this.commissions,
  });

  final List<_AdminUser> users;
  final List<_VerificationRequest> verifications;
  final List<_ReportItem> reports;
  final List<_PostItem> posts;
  final List<_CommissionItem> commissions;

  @override
  Widget build(BuildContext context) {
    final openReports = reports.where((report) => report.status == 'pending');
    final blockedUsers = users.where(
      (user) => user.status == 'suspended' || user.status == 'banned',
    );
    final activeCommissions = commissions.where(
      (item) => item.status == 'accepted' || item.status == 'in_progress',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Dashboard overview',
          subtitle: 'Moderation snapshot for the LNU SkillHub prototype.',
        ),
        _ResponsiveGrid(
          minItemWidth: 190,
          children: [
            _MetricCard(
              label: 'Total Students',
              value: users.length.toString(),
              trend: '+12 this month',
              icon: Icons.groups_outlined,
              color: _AdminColors.navy,
            ),
            _MetricCard(
              label: 'Pending Verifications',
              value: verifications.length.toString(),
              trend: '+3 this week',
              icon: Icons.verified_user_outlined,
              color: _AdminColors.yellow,
            ),
            _MetricCard(
              label: 'Active Commissions',
              value: activeCommissions.length.toString(),
              trend: '+8 active',
              icon: Icons.work_outline,
              color: _AdminColors.blueAccent,
            ),
            _MetricCard(
              label: 'Open Reports',
              value: openReports.length.toString(),
              trend: '+2 urgent',
              icon: Icons.flag_outlined,
              color: _AdminColors.darkRed,
            ),
            _MetricCard(
              label: 'Suspended / Banned',
              value: blockedUsers.length.toString(),
              trend: 'Local mock state',
              icon: Icons.shield_outlined,
              color: _AdminColors.textSub,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            const chart = _Card(
              child: _ChartPanel(
                title: 'Student registrations',
                subtitle: 'Mock monthly growth',
                child: _LineChartMock(
                  values: [23, 41, 38, 67, 52],
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  color: _AdminColors.navy,
                ),
              ),
            );
            const breakdown = _Card(
              child: _StatusBreakdown(
                title: 'User status',
                entries: [
                  _BreakdownEntry('Active', 142, _AdminColors.green),
                  _BreakdownEntry('Unverified', 24, _AdminColors.blueAccent),
                  _BreakdownEntry('Suspended', 8, _AdminColors.yellow),
                  _BreakdownEntry('Banned', 3, _AdminColors.red),
                ],
              ),
            );

            if (stacked) {
              return const Column(
                children: [
                  SizedBox(width: double.infinity, child: chart),
                  SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: breakdown),
                ],
              );
            }

            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: chart),
                SizedBox(width: 12),
                Expanded(child: breakdown),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _ResponsiveGrid(
          minItemWidth: 330,
          children: [
            _PriorityCard(
              title: 'Verification queue',
              subtitle: '${verifications.length} students waiting',
              icon: Icons.assignment_ind_outlined,
              color: _AdminColors.yellow,
              children: verifications.take(3).map((item) {
                return _CompactListTile(
                  leading: _Avatar(initials: _initials(item.name), size: 34),
                  title: item.name,
                  subtitle: '${item.studentId} - ${item.college}',
                  trailing: const _StatusPill(
                    label: 'Pending',
                    color: _AdminColors.yellow,
                  ),
                );
              }).toList(),
            ),
            _PriorityCard(
              title: 'Moderation queue',
              subtitle: '${openReports.length} open reports',
              icon: Icons.report_problem_outlined,
              color: _AdminColors.red,
              children: openReports.take(3).map((item) {
                return _CompactListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: _severityColor(item.severity),
                    size: 22,
                  ),
                  title: item.reason,
                  subtitle: '${item.reportedName} reported by ${item.by}',
                  trailing: _SeverityPill(severity: item.severity),
                );
              }).toList(),
            ),
            _PriorityCard(
              title: 'Flagged posts',
              subtitle:
                  '${posts.where((post) => post.flagged).length} need review',
              icon: Icons.image_search_outlined,
              color: _AdminColors.blueAccent,
              children: posts.where((post) => post.flagged).take(3).map((item) {
                return _CompactListTile(
                  leading: const Icon(
                    Icons.image_outlined,
                    color: _AdminColors.blueAccent,
                  ),
                  title: item.title,
                  subtitle: item.author,
                  trailing: const _StatusPill(
                    label: 'Flagged',
                    color: _AdminColors.red,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  const _UserManagementSection({
    required this.users,
    required this.selectedFilter,
    required this.searchValue,
    required this.totalUsers,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final List<_AdminUser> users;
  final String selectedFilter;
  final String searchValue;
  final int totalUsers;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'User Management',
          subtitle: 'Review student accounts and moderation status.',
          trailing: Wrap(
            spacing: 8,
            children: const [
              _ActionButton(label: 'Export', icon: Icons.download_outlined),
              _ActionButton(label: 'Filter', icon: Icons.tune_outlined),
            ],
          ),
        ),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: _SearchBox(
                        hint: 'Search students',
                        initialValue: searchValue,
                        onChanged: onSearchChanged,
                      ),
                    ),
                    for (final filter in const [
                      'all',
                      'active',
                      'suspended',
                      'banned',
                    ])
                      _FilterChipButton(
                        label: _titleCase(filter),
                        selected: selectedFilter == filter,
                        onPressed: () => onFilterChanged(filter),
                      ),
                    Text(
                      'Showing ${users.length} of $totalUsers',
                      style: const TextStyle(
                        color: _AdminColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _AdminColors.border),
              _AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('LNU Email')),
                  DataColumn(label: Text('Student ID')),
                  DataColumn(label: Text('College')),
                  DataColumn(label: Text('Verified')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Avatar(initials: user.initials, size: 32),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    color: _AdminColors.textSub,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(user.email)),
                      DataCell(Text(user.studentId)),
                      DataCell(Text('${user.college} - ${user.department}')),
                      DataCell(
                        user.verified
                            ? const _StatusPill(
                                label: 'Verified',
                                color: _AdminColors.green,
                              )
                            : const _StatusPill(
                                label: 'Unverified',
                                color: _AdminColors.blueAccent,
                              ),
                      ),
                      DataCell(_StatusBadge(status: user.status)),
                      DataCell(
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            const _SmallActionButton(
                              label: 'View',
                              icon: Icons.visibility_outlined,
                            ),
                            if (user.status != 'banned')
                              _SmallActionButton(
                                label: 'Suspend',
                                icon: Icons.lock_outline,
                                color: _AdminColors.yellow,
                                onPressed: () =>
                                    onStatusChanged(user.id, 'suspended'),
                              ),
                            if (user.status != 'banned')
                              _SmallActionButton(
                                label: 'Ban',
                                icon: Icons.person_off_outlined,
                                color: _AdminColors.red,
                                onPressed: () =>
                                    onStatusChanged(user.id, 'banned'),
                              ),
                            if (user.status == 'suspended' ||
                                user.status == 'banned')
                              _SmallActionButton(
                                label: 'Restore',
                                icon: Icons.lock_open_outlined,
                                color: _AdminColors.green,
                                onPressed: () =>
                                    onStatusChanged(user.id, 'active'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationQueueSection extends StatelessWidget {
  const _VerificationQueueSection({
    required this.verifications,
    required this.onResolve,
  });

  final List<_VerificationRequest> verifications;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Student Verification Queue',
          subtitle: '${verifications.length} pending verification requests.',
          trailing: _StatusPill(
            label: '${verifications.length} awaiting',
            color: _AdminColors.yellow,
          ),
        ),
        if (verifications.isEmpty)
          const _EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All clear',
            message: 'No pending student verification requests.',
          )
        else
          _ResponsiveGrid(
            minItemWidth: 310,
            children: verifications.map((item) {
              return _VerificationCard(
                item: item,
                onApprove: () => onResolve(item.id),
                onReject: () => onResolve(item.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final _VerificationRequest item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initials: _initials(item.name), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _AdminColors.textMain,
                      ),
                    ),
                    Text(
                      item.email,
                      style: const TextStyle(
                        color: _AdminColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.tag_outlined,
            label: 'Student ID',
            value: item.studentId,
          ),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'College',
            value: '${item.college} - ${item.department}',
          ),
          _InfoRow(
            icon: Icons.description_outlined,
            label: 'ID Type',
            value: item.idType,
          ),
          _InfoRow(
            icon: Icons.photo_camera_outlined,
            label: 'Selfie Submitted',
            value: item.selfieSubmitted ? 'Yes' : 'No',
          ),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Submitted',
            value: item.submitted,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Approve',
                icon: Icons.check,
                color: _AdminColors.green,
                onPressed: onApprove,
              ),
              _ActionButton(
                label: 'Reject',
                icon: Icons.close,
                color: _AdminColors.red,
                onPressed: onReject,
              ),
              const _ActionButton(
                label: 'View',
                icon: Icons.visibility_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsModerationSection extends StatelessWidget {
  const _ReportsModerationSection({
    required this.reports,
    required this.selectedFilter,
    required this.totalReports,
    required this.pendingReports,
    required this.onFilterChanged,
    required this.onStatusChanged,
    required this.onUserStatusChanged,
  });

  final List<_ReportItem> reports;
  final String selectedFilter;
  final int totalReports;
  final int pendingReports;
  final ValueChanged<String> onFilterChanged;
  final void Function(String id, String status) onStatusChanged;
  final void Function(String username, String status) onUserStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Reports & Moderation',
          subtitle: 'Platform conduct issues reported by students.',
          trailing: _StatusPill(
            label: '$pendingReports pending action',
            color: _AdminColors.red,
          ),
        ),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in const [
                      'all',
                      'pending',
                      'under_review',
                      'resolved',
                      'dismissed',
                    ])
                      _FilterChipButton(
                        label: filter == 'under_review'
                            ? 'Under Review'
                            : _titleCase(filter),
                        selected: selectedFilter == filter,
                        onPressed: () => onFilterChanged(filter),
                      ),
                    Text(
                      '${reports.length} of $totalReports reports',
                      style: const TextStyle(
                        color: _AdminColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _AdminColors.border),
              _AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Reported User')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Reported By')),
                  DataColumn(label: Text('Details')),
                  DataColumn(label: Text('Severity')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: reports.map((report) {
                  return DataRow(
                    cells: [
                      DataCell(Text(report.reportedName)),
                      DataCell(_ReasonTag(label: report.reason)),
                      DataCell(Text('@${report.by}')),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            report.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(_SeverityPill(severity: report.severity)),
                      DataCell(_StatusBadge(status: report.status)),
                      DataCell(Text(report.date)),
                      DataCell(
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _SmallActionButton(
                              label: 'Review',
                              icon: Icons.visibility_outlined,
                              color: _AdminColors.blueAccent,
                              onPressed: () =>
                                  onStatusChanged(report.id, 'under_review'),
                            ),
                            _SmallActionButton(
                              label: 'Suspend',
                              icon: Icons.lock_outline,
                              color: _AdminColors.yellow,
                              onPressed: () => onUserStatusChanged(
                                report.reported,
                                'suspended',
                              ),
                            ),
                            _SmallActionButton(
                              label: 'Ban',
                              icon: Icons.person_off_outlined,
                              color: _AdminColors.red,
                              onPressed: () => onUserStatusChanged(
                                report.reported,
                                'banned',
                              ),
                            ),
                            _SmallActionButton(
                              label: 'Dismiss',
                              icon: Icons.close,
                              onPressed: () =>
                                  onStatusChanged(report.id, 'dismissed'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostsReviewSection extends StatelessWidget {
  const _PostsReviewSection({
    required this.posts,
    required this.onApprove,
    required this.onRemove,
  });

  final List<_PostItem> posts;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Posts Review',
          subtitle: 'Review artwork, commission offers, and flagged posts.',
          trailing: const _ActionButton(
            label: 'Filter',
            icon: Icons.tune_outlined,
          ),
        ),
        _ResponsiveGrid(
          minItemWidth: 300,
          children: posts.map((post) {
            return _PostReviewCard(
              post: post,
              onApprove: () => onApprove(post.id),
              onRemove: () => onRemove(post.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PostReviewCard extends StatelessWidget {
  const _PostReviewCard({
    required this.post,
    required this.onApprove,
    required this.onRemove,
  });

  final _PostItem post;
  final VoidCallback onApprove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: post.type == 'artwork'
                    ? const [
                        Color(0xFFFFFFFF),
                        Color(0xFF003566),
                        Color(0xFF000088),
                      ]
                    : const [
                        Color(0xFFFFC300),
                        Color(0xFFFFC300),
                        Color(0xFF003566),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.brush_outlined,
                    color: _AdminColors.white,
                    size: 40,
                  ),
                ),
                if (post.flagged)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _AdminColors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'FLAGGED',
                        style: TextStyle(
                          color: _AdminColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _AdminColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.authorName} (@${post.author})',
                  style: const TextStyle(
                    color: _AdminColors.textSub,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _PostStat(icon: Icons.favorite, value: post.hearts),
                    _PostStat(
                      icon: Icons.visibility_outlined,
                      value: post.views,
                    ),
                    _PostStat(icon: Icons.share_outlined, value: post.shares),
                    _StatusBadge(status: post.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _ActionButton(
                      label: 'Review',
                      icon: Icons.visibility_outlined,
                      color: _AdminColors.blueAccent,
                    ),
                    if (post.status != 'approved')
                      _ActionButton(
                        label: 'Approve',
                        icon: Icons.check,
                        color: _AdminColors.green,
                        onPressed: onApprove,
                      ),
                    _ActionButton(
                      label: 'Remove',
                      icon: Icons.delete_outline,
                      color: _AdminColors.red,
                      onPressed: onRemove,
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

class _CommissionMonitoringSection extends StatelessWidget {
  const _CommissionMonitoringSection({required this.commissions});

  final List<_CommissionItem> commissions;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'pending',
      'accepted',
      'in_progress',
      'completed',
      'cancelled',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Commission Monitoring',
          subtitle: 'Track request status, disputes, and completion flow.',
          trailing: _ActionButton(
            label: 'Export',
            icon: Icons.download_outlined,
          ),
        ),
        _ResponsiveGrid(
          minItemWidth: 170,
          children: [
            for (final status in statuses)
              _MiniSummaryCard(
                label: _statusLabel(status),
                value: commissions
                    .where((commission) => commission.status == status)
                    .length
                    .toString(),
                icon: _commissionIcon(status),
                color: _statusColor(status),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final chart = _Card(
              child: _ChartPanel(
                title: 'Completed vs cancelled',
                subtitle: 'Mock monthly commission flow',
                child: _BarChartMock(
                  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  primaryValues: const [8, 14, 19, 28, 22],
                  secondaryValues: const [2, 3, 5, 4, 6],
                ),
              ),
            );
            final breakdown = _Card(
              child: _StatusBreakdown(
                title: 'Commission status',
                entries: [
                  _BreakdownEntry('Completed', 91, _AdminColors.green),
                  _BreakdownEntry('In Progress', 23, _AdminColors.blueAccent),
                  _BreakdownEntry('Pending', 15, _AdminColors.yellow),
                  _BreakdownEntry('Cancelled', 12, _AdminColors.textSub),
                  _BreakdownEntry('Disputed', 4, _AdminColors.red),
                ],
              ),
            );

            if (stacked) {
              return Column(
                children: [chart, const SizedBox(height: 12), breakdown],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: chart),
                const SizedBox(width: 12),
                Expanded(child: breakdown),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _Card(
          padding: EdgeInsets.zero,
          child: _AdminDataTable(
            columns: const [
              DataColumn(label: Text('Commission')),
              DataColumn(label: Text('Client')),
              DataColumn(label: Text('Seller')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: commissions.map((commission) {
              return DataRow(
                cells: [
                  DataCell(Text(commission.title)),
                  DataCell(Text('@${commission.client}')),
                  DataCell(Text('@${commission.seller}')),
                  DataCell(Text(commission.amount)),
                  DataCell(_StatusBadge(status: commission.status)),
                  DataCell(Text(commission.date)),
                  DataCell(
                    Wrap(
                      spacing: 6,
                      children: [
                        const _SmallActionButton(
                          label: 'View',
                          icon: Icons.visibility_outlined,
                          color: _AdminColors.blueAccent,
                        ),
                        if (commission.status == 'disputed')
                          const _SmallActionButton(
                            label: 'Mediate',
                            icon: Icons.shield_outlined,
                            color: _AdminColors.yellow,
                          ),
                        if (commission.status == 'in_progress')
                          const _SmallActionButton(
                            label: 'Flag',
                            icon: Icons.flag_outlined,
                            color: _AdminColors.red,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.users,
    required this.reports,
    required this.commissions,
  });

  final List<_AdminUser> users;
  final List<_ReportItem> reports;
  final List<_CommissionItem> commissions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Analytics',
          subtitle: 'Mock analytics for student activity and moderation load.',
          trailing: _ActionButton(
            label: 'Export Report',
            icon: Icons.download_outlined,
          ),
        ),
        _ResponsiveGrid(
          minItemWidth: 210,
          children: [
            _MetricCard(
              label: 'Total Registrations',
              value: users.length.toString(),
              trend: '+12% MoM',
              icon: Icons.groups_outlined,
              color: _AdminColors.navy,
            ),
            _MetricCard(
              label: 'Commissions Done',
              value: commissions
                  .where((commission) => commission.status == 'completed')
                  .length
                  .toString(),
              trend: '+18% MoM',
              icon: Icons.work_outline,
              color: _AdminColors.green,
            ),
            _MetricCard(
              label: 'Reports Filed',
              value: reports.length.toString(),
              trend: '+9% MoM',
              icon: Icons.flag_outlined,
              color: _AdminColors.red,
            ),
            const _MetricCard(
              label: 'Platform Activity',
              value: '504',
              trend: 'Posts + Chats',
              icon: Icons.timeline_outlined,
              color: _AdminColors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ResponsiveGrid(
          minItemWidth: 410,
          children: const [
            _Card(
              child: _ChartPanel(
                title: 'Registration trend',
                subtitle: 'Monthly account growth',
                child: _LineChartMock(
                  values: [23, 41, 38, 67, 52],
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  color: _AdminColors.navy,
                ),
              ),
            ),
            _Card(
              child: _ChartPanel(
                title: 'Report volume',
                subtitle: 'Moderation workload',
                child: _LineChartMock(
                  values: [4, 7, 5, 12, 9],
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  color: _AdminColors.red,
                ),
              ),
            ),
            _Card(
              child: _ChartPanel(
                title: 'Commission outcomes',
                subtitle: 'Completed and cancelled work',
                child: _BarChartMock(
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  primaryValues: [8, 14, 19, 28, 22],
                  secondaryValues: [2, 3, 5, 4, 6],
                ),
              ),
            ),
            _Card(
              child: _ChartPanel(
                title: 'Platform activity',
                subtitle: 'Posts, shares, and review activity',
                child: _LineChartMock(
                  values: [64, 91, 88, 142, 119],
                  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                  color: _AdminColors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Settings',
          subtitle: 'Platform configuration and admin preferences.',
        ),
        _EmptyState(
          icon: Icons.settings_outlined,
          title: 'Settings Panel',
          message:
              'Platform settings, notification preferences, and admin configuration would appear here.',
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AdminColors.inkBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: _AdminColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.minItemWidth = 260});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final count = (constraints.maxWidth / minItemWidth).floor().clamp(
          1,
          children.length,
        );
        final width = (constraints.maxWidth - spacing * (count - 1)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AdminColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AdminColors.navy.withAlpha(14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000088),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: _AdminColors.inkBlack,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _AdminColors.textMain,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AdminColors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Text(
              'No items need attention.',
              style: TextStyle(color: _AdminColors.textSub),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _CompactListTile extends StatelessWidget {
  const _CompactListTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _AdminColors.textMain,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _AdminColors.textSub),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: _AdminColors.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _AdminColors.textMain,
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

class _AdminDataTable extends StatelessWidget {
  const _AdminDataTable({required this.columns, required this.rows});

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No results',
        message: 'No mock records match the selected filters.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(_AdminColors.grayBg),
        headingTextStyle: const TextStyle(
          color: _AdminColors.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        dataTextStyle: const TextStyle(
          color: _AdminColors.textMain,
          fontSize: 12,
        ),
        columnSpacing: 26,
        horizontalMargin: 16,
        rows: rows,
        columns: columns,
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _AdminColors.textMain,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: _AdminColors.textSub, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(height: 190, child: child),
      ],
    );
  }
}

class _LineChartMock extends StatelessWidget {
  const _LineChartMock({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(values: values, color: color),
            child: Container(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in labels)
              Text(
                label,
                style: const TextStyle(
                  color: _AdminColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _AdminColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = values.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (maxValue - minValue).clamp(1, double.infinity);
    final step = values.length == 1
        ? size.width
        : size.width / (values.length - 1);
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - normalized * (size.height * .78) - 16;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(56), color.withAlpha(4)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - normalized * (size.height * .78) - 16;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = _AdminColors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _BarChartMock extends StatelessWidget {
  const _BarChartMock({
    required this.labels,
    required this.primaryValues,
    required this.secondaryValues,
  });

  final List<String> labels;
  final List<int> primaryValues;
  final List<int> secondaryValues;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...primaryValues,
      ...secondaryValues,
    ].reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Bar(
                          value: primaryValues[i],
                          maxValue: maxValue,
                          color: _AdminColors.green,
                        ),
                        const SizedBox(width: 4),
                        _Bar(
                          value: secondaryValues[i],
                          maxValue: maxValue,
                          color: _AdminColors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      color: _AdminColors.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FractionallySizedBox(
        heightFactor: (value / maxValue).clamp(.05, 1),
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.title, required this.entries});

  final String title;
  final List<_BreakdownEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AdminColors.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        for (final entry in entries) ...[
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    color: _AdminColors.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  color: _AdminColors.inkBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : entry.value / total,
              minHeight: 7,
              color: entry.color,
              backgroundColor: _AdminColors.grayBg,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BreakdownEntry {
  const _BreakdownEntry(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _AdminColors.inkBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminColors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: _AdminColors.border),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _AdminColors.textMain,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _AdminColors.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.hint,
    this.initialValue = '',
    this.onChanged,
  });

  final String hint;
  final String initialValue;
  final ValueChanged<String>? onChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _AdminColors.textSub),
          prefixIcon: const Icon(
            Icons.search,
            color: _AdminColors.textSub,
            size: 18,
          ),
          filled: true,
          fillColor: _AdminColors.grayBg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: _AdminColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _AdminColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: _AdminColors.blueAccent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: _AdminColors.grayBg,
            foregroundColor: _AdminColors.textSub,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _AdminColors.border),
            ),
            fixedSize: const Size(38, 38),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
        ),
        if (showDot)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _AdminColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: _AdminColors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _AdminColors.navy;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: effectiveColor.withAlpha(24),
        foregroundColor: effectiveColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _AdminColors.textSub;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(color: effectiveColor.withAlpha(74)),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 13),
      label: Text(label),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _AdminColors.yellow,
      backgroundColor: _AdminColors.grayBg,
      labelStyle: TextStyle(
        color: selected ? _AdminColors.inkBlack : _AdminColors.textMain,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? _AdminColors.yellow : _AdminColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => onPressed(),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _AdminColors.yellow,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: _AdminColors.inkBlack,
          fontSize: size * .34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _AdminColors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: _AdminColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _readableStatusColor(color),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return _StatusPill(
      label: _statusLabel(status),
      color: _statusColor(status),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    return _StatusPill(
      label: _titleCase(severity),
      color: _severityColor(severity),
    );
  }
}

class _ReasonTag extends StatelessWidget {
  const _ReasonTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _AdminColors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 13, color: _AdminColors.red),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.darkRed,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostStat extends StatelessWidget {
  const _PostStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _AdminColors.textSub),
        const SizedBox(width: 4),
        Text(
          _compactNumber(value),
          style: const TextStyle(
            color: _AdminColors.textMain,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AdminUser {
  const _AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.college,
    required this.department,
    required this.username,
    required this.status,
    required this.joined,
    required this.commissions,
    required this.verified,
    required this.initials,
  });

  final String id;
  final String name;
  final String email;
  final String studentId;
  final String college;
  final String department;
  final String username;
  final String status;
  final String joined;
  final int commissions;
  final bool verified;
  final String initials;

  _AdminUser copyWith({String? status}) {
    return _AdminUser(
      id: id,
      name: name,
      email: email,
      studentId: studentId,
      college: college,
      department: department,
      username: username,
      status: status ?? this.status,
      joined: joined,
      commissions: commissions,
      verified: verified,
      initials: initials,
    );
  }
}

class _VerificationRequest {
  const _VerificationRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.college,
    required this.department,
    required this.submitted,
    required this.idType,
    required this.selfieSubmitted,
  });

  final String id;
  final String name;
  final String email;
  final String studentId;
  final String college;
  final String department;
  final String submitted;
  final String idType;
  final bool selfieSubmitted;
}

class _ReportItem {
  const _ReportItem({
    required this.id,
    required this.reported,
    required this.reportedName,
    required this.by,
    required this.reason,
    required this.detail,
    required this.severity,
    required this.status,
    required this.date,
  });

  final String id;
  final String reported;
  final String reportedName;
  final String by;
  final String reason;
  final String detail;
  final String severity;
  final String status;
  final String date;

  _ReportItem copyWith({String? status}) {
    return _ReportItem(
      id: id,
      reported: reported,
      reportedName: reportedName,
      by: by,
      reason: reason,
      detail: detail,
      severity: severity,
      status: status ?? this.status,
      date: date,
    );
  }
}

class _PostItem {
  const _PostItem({
    required this.id,
    required this.author,
    required this.authorName,
    required this.title,
    required this.type,
    required this.hearts,
    required this.views,
    required this.shares,
    required this.flagged,
    required this.status,
    required this.posted,
  });

  final String id;
  final String author;
  final String authorName;
  final String title;
  final String type;
  final int hearts;
  final int views;
  final int shares;
  final bool flagged;
  final String status;
  final String posted;

  _PostItem copyWith({bool? flagged, String? status}) {
    return _PostItem(
      id: id,
      author: author,
      authorName: authorName,
      title: title,
      type: type,
      hearts: hearts,
      views: views,
      shares: shares,
      flagged: flagged ?? this.flagged,
      status: status ?? this.status,
      posted: posted,
    );
  }
}

class _CommissionItem {
  const _CommissionItem({
    required this.id,
    required this.title,
    required this.client,
    required this.seller,
    required this.amount,
    required this.status,
    required this.date,
  });

  final String id;
  final String title;
  final String client;
  final String seller;
  final String amount;
  final String status;
  final String date;
}

const _mockUsers = [
  _AdminUser(
    id: 'u001',
    name: 'Ana Reyes',
    email: 'ana.reyes@lnu.edu.ph',
    studentId: '2021-00123',
    college: 'CAS',
    department: 'Fine Arts',
    username: 'ana.draws',
    status: 'active',
    joined: 'Aug 15, 2024',
    commissions: 12,
    verified: true,
    initials: 'AR',
  ),
  _AdminUser(
    id: 'u002',
    name: 'Carlo Santos',
    email: 'carlo.santos@lnu.edu.ph',
    studentId: '2022-00456',
    college: 'CIT',
    department: 'Computer Science',
    username: 'carlo.codes',
    status: 'active',
    joined: 'Aug 20, 2024',
    commissions: 5,
    verified: true,
    initials: 'CS',
  ),
  _AdminUser(
    id: 'u003',
    name: 'Maria Lim',
    email: 'maria.lim@lnu.edu.ph',
    studentId: '2023-00789',
    college: 'COE',
    department: 'Architecture',
    username: 'maria.arch',
    status: 'suspended',
    joined: 'Jan 10, 2025',
    commissions: 2,
    verified: true,
    initials: 'ML',
  ),
  _AdminUser(
    id: 'u004',
    name: 'Jose Flores',
    email: 'jose.flores@lnu.edu.ph',
    studentId: '2024-01023',
    college: 'CBAA',
    department: 'Marketing',
    username: 'jose.fx',
    status: 'active',
    joined: 'Feb 5, 2025',
    commissions: 0,
    verified: false,
    initials: 'JF',
  ),
  _AdminUser(
    id: 'u005',
    name: 'Lara Cruz',
    email: 'lara.cruz@lnu.edu.ph',
    studentId: '2022-00301',
    college: 'CAS',
    department: 'Communication Arts',
    username: 'lara.creates',
    status: 'active',
    joined: 'Sep 3, 2024',
    commissions: 8,
    verified: true,
    initials: 'LC',
  ),
  _AdminUser(
    id: 'u006',
    name: 'Miguel Tan',
    email: 'miguel.tan@lnu.edu.ph',
    studentId: '2023-00542',
    college: 'CIT',
    department: 'Info Technology',
    username: 'miguelt',
    status: 'banned',
    joined: 'Oct 1, 2024',
    commissions: 1,
    verified: true,
    initials: 'MT',
  ),
  _AdminUser(
    id: 'u007',
    name: 'Sofia Garcia',
    email: 'sofia.garcia@lnu.edu.ph',
    studentId: '2021-00876',
    college: 'CAS',
    department: 'Visual Arts',
    username: 'sofiaG.art',
    status: 'active',
    joined: 'Aug 12, 2024',
    commissions: 20,
    verified: true,
    initials: 'SG',
  ),
  _AdminUser(
    id: 'u008',
    name: 'Ryan Mendoza',
    email: 'ryan.mendoza@lnu.edu.ph',
    studentId: '2024-01456',
    college: 'COE',
    department: 'Civil Engineering',
    username: 'ryanm',
    status: 'active',
    joined: 'Mar 20, 2025',
    commissions: 0,
    verified: false,
    initials: 'RM',
  ),
];

const _mockVerifications = [
  _VerificationRequest(
    id: 'v001',
    name: 'Ryan Mendoza',
    email: 'ryan.mendoza@lnu.edu.ph',
    studentId: '2024-01456',
    college: 'COE',
    department: 'Civil Engineering',
    submitted: 'May 18, 2025',
    idType: 'School ID',
    selfieSubmitted: true,
  ),
  _VerificationRequest(
    id: 'v002',
    name: 'Jasmine Uy',
    email: 'jasmine.uy@lnu.edu.ph',
    studentId: '2024-01802',
    college: 'CAS',
    department: 'Multimedia Arts',
    submitted: 'May 17, 2025',
    idType: 'School ID',
    selfieSubmitted: true,
  ),
  _VerificationRequest(
    id: 'v003',
    name: 'Nico Bautista',
    email: 'nico.bautista@lnu.edu.ph',
    studentId: '2025-00021',
    college: 'CBAA',
    department: 'Accountancy',
    submitted: 'May 16, 2025',
    idType: 'TOR + ID',
    selfieSubmitted: false,
  ),
  _VerificationRequest(
    id: 'v004',
    name: 'Patricia Ong',
    email: 'patricia.ong@lnu.edu.ph',
    studentId: '2023-01233',
    college: 'CIT',
    department: 'Info Technology',
    submitted: 'May 15, 2025',
    idType: 'School ID',
    selfieSubmitted: true,
  ),
  _VerificationRequest(
    id: 'v005',
    name: 'Kevin Villanueva',
    email: 'kevin.v@lnu.edu.ph',
    studentId: '2024-00987',
    college: 'COE',
    department: 'Mechanical Eng.',
    submitted: 'May 14, 2025',
    idType: 'School ID',
    selfieSubmitted: true,
  ),
];

const _mockReports = [
  _ReportItem(
    id: 'r001',
    reported: 'jose.fx',
    reportedName: 'Jose Flores',
    by: 'lara.creates',
    reason: 'Scam/Fraud',
    detail: 'Requested payment then went silent after partial payment.',
    severity: 'high',
    status: 'pending',
    date: 'May 18, 2025',
  ),
  _ReportItem(
    id: 'r002',
    reported: 'miguelt',
    reportedName: 'Miguel Tan',
    by: 'sofiaG.art',
    reason: 'Harassment',
    detail: 'Sent threatening messages after a negative commission review.',
    severity: 'critical',
    status: 'under_review',
    date: 'May 16, 2025',
  ),
  _ReportItem(
    id: 'r003',
    reported: 'carlo.codes',
    reportedName: 'Carlo Santos',
    by: 'ana.draws',
    reason: 'Plagiarism',
    detail: 'Reposted portfolio work without credit or permission.',
    severity: 'medium',
    status: 'resolved',
    date: 'May 14, 2025',
  ),
  _ReportItem(
    id: 'r004',
    reported: 'ryanm',
    reportedName: 'Ryan Mendoza',
    by: 'jose.fx',
    reason: 'Spam',
    detail: 'Posted the same commission offer repeatedly in 30 minutes.',
    severity: 'low',
    status: 'dismissed',
    date: 'May 13, 2025',
  ),
  _ReportItem(
    id: 'r005',
    reported: 'jose.fx',
    reportedName: 'Jose Flores',
    by: 'nico.bautista',
    reason: 'Inappropriate Content',
    detail: 'Post contained explicit language directed at another student.',
    severity: 'medium',
    status: 'pending',
    date: 'May 18, 2025',
  ),
  _ReportItem(
    id: 'r006',
    reported: 'miguelt',
    reportedName: 'Miguel Tan',
    by: 'kevinv',
    reason: 'Fake Identity',
    detail: 'Profile information does not match submitted student ID.',
    severity: 'high',
    status: 'pending',
    date: 'May 19, 2025',
  ),
];

const _mockPosts = [
  _PostItem(
    id: 'p001',
    author: 'ana.draws',
    authorName: 'Ana Reyes',
    title: 'Digital Portrait - Semi-Realistic Style',
    type: 'artwork',
    hearts: 145,
    views: 892,
    shares: 23,
    flagged: false,
    status: 'approved',
    posted: 'May 17, 2025',
  ),
  _PostItem(
    id: 'p002',
    author: 'sofiaG.art',
    authorName: 'Sofia Garcia',
    title: 'Logo Design Commission - OPEN',
    type: 'commission',
    hearts: 87,
    views: 430,
    shares: 11,
    flagged: false,
    status: 'approved',
    posted: 'May 17, 2025',
  ),
  _PostItem(
    id: 'p003',
    author: 'jose.fx',
    authorName: 'Jose Flores',
    title: 'Cheap commissions. DM for rates.',
    type: 'commission',
    hearts: 2,
    views: 154,
    shares: 0,
    flagged: true,
    status: 'flagged',
    posted: 'May 16, 2025',
  ),
  _PostItem(
    id: 'p004',
    author: 'lara.creates',
    authorName: 'Lara Cruz',
    title: 'New Portfolio - Brand Identity Pack',
    type: 'artwork',
    hearts: 203,
    views: 1240,
    shares: 45,
    flagged: false,
    status: 'approved',
    posted: 'May 15, 2025',
  ),
  _PostItem(
    id: 'p005',
    author: 'miguelt',
    authorName: 'Miguel Tan',
    title: 'Best digital artist - message me now',
    type: 'commission',
    hearts: 5,
    views: 89,
    shares: 1,
    flagged: true,
    status: 'under_review',
    posted: 'May 16, 2025',
  ),
];

const _mockCommissions = [
  _CommissionItem(
    id: 'c001',
    title: 'Brand Logo for Student Org',
    client: 'lara.creates',
    seller: 'ana.draws',
    amount: 'PHP 800',
    status: 'in_progress',
    date: 'May 10, 2025',
  ),
  _CommissionItem(
    id: 'c002',
    title: 'UI Design - 3 App Screens',
    client: 'nico.bautista',
    seller: 'carlo.codes',
    amount: 'PHP 1,200',
    status: 'completed',
    date: 'May 5, 2025',
  ),
  _CommissionItem(
    id: 'c003',
    title: 'Custom Digital Portrait',
    client: 'sofiaG.art',
    seller: 'ana.draws',
    amount: 'PHP 600',
    status: 'pending',
    date: 'May 18, 2025',
  ),
  _CommissionItem(
    id: 'c004',
    title: 'Tarpaulin Layout Design',
    client: 'kevinv',
    seller: 'sofiaG.art',
    amount: 'PHP 400',
    status: 'cancelled',
    date: 'May 12, 2025',
  ),
  _CommissionItem(
    id: 'c005',
    title: 'Social Media Content Kit',
    client: 'patricia.o',
    seller: 'lara.creates',
    amount: 'PHP 950',
    status: 'accepted',
    date: 'May 16, 2025',
  ),
  _CommissionItem(
    id: 'c006',
    title: 'Merch Sticker Illustration',
    client: 'jose.fx',
    seller: 'ana.draws',
    amount: 'PHP 700',
    status: 'disputed',
    date: 'May 13, 2025',
  ),
];

Color _statusColor(String status) {
  return switch (status) {
    'active' ||
    'approved' ||
    'completed' ||
    'resolved' ||
    'verified' => _AdminColors.green,
    'pending' || 'accepted' => _AdminColors.yellow,
    'under_review' ||
    'in_progress' ||
    'flagged' ||
    'unverified' => _AdminColors.blueAccent,
    'suspended' || 'cancelled' || 'dismissed' => _AdminColors.textSub,
    'banned' || 'disputed' => _AdminColors.red,
    _ => _AdminColors.textSub,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'under_review' => 'Under Review',
    'in_progress' => 'In Progress',
    _ => _titleCase(status.replaceAll('_', ' ')),
  };
}

Color _severityColor(String severity) {
  return switch (severity) {
    'critical' => _AdminColors.red,
    'high' => _AdminColors.darkRed,
    'medium' => _AdminColors.yellow,
    'low' => _AdminColors.blueAccent,
    _ => _AdminColors.textSub,
  };
}

Color _readableStatusColor(Color color) {
  if (color == _AdminColors.yellow || color == _AdminColors.gold) {
    return const Color(0xFF003566);
  }
  if (color == _AdminColors.green) {
    return const Color(0xFF00E200);
  }
  if (color == _AdminColors.textSub) {
    return _AdminColors.textMain;
  }
  return color;
}

IconData _commissionIcon(String status) {
  return switch (status) {
    'pending' => Icons.schedule_outlined,
    'accepted' => Icons.handshake_outlined,
    'in_progress' => Icons.autorenew_outlined,
    'completed' => Icons.check_circle_outline,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.work_outline,
  };
}

String _titleCase(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _initials(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();
}

String _compactNumber(int value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

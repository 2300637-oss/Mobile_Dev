import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    _NotificationItem(
      type: 'message',
      icon: Icons.mark_chat_unread_outlined,
      title: 'New message alerts',
      message: 'Direct message notifications from other students appear here.',
      accent: AppColors.royalAzure,
    ),
    _NotificationItem(
      type: 'heart',
      icon: Icons.favorite_border,
      title: 'Heart reactions',
      message: 'You will see alerts when someone hearts your post.',
      accent: AppColors.cinnabar,
    ),
    _NotificationItem(
      type: 'share',
      icon: Icons.share_outlined,
      title: 'Shared posts',
      message: 'Track when your posts are shared by other LNU students.',
      accent: AppColors.regalNavy,
    ),
    _NotificationItem(
      type: 'commission',
      icon: Icons.assignment_turned_in_outlined,
      title: 'Commission updates',
      message: 'Progress, status, and delivery updates for commissions.',
      accent: AppColors.radioactiveGrass,
    ),
    _NotificationItem(
      type: 'service_inquiry',
      icon: Icons.design_services_outlined,
      title: 'Service inquiries',
      message: 'Questions and requests about your listed services.',
      accent: AppColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<_LiveNotification>>(
          future: _loadNotifications(userId),
          builder: (context, snapshot) {
            final liveItems = snapshot.data ?? const <_LiveNotification>[];
            return RefreshIndicator(
              onRefresh: () async {
                await _loadNotifications(userId);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (liveItems.isNotEmpty) ...[
                    const _SectionLabel('Recent alerts'),
                    for (final item in liveItems) ...[
                      _LiveNotificationTile(item: item),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                  const _SectionLabel('Notification types'),
                  for (final item in _items) ...[
                    _NotificationTile(
                      item: item,
                      notifications: liveItems
                          .where((live) => live.type == item.type)
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<List<_LiveNotification>> _loadNotifications(String userId) async {
    if (userId.isEmpty) {
      return const <_LiveNotification>[];
    }

    final client = Supabase.instance.client;
    final notifications = <_LiveNotification>[];
    try {
      final chatRows = await client
          .from('chat_notifications')
          .select('title, body, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      notifications.addAll(
        chatRows.map(
          (row) => _LiveNotification(
            type: 'message',
            icon: Icons.mark_chat_unread_outlined,
            title: row['title'] as String? ?? 'New message',
            message: row['body'] as String? ?? '',
            createdAt: _dateFromValue(row['created_at']),
            accent: AppColors.royalAzure,
          ),
        ),
      );
    } catch (_) {}

    try {
      final rows = await client
          .from('app_notifications')
          .select('type, title, body, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      notifications.addAll(rows.map(_notificationFromMap));
    } catch (_) {}

    final uniqueNotifications = _deduplicateNotifications(notifications);
    uniqueNotifications.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return uniqueNotifications;
  }

  _LiveNotification _notificationFromMap(Map<String, dynamic> row) {
    final type = row['type'] as String? ?? '';
    final icon = switch (type) {
      'heart' => Icons.favorite_border,
      'share' => Icons.share_outlined,
      'commission' => Icons.assignment_turned_in_outlined,
      'service_inquiry' => Icons.design_services_outlined,
      _ => Icons.notifications_outlined,
    };
    final accent = switch (type) {
      'heart' => AppColors.cinnabar,
      'share' => AppColors.regalNavy,
      'commission' => AppColors.radioactiveGrass,
      'service_inquiry' => AppColors.gold,
      _ => AppColors.royalAzure,
    };
    return _LiveNotification(
      type: type,
      icon: icon,
      title: row['title'] as String? ?? 'Notification',
      message: row['body'] as String? ?? '',
      createdAt: _dateFromValue(row['created_at']),
      accent: accent,
    );
  }
}

List<_LiveNotification> _deduplicateNotifications(
  List<_LiveNotification> notifications,
) {
  final seen = <String>{};
  final unique = <_LiveNotification>[];
  for (final notification in notifications) {
    final key = [
      notification.type,
      notification.title.trim().toLowerCase(),
      notification.message.trim().toLowerCase(),
    ].join('|');
    if (seen.add(key)) {
      unique.add(notification);
    }
  }
  return unique;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _LiveNotificationTile extends StatelessWidget {
  const _LiveNotificationTile({required this.item});

  final _LiveNotification item;

  @override
  Widget build(BuildContext context) {
    return _NotificationSurface(
      icon: item.icon,
      title: item.title,
      message: item.message,
      accent: item.accent,
      trailing: Text(
        _relativeTime(item.createdAt),
        style: const TextStyle(color: Colors.black45, fontSize: 11),
      ),
      onTap: () => _showDetails(context),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.inkBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _relativeTime(item.createdAt),
                    style: const TextStyle(color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.message.isEmpty ? 'No details available.' : item.message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.notifications});

  final _NotificationItem item;
  final List<_LiveNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showCategory(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _NotificationContent(
            icon: item.icon,
            title: item.title,
            message: item.message,
            accent: item.accent,
            trailing: const Icon(Icons.chevron_right, color: Colors.black38),
          ),
        ),
      ),
    );
  }

  void _showCategory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.inkBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'No ${item.title.toLowerCase()} yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(notification.icon, color: item.accent),
                        title: Text(notification.title),
                        subtitle: Text(notification.message),
                        trailing: Text(_relativeTime(notification.createdAt)),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSurface extends StatelessWidget {
  const _NotificationSurface({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _NotificationContent(
            icon: icon,
            title: title,
            message: message,
            accent: accent,
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.inkBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _LiveNotification {
  const _LiveNotification({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.accent,
  });

  final String type;
  final IconData icon;
  final String title;
  final String message;
  final DateTime? createdAt;
  final Color accent;
}

class _NotificationItem {
  const _NotificationItem({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  final String type;
  final IconData icon;
  final String title;
  final String message;
  final Color accent;
}

DateTime? _dateFromValue(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _relativeTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final diff = DateTime.now().difference(value);
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

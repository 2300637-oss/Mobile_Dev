import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../app/app_colors.dart';
import '../../../auth/domain/auth_user.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.client,
    required this.currentUser,
  });

  final SupabaseClient client;
  final AuthUser currentUser;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<_NotificationItem>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _NotificationMessage(
                icon: Icons.notifications_off_outlined,
                title: 'Unable to load notifications',
                message: 'Please try again in a moment.',
                onRetry: _refresh,
              );
            }

            final items = snapshot.data ?? const <_NotificationItem>[];
            if (items.isEmpty) {
              return const _NotificationMessage(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                message: 'New messages and post hearts will appear here.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationTile(item: item);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
  }

  Future<List<_NotificationItem>> _loadNotifications() async {
    final results = await Future.wait([
      _loadChatNotifications(),
      _loadHeartNotifications(),
    ]);
    final items = [...results[0], ...results[1]];
    items.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return items;
  }

  Future<List<_NotificationItem>> _loadChatNotifications() async {
    final rows = await widget.client
        .from('chat_notifications')
        .select('id, conversation_id, title, body, created_at')
        .eq('user_id', widget.currentUser.id)
        .order('created_at', ascending: false)
        .limit(30);

    return rows
        .map<_NotificationItem>((row) {
          final title = row['title'] as String? ?? 'New message';
          final body = row['body'] as String? ?? '';
          return _NotificationItem(
            id: 'chat-${row['id']}',
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.royalAzure,
            title: title.isEmpty ? 'New message' : title,
            message: body.isEmpty ? 'Sent you a message.' : body,
            createdAt: _dateFromValue(row['created_at']),
            onTapPath: '/chat/${row['conversation_id']}',
          );
        })
        .toList(growable: false);
  }

  Future<List<_NotificationItem>> _loadHeartNotifications() async {
    final posts = await widget.client
        .from('posts')
        .select('id, caption')
        .eq('author_id', widget.currentUser.id);
    final postIds = posts
        .map((row) => row['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (postIds.isEmpty) {
      return const <_NotificationItem>[];
    }

    final reactions = await widget.client
        .from('post_reactions')
        .select('post_id, user_id, created_at')
        .inFilter('post_id', postIds)
        .neq('user_id', widget.currentUser.id)
        .order('created_at', ascending: false)
        .limit(30);
    if (reactions.isEmpty) {
      return const <_NotificationItem>[];
    }

    final userIds = reactions
        .map((row) => row['user_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profiles = userIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await widget.client
              .from('profiles')
              .select('uid, full_name, username')
              .inFilter('uid', userIds);
    final profilesById = {
      for (final profile in profiles) profile['uid'] as String: profile,
    };
    final postsById = {for (final post in posts) post['id'] as String: post};

    return reactions
        .map<_NotificationItem>((row) {
          final userId = row['user_id'] as String? ?? '';
          final profile = profilesById[userId] ?? const <String, dynamic>{};
          final post = postsById[row['post_id']] ?? const <String, dynamic>{};
          final name = _displayName(profile);
          final caption = (post['caption'] as String? ?? '').trim();
          return _NotificationItem(
            id: 'heart-${row['post_id']}-$userId',
            icon: Icons.favorite,
            iconColor: AppColors.cinnabar,
            title: '$name liked your post',
            message: caption.isEmpty
                ? 'Your post received a new heart.'
                : caption,
            createdAt: _dateFromValue(row['created_at']),
            onTapPath: '/home',
          );
        })
        .toList(growable: false);
  }

  String _displayName(Map<String, dynamic> profile) {
    final username = profile['username'] as String? ?? '';
    final fullName = profile['full_name'] as String? ?? '';
    if (username.isNotEmpty) {
      return username;
    }
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return 'Someone';
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: item.onTapPath == null
            ? null
            : () => context.go(item.onTapPath!),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.iconColor.withValues(alpha: .12),
                foregroundColor: item.iconColor,
                child: Icon(item.icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.inkBlack,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(item.createdAt),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.midnightBlue, size: 54),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.onTapPath,
  });

  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final DateTime? createdAt;
  final String? onTapPath;
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

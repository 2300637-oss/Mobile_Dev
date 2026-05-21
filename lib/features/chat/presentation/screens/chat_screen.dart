import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../domain/chat_models.dart';
import '../controllers/chat_list_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatListController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            const _ChatHeader(),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AuthErrorBanner(
                  message: controller.errorMessage!,
                  onDismissed: controller.clearError,
                ),
              ),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.conversations.isEmpty
                  ? const _EmptyChats()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                      itemCount: controller.conversations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ConversationTile(
                        summary: controller.conversations[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New chat',
        backgroundColor: AppColors.schoolBusYellow,
        foregroundColor: AppColors.inkBlack,
        shape: const CircleBorder(),
        onPressed: () => _showContacts(context, controller),
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }

  void _showContacts(BuildContext context, ChatListController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final contacts = controller.contacts;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Start Chat',
                  style: TextStyle(
                    color: AppColors.inkBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text('No contacts found yet.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: contacts.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _ContactAvatar(contact: contact),
                          title: Text(
                            contact.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            contact.detail.isEmpty
                                ? 'LNU student'
                                : contact.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            final conversationId = await controller
                                .startConversation(contact);
                            if (!sheetContext.mounted ||
                                conversationId == null) {
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            context.go('/chat/$conversationId');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.white,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Messages, files, and commission updates',
                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: AppColors.white),
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.cinnabar,
                      shape: BoxShape.circle,
                    ),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.summary});

  final ConversationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/chat/${summary.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ContactAvatar(contact: summary.peer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.peer.name,
                            style: const TextStyle(
                              color: AppColors.inkBlack,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _shortTime(summary.lastMessageAt),
                          style: const TextStyle(
                            color: AppColors.regalNavy,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.isPeerTyping
                          ? 'Typing...'
                          : summary.lastMessage.isEmpty
                          ? 'No messages yet'
                          : summary.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: summary.isPeerTyping
                            ? AppColors.radioactiveGrass
                            : AppColors.regalNavy,
                        fontWeight: summary.unreadCount > 0
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.cinnabar,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${summary.unreadCount}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _shortTime(DateTime? value) {
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

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.contact});

  final ChatContact contact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.navy,
          backgroundImage: contact.avatarUrl.isEmpty
              ? null
              : NetworkImage(contact.avatarUrl),
          child: contact.avatarUrl.isEmpty
              ? Text(
                  contact.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.schoolBusYellow,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 1,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: AppColors.radioactiveGrass,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.navy, size: 54),
            SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'Start a one-to-one chat with an LNU creative.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

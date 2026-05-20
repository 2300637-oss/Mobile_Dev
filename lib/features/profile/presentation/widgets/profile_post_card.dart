import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import 'profile_style.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({
    super.key,
    required this.post,
    required this.profile,
    required this.liked,
    required this.saved,
    required this.isOwner,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onComment,
    required this.onShare,
    required this.onPinToggle,
    required this.onEdit,
    required this.onEditAudience,
    required this.onDelete,
    required this.onReport,
  });

  final ProfilePost post;
  final StudentProfile profile;
  final bool liked;
  final bool saved;
  final bool isOwner;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onPinToggle;
  final VoidCallback onEdit;
  final VoidCallback onEditAudience;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final likeCount = liked ? post.likesCount + 1 : post.likesCount;
    return Container(
      decoration: profileCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        color: SkillHubProfileColors.textMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                          ),
                        ),
                        const Text(
                          '-',
                          style: TextStyle(color: Color(0xFFCBD5E1)),
                        ),
                        _VisibilityPill(visibility: post.visibility),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PostMenuAction>(
                key: Key('post-menu-${post.id}'),
                tooltip: 'More',
                onSelected: _handleMenuAction,
                itemBuilder: (context) => isOwner
                    ? [
                        PopupMenuItem(
                          value: _PostMenuAction.pin,
                          child: Text(
                            post.isPinned ? 'Unpin post' : 'Pin post',
                          ),
                        ),
                        const PopupMenuItem(
                          value: _PostMenuAction.save,
                          child: Text('Save post'),
                        ),
                        const PopupMenuItem(
                          value: _PostMenuAction.edit,
                          child: Text('Edit post'),
                        ),
                        const PopupMenuItem(
                          value: _PostMenuAction.editAudience,
                          child: Text('Edit audience'),
                        ),
                        const PopupMenuItem(
                          value: _PostMenuAction.delete,
                          child: Text('Delete post'),
                        ),
                      ]
                    : const [
                        PopupMenuItem(
                          value: _PostMenuAction.report,
                          child: Text('Report post'),
                        ),
                      ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          if (post.isPinned) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: SkillHubProfileColors.navy,
                ),
                SizedBox(width: 5),
                Text(
                  'Pinned post',
                  style: TextStyle(
                    color: SkillHubProfileColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          if (post.attachment != null) ...[
            const SizedBox(height: 12),
            _AttachmentPreview(attachment: post.attachment!, postId: post.id),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  key: Key('post-heart-${post.id}'),
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  color: liked
                      ? SkillHubProfileColors.red
                      : SkillHubProfileColors.textSub,
                  label: '$likeCount',
                  onPressed: onToggleLike,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentsCount}',
                  onPressed: onComment,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: onShare,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  key: Key('post-save-${post.id}'),
                  icon: saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved
                      ? SkillHubProfileColors.navy
                      : SkillHubProfileColors.textSub,
                  label: 'Save',
                  onPressed: onToggleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share post'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onShare();
                },
              ),
              ListTile(
                leading: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                title: Text(saved ? 'Remove saved post' : 'Save post'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onToggleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete post'),
                textColor: Colors.red,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PostMenuAction { pin, save, edit, editAudience, delete, report }

class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.visibility});

  final VisibilityType visibility;

  @override
  Widget build(BuildContext context) {
    final colors = switch (visibility) {
      VisibilityType.lnuPublic => (
        const Color(0xFFF0FDF4),
        const Color(0xFF166534),
        const Color(0xFFBBF7D0),
      ),
      VisibilityType.connections => (
        const Color(0xFFFFF7ED),
        const Color(0xFFC2410C),
        const Color(0xFFFED7AA),
      ),
      VisibilityType.private => (
        const Color(0xFFF8FAFC),
        SkillHubProfileColors.textSub,
        SkillHubProfileColors.border,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.$3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_visibilityIcon(visibility), size: 11, color: colors.$2),
          const SizedBox(width: 3),
          Text(
            visibility.label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.postId});

  final ProfileAttachment attachment;
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: SkillHubProfileColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _gradientFor(postId)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      color: SkillHubProfileColors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attachment.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 15,
                  color: SkillHubProfileColors.textSub,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    attachment.label,
                    style: const TextStyle(
                      color: SkillHubProfileColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Text(
                  'Preview',
                  style: TextStyle(
                    color: SkillHubProfileColors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _gradientFor(String id) {
    if (id.endsWith('2')) {
      return const LinearGradient(
        colors: [SkillHubProfileColors.yellow, SkillHubProfileColors.gold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (id.endsWith('3')) {
      return const LinearGradient(
        colors: [SkillHubProfileColors.midBlue, SkillHubProfileColors.red],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [SkillHubProfileColors.navy, SkillHubProfileColors.blueAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = SkillHubProfileColors.textSub,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

IconData _visibilityIcon(VisibilityType visibility) {
  return switch (visibility) {
    VisibilityType.private => Icons.lock_outline,
    VisibilityType.connections => Icons.people_outline,
    VisibilityType.lnuPublic => Icons.public,
  };
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../domain/chat_models.dart';
import '../controllers/chat_thread_controller.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatThreadController>();
    final messages = controller.messages;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _ThreadHeader(),
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
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(
                          message: message,
                          isMine: controller.isMine(message),
                        );
                      },
                    ),
            ),
            _TypingLine(isVisible: controller.typingUserIds.isNotEmpty),
            _MessageComposer(
              controller: _messageController,
              isSending: controller.isSending,
              isUploading: controller.isUploading,
              onChanged: controller.updateTyping,
              onAttachImage: controller.pickAndSendImage,
              onAttachFile: controller.pickAndSendFile,
              onSend: () async {
                final text = _messageController.text;
                _messageController.clear();
                controller.updateTyping('');
                await controller.sendText(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: const BoxDecoration(color: AppColors.midnightBlue),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.white,
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.schoolBusYellow,
            child: Icon(Icons.person, color: AppColors.midnightBlue),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Direct Message',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Online',
                  style: TextStyle(
                    color: AppColors.radioactiveGrass,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.royalAzure : AppColors.white;
    final textColor = isMine ? AppColors.white : AppColors.inkBlack;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .76,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(isMine ? 8 : 2),
              bottomRight: Radius.circular(isMine ? 2 : 8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.hasAttachment) ...[
                _AttachmentPreview(message: message),
                if (message.body.isNotEmpty) const SizedBox(height: 8),
              ],
              if (message.body.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.body,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _shortTime(message.createdAt),
                    style: TextStyle(
                      color: isMine ? const Color(0xCCFFFFFF) : Colors.black45,
                      fontSize: 10,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.seenAt == null ? Icons.check : Icons.done_all,
                      color: const Color(0xCCFFFFFF),
                      size: 13,
                    ),
                  ],
                ],
              ),
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
    final hour = value.hour > 12 ? value.hour - 12 : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.attachmentType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.attachmentUrl,
          height: 170,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FileTile(name: message.attachmentName),
        ),
      );
    }

    return _FileTile(name: message.attachmentName);
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name.isEmpty ? 'Attachment' : name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingLine extends StatelessWidget {
  const _TypingLine({required this.isVisible});

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isVisible
          ? const Padding(
              key: ValueKey('typing'),
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Typing...',
                  style: TextStyle(
                    color: AppColors.radioactiveGrass,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : const SizedBox(key: ValueKey('empty'), height: 6),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.isUploading,
    required this.onChanged,
    required this.onAttachImage,
    required this.onAttachFile,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isUploading;
  final ValueChanged<String> onChanged;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachFile;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Attach',
            onPressed: isUploading ? null : () => _showAttachmentMenu(context),
            icon: isUploading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: const Color(0xFFF3F4F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.royalAzure,
              foregroundColor: AppColors.white,
            ),
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onAttachImage();
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onAttachFile();
                  },
                  icon: const Icon(Icons.insert_drive_file_outlined),
                  label: const Text('File'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

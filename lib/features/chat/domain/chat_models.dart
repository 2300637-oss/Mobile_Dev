class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.detail,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String detail;
  final String avatarUrl;
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.peer,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isPeerTyping,
  });

  final String id;
  final ChatContact peer;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isPeerTyping;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.attachmentType,
    required this.createdAt,
    required this.seenAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String attachmentUrl;
  final String attachmentName;
  final String attachmentType;
  final DateTime? createdAt;
  final DateTime? seenAt;

  bool get hasAttachment => attachmentUrl.isNotEmpty;

  factory ChatMessage.fromSupabaseMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id']?.toString() ?? '',
      conversationId: data['conversation_id'] as String? ?? '',
      senderId: data['sender_id'] as String? ?? '',
      body: data['body'] as String? ?? '',
      attachmentUrl: data['attachment_url'] as String? ?? '',
      attachmentName: data['attachment_name'] as String? ?? '',
      attachmentType: data['attachment_type'] as String? ?? '',
      createdAt: _dateFromValue(data['created_at']),
      seenAt: _dateFromValue(data['seen_at']),
    );
  }
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

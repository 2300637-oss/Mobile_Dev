import 'package:image_picker/image_picker.dart';

import '../../auth/domain/auth_user.dart';
import '../domain/chat_models.dart';

abstract class ChatDataSource {
  Stream<List<ConversationSummary>> watchConversations(String currentUserId);

  Stream<List<ChatMessage>> watchMessages({
    required String conversationId,
    required String currentUserId,
  });

  Stream<List<String>> watchTypingUsers({
    required String conversationId,
    required String currentUserId,
  });

  Future<List<ChatContact>> fetchContacts(String currentUserId);

  Future<ChatContact?> fetchConversationPeer({
    required String conversationId,
    required String currentUserId,
  });

  Future<String> startConversation({
    required AuthUser currentUser,
    required ChatContact peer,
  });

  Future<void> sendMessage({
    required String conversationId,
    required AuthUser sender,
    required String body,
    String attachmentUrl = '',
    String attachmentName = '',
    String attachmentType = '',
  });

  Future<void> markConversationSeen({
    required String conversationId,
    required String currentUserId,
  });

  Future<void> setTyping({
    required String conversationId,
    required String currentUserId,
    required bool isTyping,
  });

  Future<String> uploadAttachment({
    required String userId,
    required XFile file,
  });
}

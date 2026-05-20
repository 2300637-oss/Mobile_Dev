import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../../auth/domain/auth_user.dart';
import '../domain/chat_models.dart';
import 'chat_repository.dart';

class LocalChatRepository implements ChatDataSource {
  LocalChatRepository();

  static final List<ChatContact> _contacts = [
    const ChatContact(
      id: '00000000-0000-4000-8000-000000000101',
      name: 'ari.arts',
      detail: 'College of Arts and Sciences',
    ),
    const ChatContact(
      id: '00000000-0000-4000-8000-000000000102',
      name: 'pixel.migs',
      detail: 'College of Computer Studies',
    ),
    const ChatContact(
      id: '00000000-0000-4000-8000-000000000103',
      name: 'Miguel Santos',
      detail: 'UI/UX and digital art',
    ),
  ];
  static final Map<String, List<ChatMessage>> _messages = {};
  static final Map<String, ChatContact> _peersByConversation = {};
  static final Map<String, Set<String>> _participantsByConversation = {};
  static final Map<String, StreamController<void>> _controllers = {};
  static final Map<String, Set<String>> _typingUsers = {};

  @override
  Stream<List<ConversationSummary>> watchConversations(
    String currentUserId,
  ) async* {
    _seed(currentUserId);
    yield _conversationSummaries(currentUserId);
    yield* _controllerFor(
      'conversations',
    ).stream.map((_) => _conversationSummaries(currentUserId));
  }

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String conversationId,
    required String currentUserId,
  }) async* {
    yield List.unmodifiable(
      _visibleMessages(
        conversationId: conversationId,
        currentUserId: currentUserId,
      ),
    );
    yield* _controllerFor(conversationId).stream.map(
      (_) => List.unmodifiable(
        _visibleMessages(
          conversationId: conversationId,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  @override
  Stream<List<String>> watchTypingUsers({
    required String conversationId,
    required String currentUserId,
  }) async* {
    yield const <String>[];
    yield* _controllerFor('typing-$conversationId').stream.map((_) {
      return (_typingUsers[conversationId] ?? const <String>{})
          .where((id) => id != currentUserId)
          .toList(growable: false);
    });
  }

  @override
  Future<List<ChatContact>> fetchContacts(String currentUserId) async {
    return _contacts
        .where((contact) => contact.id != currentUserId)
        .toList(growable: false);
  }

  @override
  Future<String> startConversation({
    required AuthUser currentUser,
    required ChatContact peer,
  }) async {
    final conversationId = _conversationId(currentUser.id, peer.id);
    _peersByConversation[conversationId] = peer;
    _participantsByConversation[conversationId] = {currentUser.id, peer.id};
    _messages.putIfAbsent(conversationId, () => []);
    _notify('conversations');
    return conversationId;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required AuthUser sender,
    required String body,
    String attachmentUrl = '',
    String attachmentName = '',
    String attachmentType = '',
  }) async {
    if (!_isParticipant(
      conversationId: conversationId,
      currentUserId: sender.id,
    )) {
      throw StateError('Current user is not part of this conversation.');
    }

    final now = DateTime.now();
    final message = ChatMessage(
      id: 'local-${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: sender.id,
      body: body.trim(),
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentType: attachmentType,
      createdAt: now,
      seenAt: null,
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);
    await setTyping(
      conversationId: conversationId,
      currentUserId: sender.id,
      isTyping: false,
    );
    _notify(conversationId);
    _notify('conversations');
  }

  @override
  Future<void> markConversationSeen({
    required String conversationId,
    required String currentUserId,
  }) async {}

  @override
  Future<void> setTyping({
    required String conversationId,
    required String currentUserId,
    required bool isTyping,
  }) async {
    if (!_isParticipant(
      conversationId: conversationId,
      currentUserId: currentUserId,
    )) {
      return;
    }

    final users = _typingUsers.putIfAbsent(conversationId, () => <String>{});
    if (isTyping) {
      users.add(currentUserId);
    } else {
      users.remove(currentUserId);
    }
    _notify('typing-$conversationId');
    _notify('conversations');
  }

  @override
  Future<String> uploadAttachment({
    required String userId,
    required XFile file,
  }) async {
    return file.path;
  }

  static void _seed(String currentUserId) {
    final conversationId = _conversationId(currentUserId, _contacts.first.id);
    if (_messages.containsKey(conversationId)) {
      return;
    }
    _peersByConversation[conversationId] = _contacts.first;
    _participantsByConversation[conversationId] = {
      currentUserId,
      _contacts.first.id,
    };
    _messages[conversationId] = [
      ChatMessage(
        id: 'seed-1',
        conversationId: conversationId,
        senderId: _contacts.first.id,
        body: 'Hi! I saw your post. Are you open for commissions?',
        attachmentUrl: '',
        attachmentName: '',
        attachmentType: '',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        seenAt: DateTime.now().subtract(const Duration(minutes: 16)),
      ),
      ChatMessage(
        id: 'seed-2',
        conversationId: conversationId,
        senderId: currentUserId,
        body: 'Hello! Yes, I am open. What did you have in mind?',
        attachmentUrl: '',
        attachmentName: '',
        attachmentType: '',
        createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
        seenAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  static List<ConversationSummary> _conversationSummaries(
    String currentUserId,
  ) {
    final summaries = _messages.entries
        .where((entry) {
          return _isParticipant(
            conversationId: entry.key,
            currentUserId: currentUserId,
          );
        })
        .map((entry) {
          final messages = entry.value;
          final peer = _peersByConversation[entry.key] ?? _contacts.first;
          final lastMessage = messages.isEmpty ? null : messages.last;
          return ConversationSummary(
            id: entry.key,
            peer: peer,
            lastMessage: lastMessage?.body.isNotEmpty == true
                ? lastMessage!.body
                : lastMessage?.hasAttachment == true
                ? 'Attachment'
                : 'No messages yet',
            lastMessageAt: lastMessage?.createdAt,
            unreadCount: messages
                .where(
                  (message) =>
                      message.senderId != currentUserId &&
                      message.seenAt == null,
                )
                .length,
            isPeerTyping: (_typingUsers[entry.key] ?? const <String>{})
                .contains(peer.id),
          );
        })
        .toList();
    summaries.sort((a, b) {
      final left = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return summaries;
  }

  static List<ChatMessage> _visibleMessages({
    required String conversationId,
    required String currentUserId,
  }) {
    if (!_isParticipant(
      conversationId: conversationId,
      currentUserId: currentUserId,
    )) {
      return const <ChatMessage>[];
    }
    return _messages[conversationId] ?? const <ChatMessage>[];
  }

  static bool _isParticipant({
    required String conversationId,
    required String currentUserId,
  }) {
    final participants = _participantsByConversation[conversationId];
    if (participants != null) {
      return participants.contains(currentUserId);
    }

    return conversationId.split('_').contains(currentUserId);
  }

  static String _conversationId(String left, String right) {
    final ids = [left, right]..sort();
    return '${ids.first}_${ids.last}';
  }

  static StreamController<void> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<void>.broadcast(),
    );
  }

  static void _notify(String key) {
    _controllerFor(key).add(null);
  }
}

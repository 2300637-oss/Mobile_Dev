import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../auth/domain/auth_user.dart';
import '../domain/chat_models.dart';
import 'chat_repository.dart';

class SupabaseChatRepository implements ChatDataSource {
  SupabaseChatRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<List<ConversationSummary>> watchConversations(String currentUserId) {
    return _client
        .from('conversation_participants')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', currentUserId)
        .asyncMap((rows) => _loadConversationSummaries(currentUserId, rows));
  }

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String conversationId,
    required String currentUserId,
  }) async* {
    yield await _fetchMessages(conversationId);
    yield* Stream.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => _fetchMessages(conversationId));
  }

  @override
  Stream<List<String>> watchTypingUsers({
    required String conversationId,
    required String currentUserId,
  }) {
    return _client
        .from('typing_status')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .map((rows) {
          final now = DateTime.now();
          return rows
              .where((row) {
                final updatedAt = _dateFromValue(row['updated_at']);
                return row['user_id'] != currentUserId &&
                    row['is_typing'] == true &&
                    updatedAt != null &&
                    now.difference(updatedAt).inSeconds < 12;
              })
              .map((row) => row['user_id'] as String? ?? '')
              .where((userId) => userId.isNotEmpty)
              .toList(growable: false);
        });
  }

  @override
  Future<List<ChatContact>> fetchContacts(String currentUserId) async {
    final rows = await _client
        .from('profiles')
        .select(
          'uid, full_name, username, college, department, year_level, profile_picture_url',
        )
        .neq('uid', currentUserId)
        .order('full_name');

    return rows.map(_contactFromProfile).toList(growable: false);
  }

  @override
  Future<ChatContact?> fetchConversationPeer({
    required String conversationId,
    required String currentUserId,
  }) async {
    final participantRows = await _client
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', conversationId);
    final peerId = participantRows
        .map((row) => row['user_id'] as String? ?? '')
        .firstWhere(
          (userId) => userId.isNotEmpty && userId != currentUserId,
          orElse: () => '',
        );
    if (peerId.isEmpty) {
      return null;
    }

    final profile = await _client
        .from('profiles')
        .select(
          'uid, full_name, username, college, department, year_level, profile_picture_url',
        )
        .eq('uid', peerId)
        .maybeSingle();
    return _contactFromProfile(
      profile ?? const <String, dynamic>{},
      fallbackId: peerId,
    );
  }

  @override
  Future<String> startConversation({
    required AuthUser currentUser,
    required ChatContact peer,
  }) async {
    final existing = await _findExistingConversation(currentUser.id, peer.id);
    if (existing != null) {
      return existing;
    }

    final conversationId = _uuidV4();
    await _client.from('conversations').insert({
      'id': conversationId,
      'last_message_text': '',
      'last_message_at': null,
    });

    await _client.from('conversation_participants').insert([
      {
        'conversation_id': conversationId,
        'user_id': currentUser.id,
        'display_name': currentUser.displayName ?? currentUser.email ?? '',
      },
      {
        'conversation_id': conversationId,
        'user_id': peer.id,
        'display_name': peer.name,
      },
    ]);

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
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty && attachmentUrl.isEmpty) {
      return;
    }

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': sender.id,
      'body': trimmedBody,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType,
    });

    await _client
        .from('conversations')
        .update({
          'last_message_text': trimmedBody.isNotEmpty
              ? trimmedBody
              : attachmentName.isNotEmpty
              ? attachmentName
              : 'Attachment',
          'last_message_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    final participants = await _client
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', conversationId);
    final notifications = participants
        .map((row) => row['user_id'] as String? ?? '')
        .where((userId) => userId.isNotEmpty && userId != sender.id)
        .map(
          (userId) => {
            'user_id': userId,
            'conversation_id': conversationId,
            'sender_id': sender.id,
            'title': sender.displayName ?? sender.email ?? 'New message',
            'body': trimmedBody.isNotEmpty ? trimmedBody : 'Sent an attachment',
          },
        )
        .toList(growable: false);
    if (notifications.isNotEmpty) {
      await _client.from('chat_notifications').insert(notifications);
    }

    await setTyping(
      conversationId: conversationId,
      currentUserId: sender.id,
      isTyping: false,
    );
  }

  @override
  Future<void> markConversationSeen({
    required String conversationId,
    required String currentUserId,
  }) async {
    await _client
        .from('messages')
        .update({'seen_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .filter('seen_at', 'is', null);
  }

  @override
  Future<void> setTyping({
    required String conversationId,
    required String currentUserId,
    required bool isTyping,
  }) {
    return _client.from('typing_status').upsert({
      'conversation_id': conversationId,
      'user_id': currentUserId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<String> uploadAttachment({
    required String userId,
    required XFile file,
  }) async {
    final nameParts = file.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : 'file';
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final path = '$userId/$timestamp.$extension';

    await _client.storage
        .from('chat-attachments')
        .upload(
          path,
          File(file.path),
          fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
        );
    return _client.storage.from('chat-attachments').getPublicUrl(path);
  }

  Future<List<ConversationSummary>> _loadConversationSummaries(
    String currentUserId,
    List<Map<String, dynamic>> participantRows,
  ) async {
    final conversationIds = participantRows
        .map((row) => row['conversation_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (conversationIds.isEmpty) {
      return const <ConversationSummary>[];
    }

    final conversations = await _client
        .from('conversations')
        .select('id, last_message_text, last_message_at')
        .inFilter('id', conversationIds);
    final allParticipants = await _client
        .from('conversation_participants')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', conversationIds);
    final peerIds = allParticipants
        .map((row) => row['user_id'] as String? ?? '')
        .where((userId) => userId.isNotEmpty && userId != currentUserId)
        .toSet()
        .toList(growable: false);
    final profiles = peerIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('profiles')
              .select(
                'uid, full_name, username, college, department, year_level, profile_picture_url',
              )
              .inFilter('uid', peerIds);
    final unreadRows = await _client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', conversationIds)
        .neq('sender_id', currentUserId)
        .filter('seen_at', 'is', null);
    final typingRows = await _client
        .from('typing_status')
        .select('conversation_id, user_id, is_typing, updated_at')
        .inFilter('conversation_id', conversationIds)
        .neq('user_id', currentUserId);

    final participantsByConversation = <String, List<String>>{};
    for (final row in allParticipants) {
      final conversationId = row['conversation_id'] as String? ?? '';
      final userId = row['user_id'] as String? ?? '';
      participantsByConversation
          .putIfAbsent(conversationId, () => [])
          .add(userId);
    }
    final profilesById = {
      for (final profile in profiles) profile['uid'] as String: profile,
    };
    final unreadByConversation = <String, int>{};
    for (final row in unreadRows) {
      final conversationId = row['conversation_id'] as String? ?? '';
      unreadByConversation[conversationId] =
          (unreadByConversation[conversationId] ?? 0) + 1;
    }
    final now = DateTime.now();
    final typingByConversation = <String>{};
    for (final row in typingRows) {
      final updatedAt = _dateFromValue(row['updated_at']);
      if (row['is_typing'] == true &&
          updatedAt != null &&
          now.difference(updatedAt).inSeconds < 12) {
        typingByConversation.add(row['conversation_id'] as String? ?? '');
      }
    }

    final summaries = conversations.map((conversation) {
      final conversationId = conversation['id'] as String? ?? '';
      final peerId =
          participantsByConversation[conversationId]?.firstWhere(
            (userId) => userId != currentUserId,
            orElse: () => '',
          ) ??
          '';
      final peerProfile = profilesById[peerId] ?? const <String, dynamic>{};

      return ConversationSummary(
        id: conversationId,
        peer: _contactFromProfile(peerProfile, fallbackId: peerId),
        lastMessage: conversation['last_message_text'] as String? ?? '',
        lastMessageAt: _dateFromValue(conversation['last_message_at']),
        unreadCount: unreadByConversation[conversationId] ?? 0,
        isPeerTyping: typingByConversation.contains(conversationId),
      );
    }).toList();
    summaries.sort((a, b) {
      final left = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return summaries;
  }

  Future<List<ChatMessage>> _fetchMessages(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select(
          'id, conversation_id, sender_id, body, attachment_url, attachment_name, attachment_type, seen_at, created_at',
        )
        .eq('conversation_id', conversationId)
        .order('created_at');
    return rows.map(ChatMessage.fromSupabaseMap).toList(growable: false);
  }

  Future<String?> _findExistingConversation(
    String currentUserId,
    String peerId,
  ) async {
    final rows = await _client
        .from('conversation_participants')
        .select('conversation_id, user_id')
        .inFilter('user_id', [currentUserId, peerId]);
    final usersByConversation = <String, Set<String>>{};
    for (final row in rows) {
      final conversationId = row['conversation_id'] as String? ?? '';
      final userId = row['user_id'] as String? ?? '';
      usersByConversation
          .putIfAbsent(conversationId, () => <String>{})
          .add(userId);
    }
    for (final entry in usersByConversation.entries) {
      if (entry.value.contains(currentUserId) && entry.value.contains(peerId)) {
        return entry.key;
      }
    }
    return null;
  }

  ChatContact _contactFromProfile(
    Map<String, dynamic> profile, {
    String fallbackId = '',
  }) {
    final fullName = profile['full_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    final college = profile['college'] as String? ?? '';
    final department = profile['department'] as String? ?? '';
    final yearLevel = profile['year_level'] as String? ?? '';
    return ChatContact(
      id: profile['uid'] as String? ?? fallbackId,
      name: fullName.isNotEmpty
          ? fullName
          : username.isNotEmpty
          ? username
          : 'LNU student',
      detail: [
        college,
        department,
        if (yearLevel.isNotEmpty) 'Year $yearLevel',
      ].where((value) => value.isNotEmpty).join(' - '),
      avatarUrl: profile['profile_picture_url'] as String? ?? '',
    );
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final text = bytes.map(hex).join();
  return '${text.substring(0, 8)}-${text.substring(8, 12)}-'
      '${text.substring(12, 16)}-${text.substring(16, 20)}-'
      '${text.substring(20)}';
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

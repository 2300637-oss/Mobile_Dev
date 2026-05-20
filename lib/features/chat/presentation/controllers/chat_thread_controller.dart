import 'dart:async';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/auth_user.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatThreadController extends ChangeNotifier {
  ChatThreadController({
    required ChatDataSource repository,
    required AuthUser user,
    required this.conversationId,
  }) : _repository = repository,
       _user = user;

  final ChatDataSource _repository;
  final AuthUser _user;
  final String conversationId;
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  Timer? _typingDebounce;

  List<ChatMessage> messages = const [];
  List<String> typingUserIds = const [];
  ChatContact? peer;
  bool isLoading = true;
  bool isSending = false;
  bool isUploading = false;
  String? errorMessage;

  void start() {
    _loadPeer();
    _messagesSubscription = _repository
        .watchMessages(conversationId: conversationId, currentUserId: _user.id)
        .listen(
          (items) {
            messages = [...items]..sort(_compareMessages);
            isLoading = false;
            errorMessage = null;
            notifyListeners();
            markSeen();
          },
          onError: (_) {
            errorMessage = 'Unable to load messages. Please try again.';
            isLoading = false;
            notifyListeners();
          },
        );
    _typingSubscription = _repository
        .watchTypingUsers(
          conversationId: conversationId,
          currentUserId: _user.id,
        )
        .listen((userIds) {
          typingUserIds = userIds;
          notifyListeners();
        });
  }

  Future<void> _loadPeer() async {
    try {
      peer = await _repository.fetchConversationPeer(
        conversationId: conversationId,
        currentUserId: _user.id,
      );
      notifyListeners();
    } catch (_) {
      // The chat can still work without peer metadata.
    }
  }

  Future<void> sendText(String value) async {
    final message = value.trim();
    if (message.isEmpty || isSending) {
      return;
    }

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        sender: _user,
        body: message,
      );
    } catch (_) {
      errorMessage = 'Unable to send message.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> pickAndSendImage() async {
    if (isUploading) {
      return;
    }
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = await _repository.uploadAttachment(
        userId: _user.id,
        file: file,
      );
      await _repository.sendMessage(
        conversationId: conversationId,
        sender: _user,
        body: '',
        attachmentUrl: url,
        attachmentName: file.name,
        attachmentType: 'image',
      );
    } catch (_) {
      errorMessage = 'Unable to send attachment.';
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndSendFile() async {
    if (isUploading) {
      return;
    }
    final file = await file_selector.openFile();
    if (file == null) {
      return;
    }

    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final attachment = XFile(
        file.path,
        name: file.name,
        mimeType: file.mimeType ?? 'application/octet-stream',
      );
      final url = await _repository.uploadAttachment(
        userId: _user.id,
        file: attachment,
      );
      await _repository.sendMessage(
        conversationId: conversationId,
        sender: _user,
        body: '',
        attachmentUrl: url,
        attachmentName: file.name,
        attachmentType: 'file',
      );
    } catch (_) {
      errorMessage = 'Unable to send file.';
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  void updateTyping(String value) {
    _typingDebounce?.cancel();
    _repository.setTyping(
      conversationId: conversationId,
      currentUserId: _user.id,
      isTyping: value.trim().isNotEmpty,
    );
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _repository.setTyping(
        conversationId: conversationId,
        currentUserId: _user.id,
        isTyping: false,
      );
    });
  }

  Future<void> markSeen() {
    return _repository.markConversationSeen(
      conversationId: conversationId,
      currentUserId: _user.id,
    );
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  bool isMine(ChatMessage message) => message.senderId == _user.id;

  int _compareMessages(ChatMessage left, ChatMessage right) {
    final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return leftDate.compareTo(rightDate);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _repository.setTyping(
      conversationId: conversationId,
      currentUserId: _user.id,
      isTyping: false,
    );
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }
}

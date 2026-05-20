import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_user.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatListController extends ChangeNotifier {
  ChatListController({
    required ChatDataSource repository,
    required AuthUser user,
  }) : _repository = repository,
       _user = user;

  final ChatDataSource _repository;
  final AuthUser _user;
  StreamSubscription<List<ConversationSummary>>? _subscription;

  List<ConversationSummary> conversations = const [];
  List<ChatContact> contacts = const [];
  bool isLoading = true;
  bool isStarting = false;
  String? errorMessage;

  void start() {
    _subscription = _repository
        .watchConversations(_user.id)
        .listen(
          (items) {
            conversations = items;
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            errorMessage = 'Unable to load conversations. Please try again.';
            isLoading = false;
            notifyListeners();
          },
        );
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      contacts = await _repository.fetchContacts(_user.id);
      notifyListeners();
    } catch (_) {
      errorMessage = 'Unable to load contacts.';
      notifyListeners();
    }
  }

  Future<String?> startConversation(ChatContact peer) async {
    isStarting = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _repository.startConversation(
        currentUser: _user,
        peer: peer,
      );
    } catch (_) {
      errorMessage = 'Unable to start chat. Please try again.';
      return null;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

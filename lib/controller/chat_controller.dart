import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/socket_service.dart';
import 'package:dama/models/message_model.dart';

class ChatController extends GetxController {
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentConversationId = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isSending = false.obs;

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  int _tempMessageId = 0;

  Future<String> initConversation(
    String user1,
    String user2,
    String token,
  ) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final conversationId = await _apiService.startConversation(user1, user2);
      await initialize(conversationId, token);
      return conversationId;
    } catch (e) {
      errorMessage.value = 'Failed to start conversation: ${e.toString()}';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initialize(String conversationId, String token) async {
    // Clear previous state when switching conversations
    if (currentConversationId.value.isNotEmpty &&
        currentConversationId.value != conversationId) {
      _socketService.leaveConversation(currentConversationId.value);
      _socketService.removeMessageListener();
      messages.clear();
    }

    currentConversationId.value = conversationId;

    try {
      await _socketService.connect(token);
      _socketService.joinConversation(conversationId);
      _socketService.listenForMessages(_handleIncomingMessage);
      await loadMessages();
    } catch (e) {
      errorMessage.value = 'Failed to initialize chat: ${e.toString()}';
    }
  }

  void _handleIncomingMessage(dynamic messageData) {
    try {
      final message = MessageModel.fromJson(messageData);
      if (message.conversationId == currentConversationId.value) {
        // Remove any temporary message with matching content and replace with server message
        messages.removeWhere(
          (m) =>
              m.id.startsWith('temp_') &&
              m.content == message.content &&
              m.senderId == message.senderId,
        );

        // Add if not already present
        if (!messages.any((m) => m.id == message.id)) {
          messages.add(message);
        }
      }
    } catch (e) {
    }
  }

  Future<void> loadMessages() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final loadedMessages = await _apiService.getMessages(
        currentConversationId.value,
      );
      loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      messages.assignAll(loadedMessages);
    } catch (e) {
      errorMessage.value = 'Failed to load messages: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String content, String senderId) async {
    try {
      if (content.trim().isEmpty) return;

      // Create optimistic message for immediate UI feedback
      final tempId = 'temp_${_tempMessageId++}';
      final optimisticMessage = MessageModel(
        id: tempId,
        conversationId: currentConversationId.value,
        senderId: senderId,
        content: content,
        createdAt: DateTime.now(),
      );

      // Add to UI immediately
      messages.add(optimisticMessage);

      final message = {
        'conversationId': currentConversationId.value,
        'senderId': senderId,
        'content': content,
      };

      _socketService.sendMessage(message);
    } catch (e) {
      errorMessage.value = 'Failed to send message: ${e.toString()}';
    }
  }

  void clearChat() {
    messages.clear();
    currentConversationId.value = '';
    errorMessage.value = '';
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      final success = await _apiService.deleteMessage(messageId);
      if (success) {
        messages.removeWhere((m) => m.id == messageId);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to delete message: ${e.toString()}';
      return false;
    }
  }

  Future<void> markAsRead(String userId) async {
    try {
      await _apiService.markMessagesAsRead(currentConversationId.value, userId);
    } catch (e) {
    }
  }

  @override
  void onClose() {
    if (currentConversationId.value.isNotEmpty) {
      _socketService.leaveConversation(currentConversationId.value);
    }
    _socketService.removeMessageListener();
    _socketService.dispose();
    super.onClose();
  }
}

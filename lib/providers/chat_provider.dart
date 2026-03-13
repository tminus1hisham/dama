import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isConnected = false;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;

  void initializeChat(String token) {
    _chatService.initialize(token, onMessageReceived: _handleIncomingMessage);
    _isConnected = true;
    notifyListeners();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Assuming the data is a message object
    final message = Message.fromJson(data);
    _messages.add(message);
    notifyListeners();
  }

  Future<void> loadConversations(String userId) async {
    try {
      final response = await _chatService.getUserConversations(userId);
      if (response['success'] == true) {
        _conversations = List<Conversation>.from(
          (response['conversations'] as List).map(
            (x) => Conversation.fromJson(x),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final response = await _chatService.getMessages(conversationId);
      if (response['success'] == true) {
        _messages = List<Message>.from(
          (response['messages'] as List).map((x) => Message.fromJson(x)),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    _chatService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
    );
  }

  void joinChatRoom(String conversationId) {
    _chatService.joinConversation(conversationId);
  }

  void leaveChatRoom(String conversationId) {
    _chatService.leaveConversation(conversationId);
  }

  void disconnect() {
    _chatService.disconnect();
    _isConnected = false;
    notifyListeners();
  }
}

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

typedef MessageCallback = void Function(Map<String, dynamic> data);

class ChatService {
  static const String _baseUrl = 'http://167.71.68.0:4000/v1/chat';
  static const String _socketUrl = 'http://167.71.68.0:4000';
  
  late IO.Socket socket;
  String? _token;
  MessageCallback? _onMessageReceived;
  
  // Initialize with token
  void initialize(String token, {MessageCallback? onMessageReceived}) {
    _token = token;
    _onMessageReceived = onMessageReceived;
    
    // Setup socket connection
    socket = IO.io(_socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });
    
    setupSocketListeners();
  }
  
  void setupSocketListeners() {
    socket.on('connect', (_) {
      print('Connected to chat server: ${socket.id}');
    });
    
    socket.on('receiveMessage', (data) {
      // Handle incoming messages
      print('New message received: $data');
      if (_onMessageReceived != null) {
        _onMessageReceived!(data);
      }
    });
    
    socket.on('disconnect', (_) => print('Disconnected'));
  }
  
  // Join a conversation room
  void joinConversation(String conversationId) {
    socket.emit('joinConversation', conversationId);
  }
  
  // Leave a conversation room
  void leaveConversation(String conversationId) {
    socket.emit('leaveConversation', conversationId);
  }
  
  // Send a message
  void sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    socket.emit('sendMessage', {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
    });
  }
  
  // REST API Calls
  Future<Map<String, dynamic>> getConversation(String userId1, String userId2) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversation/$userId1/$userId2'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    
    return json.decode(response.body);
  }
  
  Future<Map<String, dynamic>> getUserConversations(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/$userId'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    
    return json.decode(response.body);
  }
  
  Future<Map<String, dynamic>> getMessages(String conversationId, {int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/$conversationId?page=$page&limit=$limit'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    
    return json.decode(response.body);
  }
  
  void disconnect() {
    socket.disconnect();
  }
}
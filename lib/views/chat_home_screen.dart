import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_models.dart';
import '../services/local_storage_service.dart';
import '../widgets/profile_avatar.dart';
import 'chat_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  _ChatHomeScreenState createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final token = await StorageService.getData("access_token");
    _currentUserId = await StorageService.getData("user_id");
    
    if (token != null && _currentUserId != null) {
      chatProvider.initializeChat(token);
      chatProvider.loadConversations(_currentUserId!);
    }
  }
  
  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.conversations.isEmpty) {
            return Center(child: Text('No conversations yet'));
          }
          
          return ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              // Assuming participants include other user
              // For simplicity, assuming first participant is other user
              // In real app, filter out current user
              final otherUserId = conversation.participants.firstWhere(
                (id) => id != _currentUserId,
                orElse: () => '',
              );
              
              return ListTile(
                leading: ProfileAvatar(
                  // Add profile picture if available
                  child: Text(otherUserId.isNotEmpty ? otherUserId[0].toUpperCase() : '?'),
                ),
                title: Text('User $otherUserId'), // Replace with actual name
                subtitle: Text(conversation.lastMessage?.content ?? ''),
                onTap: () {
                  // Create a dummy User object
                  final otherUser = User(
                    id: otherUserId,
                    fullName: 'User $otherUserId', // Replace with actual name
                  );
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        otherUser: otherUser,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
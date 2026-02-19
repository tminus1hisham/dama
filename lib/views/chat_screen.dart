import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_models.dart';
import '../services/local_storage_service.dart';
import '../widgets/profile_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final User otherUser;
  
  const ChatScreen({super.key, required this.conversationId, required this.otherUser});
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    
    _loadCurrentUserId();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Join chat room
    chatProvider.joinChatRoom(widget.conversationId);
    
    // Load messages
    chatProvider.loadMessages(widget.conversationId);
  }
  
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await StorageService.getData("user_id");
    setState(() {});
  }
  
  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.leaveChatRoom(widget.conversationId);
    _messageController.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      content: _messageController.text.trim(),
    );
    
    _messageController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ProfileAvatar(
              backgroundImage: widget.otherUser.profilePicture != null
                  ? NetworkImage(widget.otherUser.profilePicture!)
                  : null,
              child: Text(widget.otherUser.fullName[0].toUpperCase()),
            ),
            SizedBox(width: 10),
            Text(widget.otherUser.fullName),
          ],
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Newest messages at bottom
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[chatProvider.messages.length - 1 - index]; // Reverse for display
                    final isMe = message.senderId == _currentUserId;
                    
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
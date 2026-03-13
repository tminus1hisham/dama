import 'package:dama/controller/chat_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/chat_navigationbar.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String otherUserName;
  final String? otherUserImage;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _chatController;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Always get a fresh controller or find existing one
    if (Get.isRegistered<ChatController>()) {
      _chatController = Get.find<ChatController>();
    } else {
      _chatController = Get.put(ChatController());
    }
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final token = await StorageService.getData('access_token');
    await _chatController.initialize(widget.conversationId, token);
    // Mark messages as read when opening the chat
    await _chatController.markAsRead(widget.currentUserId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _chatController.sendMessage(text, widget.currentUserId);
      _messageController.clear();
      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _showDeleteMessageDialog(String messageId, bool isMe) {
    if (!isMe) return; // Only allow deleting own messages

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await _chatController.deleteMessage(messageId);
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Message deleted',
                    margin: EdgeInsets.only(top: 15, left: 15, right: 15),
                    colorText: kWhite,
                    backgroundColor: kGreen,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to delete message',
                    margin: EdgeInsets.only(top: 15, left: 15, right: 15),
                    colorText: kWhite,
                    backgroundColor: kRed.withOpacity(0.9),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String formatChatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return "${hour.toString().padLeft(2, '0')}:$minute $period";
    } catch (e) {
      return "";
    }
  }

  String formatDateHeader(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(Duration(days: 1));
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return 'Today';
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else if (now.difference(messageDate).inDays < 7) {
        // Show day name for last 7 days
        const days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        return days[dateTime.weekday - 1];
      } else {
        // Show full date
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }
    } catch (e) {
      return "";
    }
  }

  String getDateKey(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime).toLocal();
      return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildDateHeader(String dateText, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? kBlack.withOpacity(0.6) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        children: [
          ChatNavigationAppbar(
            imageUrl: widget.otherUserImage ?? '',
            name: widget.otherUserName,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Obx(() {
                  if (_chatController.isLoading.value) {
                    return Center(child: customSpinner);
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8),
                    itemCount: _chatController.messages.length,
                    itemBuilder: (context, index) {
                      final message = _chatController.messages[index];
                      final isMe = message.senderId == widget.currentUserId;
                      final isTempMessage = message.id.startsWith('temp_');

                      // Check if we need to show a date header
                      bool showDateHeader = false;
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevMessage = _chatController.messages[index - 1];
                        final currentDateKey = getDateKey(
                          '${message.createdAt}',
                        );
                        final prevDateKey = getDateKey(
                          '${prevMessage.createdAt}',
                        );
                        showDateHeader = currentDateKey != prevDateKey;
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            _buildDateHeader(
                              formatDateHeader('${message.createdAt}'),
                              isDarkMode,
                            ),
                          GestureDetector(
                            onLongPress:
                                () =>
                                    _showDeleteMessageDialog(message.id, isMe),
                            child: ChatBubble(
                              clipper: ChatBubbleClipper1(
                                type:
                                    isMe
                                        ? BubbleType.sendBubble
                                        : BubbleType.receiverBubble,
                              ),
                              alignment:
                                  isMe ? Alignment.topRight : Alignment.topLeft,
                              margin: EdgeInsets.symmetric(vertical: 4),
                              backGroundColor: isMe ? Colors.blue : kWhite,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 80),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatChatTime(
                                            '${message.createdAt}',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isMe
                                                    ? Colors.white70
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            isTempMessage
                                                ? Icons.access_time
                                                : Icons.done_all,
                                            size: 12,
                                            color:
                                                isTempMessage
                                                    ? Colors.white54
                                                    : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, bottom: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                          cursorColor: isDarkMode ? kWhite : kBlue,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.send, color: kWhite),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

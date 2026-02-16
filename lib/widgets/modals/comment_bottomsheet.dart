import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentData {
  final String name;
  final String comment;
  final String profileImageUrl;
  final DateTime createdAt;

  CommentData({
    required this.name,
    required this.comment,
    required this.profileImageUrl,
    required this.createdAt,
  });
}

class CommentsBottomSheet extends StatefulWidget {
  final List<CommentData> comments;
  final Function(String) onSendPressed;
  final ScrollController scrollController;
  final bool isLoading;

  const CommentsBottomSheet({
    super.key,
    required this.comments,
    required this.onSendPressed,
    required this.scrollController,
    required this.isLoading,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.comments.isNotEmpty) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendPressed(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  final Utils _utils = Utils();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? kBlack : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              widget.comments.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No comments yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Be the first to comment",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    controller: widget.scrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.comments[index];
                      return ListTile(
                        leading:
                            comment.profileImageUrl.isEmpty
                                ? const CircleAvatar(
                                  backgroundColor: kGrey,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                )
                                : CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    comment.profileImageUrl,
                                  ),
                                ),
                        title: Text(
                          comment.name,
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.comment,
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _utils.timeAgo(comment.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                        cursorColor: isDarkMode ? kWhite : kBlue,
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    widget.isLoading
                        ? const CircularProgressIndicator()
                        : IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _handleSend,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
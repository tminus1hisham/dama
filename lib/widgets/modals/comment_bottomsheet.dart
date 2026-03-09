import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle, title and close button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? kGlassBorder : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Drag handle indicator
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.comments,
                          size: 20,
                          color: kBlue,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.comments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? kGrey.withOpacity(0.3) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDarkMode ? kWhite : kGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Comments list
            Flexible(
              child: widget.comments.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildCommentsList(isDarkMode),
            ),

            // Input field
            _buildInputField(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.commentDots,
                size: 40,
                color: kBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No comments yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to share your thoughts!",
              style: TextStyle(
                fontSize: 14,
                color: kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(bool isDarkMode) {
    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = widget.comments[index];
        return _buildCommentItem(comment, isDarkMode);
      },
    );
  }

  Widget _buildCommentItem(CommentData comment, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ProfileAvatar(
          radius: 20,
          backgroundColor: kBlue.withOpacity(0.2),
          backgroundImage: comment.profileImageUrl.isNotEmpty 
              ? NetworkImage(comment.profileImageUrl) 
              : null,
          child: comment.profileImageUrl.isEmpty
              ? Text(
                  comment.name.isNotEmpty ? comment.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: kBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Comment bubble
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and time
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  Text(
                    _utils.timeAgo(comment.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: kGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Comment text in bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkThemeBg : Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  comment.comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? kWhite.withOpacity(0.9) : kBlack.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? kGlassBorder : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? kDarkThemeBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: 15,
                ),
                cursorColor: kBlue,
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(
                    color: kGrey,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 10),
          widget.isLoading
              ? Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kBlue,
                  ),
                )
              : GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: kWhite,
                      size: 20,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
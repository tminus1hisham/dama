import 'package:dama/controller/conversations_controller.dart';
import 'package:dama/controller/global_search_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/chat/chat_screen.dart';
import 'package:dama/widgets/cards/chat_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/users_chat_topbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChatUsersScreen extends StatefulWidget {
  const ChatUsersScreen({super.key});

  @override
  State<ChatUsersScreen> createState() => _ChatUsersScreenState();
}

class _ChatUsersScreenState extends State<ChatUsersScreen> {
  final ConversationsController _conversationsController = Get.put(
    ConversationsController(),
  );

  int selectedTab = 0;

  final TextEditingController _searchController = TextEditingController();

  String currentUserId = "";
  String profileImageUrl = DEFAULT_IMAGE_URL;

  void _fetchConversations() async {
    final fetchedUserId = await StorageService.getData('userId');
    setState(() {
      currentUserId = fetchedUserId ?? '';
    });

    if (currentUserId.isNotEmpty) {
      await _conversationsController.fetchUserConversations(currentUserId);
    }
  }

  void _updateFilteredList() {
    // Trigger rebuild - the actual filtering now happens in the Obx widget
    setState(() {});
  }

  void _showNewChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => NewChatBottomSheet(
            currentUserId: currentUserId,
            onConversationStarted: () {
              _fetchConversations();
            },
          ),
    );
  }

  Widget _buildPillButton(String text, int index) {
    final bool isSelected = selectedTab == index;
    const selectedColor = Color(0xFF234EC6);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
          _updateFilteredList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isSelected ? Border.all(color: selectedColor) : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? kWhite : kGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateFilteredList);
    _fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        children: [
          UsersChatTopbar(
            searchController: _searchController,
            onSearchChanged: (value) => _updateFilteredList(),
            onNewChatPressed: _showNewChatBottomSheet,
          ),
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildPillButton("All", 0),
                  const SizedBox(width: 12),
                  _buildPillButton("Unread", 1),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Obx(() {
                  // Reactive: rebuild when conversations change
                  final conversations = _conversationsController.conversations;

                  if (_conversationsController.isLoading.value) {
                    return Center(child: customSpinner);
                  }

                  // Simple filtering - show all conversations, apply search only if needed
                  final searchTerm =
                      _searchController.text.toLowerCase().trim();

                  List filtered = conversations.toList();

                  // Apply search filter only if there's a search term
                  if (searchTerm.isNotEmpty) {
                    filtered =
                        filtered.where((conversation) {
                          // Find the other participant (not current user)
                          final otherParticipants = conversation.participants
                              .where((p) => p.id != currentUserId);
                          if (otherParticipants.isEmpty) return false;
                          final otherParticipant = otherParticipants.first;

                          final fullName =
                              "${otherParticipant.firstName} ${otherParticipant.lastName}"
                                  .toLowerCase();
                          return fullName.contains(searchTerm);
                        }).toList();
                  }

                  // Apply tab filter
                  if (selectedTab == 1) {
                    filtered =
                        filtered.where((c) => c.unreadCount > 0).toList();
                  }

                  // Sort by last message time (most recent first)
                  filtered.sort((a, b) {
                    final aTime = a.lastMessage?.createdAt ?? a.createdAt;
                    final bTime = b.lastMessage?.createdAt ?? b.createdAt;
                    return bTime.compareTo(aTime);
                  });

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "No conversations yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? kWhite : kBlack,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Start chatting with other DAMA Kenya members",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showNewChatBottomSheet();
                            },
                            icon: Icon(Icons.chat, size: 20),
                            label: Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: kWhite,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];

                      final otherParticipants =
                          conversation.participants
                              .where((p) => p.id != currentUserId)
                              .toList();
                      final otherUser =
                          otherParticipants.isNotEmpty
                              ? otherParticipants[0]
                              : conversation.participants[0];

                      // Determine the message to display
                      String displayMessage = "Tap to open chat";
                      bool isSentByMe = false;
                      String displayTime = conversation.createdAt;

                      if (conversation.lastMessage != null) {
                        final lastMsg = conversation.lastMessage!;
                        isSentByMe = lastMsg.senderId == currentUserId;
                        displayMessage = lastMsg.content;
                        displayTime = lastMsg.createdAt;

                        // Truncate long messages
                        if (displayMessage.length > 40) {
                          displayMessage =
                              '${displayMessage.substring(0, 40)}...';
                        }
                      }

                      return ChatCard(
                        time: displayTime,
                        profileImageUrl: otherUser.profilePicture,
                        name: "${otherUser.firstName} ${otherUser.lastName}",
                        message: displayMessage,
                        unreadCount: conversation.unreadCount,
                        isSentByMe: isSentByMe,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatScreen(
                                    conversationId: conversation.id,
                                    currentUserId: currentUserId,
                                    otherUserName:
                                        '${otherUser.firstName} ${otherUser.lastName}',
                                    otherUserImage: otherUser.profilePicture,
                                  ),
                            ),
                          ).then((_) {
                            // Refresh conversations when returning from chat
                            _fetchConversations();
                          });
                        },
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewChatBottomSheet extends StatefulWidget {
  final String currentUserId;
  final VoidCallback onConversationStarted;

  const NewChatBottomSheet({
    super.key,
    required this.currentUserId,
    required this.onConversationStarted,
  });

  @override
  State<NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalSearchController _globalSearchController = Get.put(
    GlobalSearchController(),
  );
  final ConversationsController _conversationsController =
      Get.find<ConversationsController>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {
      _globalSearchController.performSearch(_searchController.text);
    } else {
      _globalSearchController.clearSearch();
    }
  }

  Future<void> _startConversation(
    String otherUserId,
    String otherUserName,
    String? otherUserImage,
  ) async {
    setState(() => _isLoading = true);

    try {
      final conversationId = await _conversationsController.startConversation(
        widget.currentUserId,
        otherUserId,
      );

      if (conversationId != null && mounted) {
        Navigator.pop(context); // Close bottom sheet
        widget.onConversationStarted();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  conversationId: conversationId,
                  currentUserId: widget.currentUserId,
                  otherUserName: otherUserName,
                  otherUserImage: otherUserImage,
                ),
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start conversation',
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return SafeArea(
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkThemeBg : kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'New Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ),
            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged:
                    (value) => _globalSearchController.performSearch(value),
                style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                decoration: InputDecoration(
                  hintText: 'Search users by name',
                  hintStyle: TextStyle(color: kGrey),
                  prefixIcon: Icon(Icons.search, color: kGrey),
                  filled: true,
                  fillColor: isDarkMode ? kBlack : kBGColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Results
            Expanded(
              child:
                  _isLoading
                      ? Center(child: customSpinner)
                      : Obx(() {
                        if (_globalSearchController.isLoading.value) {
                          return Center(child: customSpinner);
                        }

                        final searchResults =
                            _globalSearchController.searchResults;
                        final users =
                            (searchResults['users'] as List<dynamic>? ?? [])
                                .where(
                                  (user) => user['_id'] != widget.currentUserId,
                                )
                                .where((user) {
                                  // Exclude users with admin or manager roles
                                  final roles =
                                      user['roles'] as List<dynamic>? ?? [];
                                  return !roles.contains('admin') &&
                                      !roles.contains('manager');
                                })
                                .toList();

                        if (_searchController.text.length < 2) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Search for users to start a chat',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (users.isEmpty) {
                          return Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final firstName = user['firstName'] ?? '';
                            final lastName = user['lastName'] ?? '';
                            final profilePic = user['profile_picture'] ?? '';
                            final userId = user['_id'] ?? '';
                            final fullName = '$firstName $lastName'.trim();

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: kLightGrey,
                                backgroundImage:
                                    profilePic.isNotEmpty
                                        ? NetworkImage(profilePic)
                                        : null,
                                child:
                                    profilePic.isEmpty
                                        ? Icon(Icons.person, color: kGrey)
                                        : null,
                              ),
                              title: Text(
                                fullName,
                                style: TextStyle(
                                  color: isDarkMode ? kWhite : kBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle:
                                  user['title'] != null
                                      ? Text(
                                        user['title'],
                                        style: TextStyle(color: kGrey),
                                      )
                                      : null,
                              trailing: Icon(
                                Icons.chat_bubble_outline,
                                color: kBlue,
                              ),
                              onTap:
                                  () => _startConversation(
                                    userId,
                                    fullName,
                                    profilePic.isNotEmpty ? profilePic : null,
                                  ),
                            );
                          },
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }
}

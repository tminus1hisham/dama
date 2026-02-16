import 'dart:ui';

import 'package:dama/controller/conversations_controller.dart';
import 'package:dama/controller/global_search_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/views/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ChatOverlay extends StatefulWidget {
  final bool isDarkMode;

  const ChatOverlay({super.key, required this.isDarkMode});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final ConversationsController _conversationsController = Get.put(
    ConversationsController(),
  );
  final GlobalSearchController _searchController = Get.put(
    GlobalSearchController(),
  );

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _filteredConversations = [];

  String currentUserId = "";
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _searchTextController.addListener(_onSearchChanged);
    _loadData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadData() async {
    final fetchedUserId = await StorageService.getData('userId');
    if (mounted) {
      setState(() => currentUserId = fetchedUserId ?? '');
      await _conversationsController.fetchUserConversations(currentUserId);
      _updateFilteredLists();
    }
  }

  void _onSearchChanged() {
    _updateFilteredLists();
    if (_selectedTab == 1) {
      if (_searchTextController.text.length >= 2) {
        _searchController.performSearch(_searchTextController.text);
      } else {
        // Clear search results when text is cleared or too short
        _searchController.clearSearch();
      }
    }
    // Update UI for suffix icon visibility without losing focus
    if (mounted) {
      setState(() {});
    }
  }

  void _updateFilteredLists() {
    final searchTerm = _searchTextController.text.toLowerCase();

    // Filter conversations
    final filteredConvos =
        _conversationsController.conversations.where((conversation) {
          final otherParticipants =
              conversation.participants
                  .where((p) => p.id != currentUserId)
                  .toList();
          if (otherParticipants.isEmpty) return false;
          final otherUser = otherParticipants[0];
          final fullName =
              "${otherUser.firstName} ${otherUser.lastName}".toLowerCase();
          return fullName.contains(searchTerm);
        }).toList();

    setState(() {
      _filteredConversations = filteredConvos;
    });
  }

  void _toggleExpanded() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _loadData();
      } else {
        _animationController.reverse();
        _searchFocusNode.unfocus();
        // Clear search state when closing the panel
        _searchTextController.clear();
        _searchController.clearSearch();
        _selectedTab = 0;
      }
    });
  }

  Future<void> _startNewConversation(
    String otherId,
    String name,
    String? image,
  ) async {
    HapticFeedback.lightImpact();

    if (currentUserId.isEmpty) {
      return;
    }

    if (otherId.isEmpty) {
      return;
    }

    final conversationId = await _conversationsController.startConversation(
      currentUserId,
      otherId,
    );

    if (conversationId != null && mounted) {
      Get.to(
        () => ChatScreen(
          conversationId: conversationId,
          currentUserId: currentUserId,
          otherUserName: name,
          otherUserImage: image,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      _toggleExpanded();
    }
  }

  void _openExistingChat(dynamic conversation) {
    HapticFeedback.lightImpact();
    final otherParticipants =
        conversation.participants.where((p) => p.id != currentUserId).toList();

    if (otherParticipants.isNotEmpty) {
      final otherUser = otherParticipants[0];
      Get.to(
        () => ChatScreen(
          conversationId: conversation.id,
          currentUserId: currentUserId,
          otherUserName: "${otherUser.firstName} ${otherUser.lastName}",
          otherUserImage: otherUser.profilePicture,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      _toggleExpanded();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Backdrop blur when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          ),

        // Chat Panel
        if (_isExpanded)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                right: 16,
                bottom: 100 + _slideAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.bottomRight,
                    child: _buildChatPanel(isDarkMode, screenSize),
                  ),
                ),
              );
            },
          ),

        // FAB
        Positioned(right: 20, bottom: 100, child: _buildFAB(isDarkMode)),
      ],
    );
  }

  Widget _buildChatPanel(bool isDarkMode, Size screenSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: screenSize.width * 0.92,
            height: screenSize.height * 0.6,
            constraints: const BoxConstraints(
              maxWidth: 380,
              maxHeight: 550,
              minWidth: 320,
              minHeight: 450,
            ),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? const Color(0xFF1A1A2E).withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildModernHeader(isDarkMode),
                _buildModernSearchBar(isDarkMode),
                _buildModernTabSelector(isDarkMode),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _selectedTab == 0
                            ? _buildConversationsList(isDarkMode)
                            : _buildMembersList(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isExpanded ? 1.0 : _pulseAnimation.value,
          child: GestureDetector(
            onTap: _toggleExpanded,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      _isExpanded
                          ? [kRed, kRed.withOpacity(0.8)]
                          : [kBlue, kBlue.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (_isExpanded ? kRed : kBlue).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  _isExpanded ? Icons.close_rounded : Icons.chat_rounded,
                  key: ValueKey(_isExpanded),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue, kBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connect with DAMA members',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final count = _conversationsController.conversations.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: TextField(
          controller: _searchTextController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText:
                _selectedTab == 0
                    ? 'Search conversations...'
                    : 'Search DAMA members...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: GestureDetector(
              onTap: () {
                if (_searchTextController.text.length >= 2) {
                  HapticFeedback.selectionClick();
                  if (_selectedTab == 1) {
                    _searchController.performSearch(_searchTextController.text);
                  }
                }
              },
              child: Icon(
                Icons.search_rounded,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                size: 22,
              ),
            ),
            suffixIcon:
                _searchTextController.text.isNotEmpty
                    ? GestureDetector(
                      onTap: () {
                        _searchTextController.clear();
                        _searchController.clearSearch();
                        _updateFilteredLists();
                        setState(() {});
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color:
                              isDarkMode
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabSelector(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildModernTabButton(
              'Chats',
              Icons.chat_bubble_outline_rounded,
              0,
              isDarkMode,
            ),
            const SizedBox(width: 6),
            _buildModernTabButton(
              'New Chat',
              Icons.person_add_alt_rounded,
              1,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabButton(
    String text,
    IconData icon,
    int index,
    bool isDarkMode,
  ) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [kBlue, kBlue.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: kBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSelected
                        ? Colors.white
                        : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : (isDarkMode
                              ? Colors.white54
                              : Colors.grey.shade600),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(bool isDarkMode) {
    return Obx(() {
      if (_conversationsController.isLoading.value) {
        return _buildLoadingState(isDarkMode);
      }

      final conversations =
          _searchTextController.text.isEmpty
              ? _conversationsController.conversations
              : _filteredConversations;

      if (conversations.isEmpty) {
        return _buildEmptyState(
          isDarkMode,
          Icons.chat_bubble_outline_rounded,
          'No conversations yet',
          'Start chatting with DAMA members',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final otherParticipants =
              conversation.participants
                  .where((p) => p.id != currentUserId)
                  .toList();

          if (otherParticipants.isEmpty) return const SizedBox.shrink();

          final otherUser = otherParticipants[0];

          return _buildModernChatTile(
            isDarkMode: isDarkMode,
            name: "${otherUser.firstName} ${otherUser.lastName}",
            subtitle: 'Tap to view conversation',
            imageUrl: otherUser.profilePicture,
            onTap: () => _openExistingChat(conversation),
            index: index,
          );
        },
      );
    });
  }

  Widget _buildMembersList(bool isDarkMode) {
    return Obx(() {
      if (_searchController.isLoading.value) {
        return _buildLoadingState(isDarkMode);
      }

      if (_searchTextController.text.length < 2) {
        return _buildSearchPrompt(isDarkMode);
      }

      final searchResults = _searchController.searchResults;
      final users = searchResults['users'] as List<dynamic>? ?? [];

      if (users.isEmpty) {
        return _buildEmptyState(
          isDarkMode,
          Icons.person_search_rounded,
          'No members found',
          'Try a different search term',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final oderId = user['_id'] ?? '';
          final firstName = user['firstName'] ?? '';
          final lastName = user['lastName'] ?? '';
          final profilePic = user['profile_picture'];
          final title = user['title'] ?? 'DAMA Member';

          if (oderId == currentUserId) return const SizedBox.shrink();

          return _buildModernChatTile(
            isDarkMode: isDarkMode,
            name: "$firstName $lastName",
            subtitle: title,
            imageUrl: profilePic,
            showArrow: true,
            onTap:
                () => _startNewConversation(
                  oderId,
                  "$firstName $lastName",
                  profilePic,
                ),
            index: index,
          );
        },
      );
    });
  }

  Widget _buildModernChatTile({
    required bool isDarkMode,
    required String name,
    required String subtitle,
    String? imageUrl,
    bool showArrow = false,
    required VoidCallback onTap,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(name, imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kBlue, kBlue.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient:
            hasImage
                ? null
                : LinearGradient(
                  colors: [kBlue, kBlue.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.circular(14),
        image:
            hasImage
                ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          !hasImage
              ? Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildSearchPrompt(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBlue.withOpacity(0.1), kBlue.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 48,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Find DAMA Members',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by name to start a new conversation',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : kBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: kBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Type at least 2 characters to search',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : kBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDarkMode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
              backgroundColor:
                  isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

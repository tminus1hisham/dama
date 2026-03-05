import 'package:dama/controller/blog_controller.dart';
import 'package:dama/controller/comment_controller.dart';
import 'package:dama/controller/like_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/widgets/cards/blog_card.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/blogs_model.dart';

class Blogs extends StatefulWidget {
  final VoidCallback onMenuTap;

  const Blogs({super.key, required this.onMenuTap});

  @override
  State<Blogs> createState() => _BlogsState();
}

class _BlogsState extends State<Blogs> with AutomaticKeepAliveClientMixin {
  String? imageUrl;
  final BlogController _blogController = Get.put(BlogController());
  final CommentController _commentController = Get.put(CommentController());
  final LikeController _likeController = Get.put(LikeController());

  String comment = '';
  final Utils _utils = Utils();
  void _addComment(String blogID, String commentText) {
    if (commentText.isNotEmpty) {
      _commentController.addComment(blogID, commentText);
      setState(() {
        comment = '';
      });
    } else {
      Get.snackbar('Error', 'Please enter a comment');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    setState(() {
      imageUrl = url;
    });
  }

  void _navigateToBlog(BlogPostModel blog) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => SelectedBlogScreen(
              roles: blog.author?.roles ?? [],
              blogId: blog.id,
              authorId: blog.author?.id ?? '',
              profileImageUrl: blog.author?.profilePicture ?? '',
              title: blog.title,
              imageUrl: blog.imageUrl,
              author: blog.author != null 
                  ? '${blog.author!.firstName} ${blog.author!.lastName}'
                  : 'DAMA KENYA',
              createdAt: blog.createdAt,
              description: blog.description,
              comments: blog.comments,
              sources: blog.sources,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showCommentsBottomSheet(
    BuildContext context, {
    required String blogID,
    required bool isDarkTheme,
    required List<dynamic> initialComments,
  }) {
    if (!_commentController.comments.containsKey(blogID)) {
      _commentController.initializeComments(blogID, initialComments);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final currentComments = _commentController.comments[blogID] ?? [];

              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Material(
                  color: isDarkTheme ? kDarkThemeBg : kWhite,
                  child: CommentsBottomSheet(
                    comments: currentComments,
                    isLoading: _commentController.isLoading.value,
                    onSendPressed: (String newComment) {
                      _addComment(blogID, newComment);
                    },
                    scrollController: scrollController,
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  // Format category name for display (e.g., "ENTERTAINMENT" -> "Entertainment")
  String _formatCategoryName(String category) {
    if (category.isEmpty) return 'Uncategorized';
    if (category.toLowerCase() == 'all blogs') return 'All Blogs';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  /// Build a compact trending blog card
  Widget _buildTrendingCard(BlogPostModel blog, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _navigateToBlog(blog),
      child: Container(
        width: 150,
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1a1f2e) : kWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blog image with gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 75,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _utils.cleanUrl(blog.imageUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                            child: Icon(Icons.image, size: 24, color: kGrey),
                          ),
                    ),
                    // Subtle gradient for better text visibility below
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDarkMode ? Color(0xFF1a1f2e) : kWhite)
                                  .withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                blog.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    super.build(context);
    return Container(
      color: isDarkMode ? kDarkThemeBg : kBGColor,
      child: Column(
        children: [
          // Horizontal Category Filter
          Obx(() {
            if (_blogController.categories.isEmpty) {
              return SizedBox.shrink();
            }

            final currentSelectedCategory =
                _blogController.selectedCategory.value;

            return Container(
              color: isDarkMode ? kBlack : kWhite,
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 10),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _blogController.categories.length,
                      itemBuilder: (context, index) {
                        final category = _blogController.categories[index];
                        final isSelected = currentSelectedCategory == category;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _blogController.selectCategory(category);
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            key: ValueKey('${category}_$isSelected'),
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? kBlue
                                      : (isDarkMode
                                          ? Color(0xFF1a1f2e)
                                          : kWhite),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? kBlue
                                        : (isDarkMode
                                            ? Color(0xFF2a3040)
                                            : kLightGrey),
                                width: 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: kBlue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCategoryName(category),
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? kWhite
                                            : (isDarkMode ? kWhite : kBlack),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),

          // Divider
          Container(height: 8, color: isDarkMode ? kDarkThemeBg : kBGColor),

          // Trending Blogs Section
          Obx(() {
            if (_blogController.trendingBlogs.isEmpty) {
              return SizedBox.shrink();
            }
            return Container(
              color: isDarkMode ? kBlack : kWhite,
              padding: EdgeInsets.only(bottom: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('🔥', style: TextStyle(fontSize: 14)),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Trending Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _blogController.trendingBlogs.length,
                      itemBuilder: (context, index) {
                        final blog = _blogController.trendingBlogs[index];
                        return _buildTrendingCard(blog, isDarkMode);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),

          // Divider before blog list
          Container(height: 8, color: isDarkMode ? kDarkThemeBg : kBGColor),

          // Blog List
          Expanded(
            child: RefreshIndicator(
              color: kWhite,
              backgroundColor: kBlue,
              displacement: 40,
              onRefresh: () => _blogController.refreshBlogs(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: PagedListView<int, BlogPostModel>(
                    pagingController: _blogController.pagingController,
                    padding: EdgeInsets.only(top: 4, bottom: 20),
                    builderDelegate: PagedChildBuilderDelegate<BlogPostModel>(
                      itemBuilder: (context, blog, index) {
                        final blogID = blog.id;

                        // Initialize like status if not already done
                        if (!_likeController.likedStatus.containsKey(blogID)) {
                          _likeController.initializeLikeStatus(
                            blogID,
                            blog.likes,
                          );
                        }

                        return KeyedSubtree(
                          key: ValueKey('blog_$blogID'),
                          child: Obx(() {
                          final isLiked =
                              _likeController.likedStatus[blogID] ?? false;
                          final likeCount =
                              _likeController.likeCount[blogID] ??
                              blog.likes.length;

                          final commentCount =
                              _commentController.comments[blog.id]?.length ??
                              blog.comments.length;

                          return blogCard(
                            category: blog.category ?? '',
                            roles: blog.author?.roles ?? [],
                            onProfileClicked: () {
                              if (blog.author == null) return;
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => OtherUserProfile(
                                        userID: blog.author!.id,
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 200,
                                  ),
                                ),
                              );
                            },
                            isLiked: isLiked,
                            likes: likeCount.toString(),
                            commentNumber: '$commentCount',
                            onPressed: () => _navigateToBlog(blog),
                            profileImageUrl: blog.author?.profilePicture ?? '',
                            fullName: blog.author != null
                                ? '${blog.author!.firstName} ${blog.author!.lastName}'
                                : 'DAMA KENYA',
                            blog: blog.description,
                            heading: blog.title,
                            imageUrl: _utils.cleanUrl(blog.imageUrl),
                            time: _utils.timeAgo(blog.createdAt),
                            title: blog.status,
                            onCommentsPressed: () {
                              _showCommentsBottomSheet(
                                context,
                                isDarkTheme: isDarkMode,
                                blogID: blog.id,
                                initialComments: blog.comments,
                              );
                            },
                            onLikePressed:
                                () => _likeController.toggleLike(blog.id),
                            onSharePressed: () {
                              final link =
                                  'https://mydama.damakenya.org/blog/${blog.id}';
                              Share.share(
                                'Check out this blog on Dama Kenya: ${blog.title}\n$link',
                                subject: 'Dama Kenya',
                              );
                            },
                          );
                        }),
                        );
                      },
                    ),
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
  bool get wantKeepAlive => true;
}

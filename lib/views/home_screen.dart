import 'package:dama/controller/comment_controller.dart';
import 'package:dama/controller/feed_controller.dart';
import 'package:dama/controller/like_controller.dart';
import 'package:dama/controller/news_comment_contoller.dart';
import 'package:dama/controller/news_like_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/widgets/cards/blog_card.dart';
import 'package:dama/widgets/cards/news_card.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/theme_provider.dart';
import '../widgets/shimmer/blog_card_shimmer.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const HomeScreen({super.key, required this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  String? imageUrl;
  final CommentController _commentController = Get.put(CommentController());
  final FeedController _feedController = Get.put(FeedController());
  final LikeController _likeController = Get.put(LikeController());

  final NewsCommentController _newsCommentController = Get.put(
    NewsCommentController(),
  );
  final NewsLikeController _newsLikeController = Get.put(NewsLikeController());

  final Utils _utils = Utils();
  String comment = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    setState(() {
      imageUrl = url;
    });
  }

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

  void _addNewsComment(String newsID, String commentText) {
    if (commentText.isNotEmpty) {
      _newsCommentController.addComment(newsID, commentText);
      setState(() {
        comment = '';
      });
    } else {
      Get.snackbar('Error', 'Please enter a comment');
    }
  }

  void _showCommentsBottomSheet(
    BuildContext context, {
    required String blogID,
    required List<dynamic> initialComments,
    required bool isDarkMode,
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
                  color: isDarkMode ? kDarkThemeBg : kWhite,
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

  void _showNewsCommentsBottomSheet(
    BuildContext context, {
    required String newsID,
    required List<dynamic> initialComments,
    required bool isDarkMode,
  }) {
    if (!_newsCommentController.comments.containsKey(newsID)) {
      _newsCommentController.initializeComments(newsID, initialComments);
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
              final currentComments =
                  _newsCommentController.comments[newsID] ?? [];

              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Material(
                  color: isDarkMode ? kDarkThemeBg : kWhite,
                  child: CommentsBottomSheet(
                    comments: currentComments,
                    isLoading: _newsCommentController.isLoading.value,
                    onSendPressed: (String newComment) {
                      _addNewsComment(newsID, newComment);
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

  // Helper method to determine if an item is a blog or news
  bool _isBlogItem(dynamic item) {
    // Check the runtime type first (most reliable)
    final typeName = item.runtimeType.toString();
    if (typeName.contains('BlogPost') || typeName.contains('Blog')) {
      return true;
    }
    if (typeName.contains('News')) {
      return false;
    }

    try {
      final status = item.status;
      return status != null;
    } catch (e) {
      return false;
    }
  }

  Widget _buildFeedItem(dynamic item, bool isDarkMode) {
    if (_isBlogItem(item)) {
      return _buildBlogCard(item, isDarkMode);
    } else {
      return _buildNewsCard(item, isDarkMode);
    }
  }

  Widget _buildBlogCard(dynamic blog, bool isDarkMode) {
    if (!_likeController.likedStatus.containsKey(blog.id)) {
      _likeController.initializeLikeStatus(blog.id, blog.likes);
    }

    return Obx(() {
      final isLiked = _likeController.likedStatus[blog.id] ?? false;
      final likeCount = _likeController.likeCount[blog.id] ?? blog.likes.length;
      final commentCount =
          _commentController.comments[blog.id]?.length ?? blog.comments.length;

      return blogCard(
        category: blog.category ?? '',
        roles: blog.author?.roles ?? [],
        onProfileClicked: () {
          if (blog.author == null) {
            debugPrint('[HomeScreen] Cannot navigate - blog author is null');
            return;
          }
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      OtherUserProfile(userID: blog.author!.id),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        isLiked: isLiked,
        likes: likeCount.toString(),
        commentNumber: '$commentCount',
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (
                    context,
                    animation,
                    secondaryAnimation,
                  ) => SelectedBlogScreen(
                    roles: blog.author?.roles ?? [],
                    comments: blog.comments ?? [],
                    blogId: blog.id,
                    authorId: blog.author?.id ?? '',
                    profileImageUrl: blog.author?.profilePicture ?? '',
                    title: blog.title,
                    imageUrl: blog.imageUrl,
                    author:
                        '${blog.author?.firstName ?? ''} ${blog.author?.lastName ?? ''}',
                    createdAt: blog.createdAt,
                    description: blog.description,
                    sources: blog.sources,
                  ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        profileImageUrl: blog.author?.profilePicture ?? '',
        fullName:
            '${blog.author?.firstName ?? ''} ${blog.author?.lastName ?? ''}',
        blog: blog.description,
        heading: blog.title,
        imageUrl: blog.imageUrl,
        time: _utils.timeAgo(blog.createdAt),
        title: blog.status ?? '',
        onCommentsPressed: () {
          _showCommentsBottomSheet(
            context,
            blogID: blog.id,
            initialComments: blog.comments ?? [],
            isDarkMode: isDarkMode,
          );
        },
        onLikePressed: () => _likeController.toggleLike(blog.id),
        onSharePressed: () {
          final link = 'https://mydama.damakenya.org/blog/${blog.id}';
          Share.share(
            'Check out this blog on Dama Kenya: ${blog.title}\n$link',
            subject: 'Dama Kenya',
          );
        },
      );
    });
  }

  Widget _buildNewsCard(dynamic newsItem, bool isDarkMode) {
    if (!_newsLikeController.likedStatus.containsKey(newsItem.id)) {
      _newsLikeController.initializeLikeStatus(newsItem.id, newsItem.likes);
    }

    return Obx(() {
      final isLiked = _newsLikeController.likedStatus[newsItem.id] ?? false;
      final likeCount =
          _newsLikeController.likeCount[newsItem.id] ?? newsItem.likes.length;
      final commentCount =
          _newsCommentController.comments[newsItem.id]?.length ??
          newsItem.comments.length;

      return NewsCard(
        category: newsItem.category ?? '',
        roles: newsItem.author?.roles ?? [],
        onProfileClicked: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      OtherUserProfile(userID: newsItem.author!.id),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        isLiked: isLiked,
        likes: likeCount.toString(),
        commentNumber: '$commentCount',
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (
                    context,
                    animation,
                    secondaryAnimation,
                  ) => SelectedNewsScreen(
                    roles: newsItem.author?.roles ?? [],
                    comments: newsItem.comments ?? [],
                    newsId: newsItem.id,
                    authorID: newsItem.author?.id ?? '',
                    profileImageUrl: newsItem.author?.profilePicture ?? '',
                    title: newsItem.title,
                    imageUrl: newsItem.imageUrl,
                    author:
                        '${newsItem.author?.firstName ?? ''} ${newsItem.author?.lastName ?? ''}',
                    createdAt: _utils.timeAgo(newsItem.createdAt),
                    description: newsItem.description,
                    sources: newsItem.sources,
                  ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        profileImageUrl: newsItem.author?.profilePicture ?? '',
        fullName:
            '${newsItem.author?.firstName ?? ''} ${newsItem.author?.lastName ?? ''}',
        heading: newsItem.title,
        description: newsItem.description,
        imageUrl: newsItem.imageUrl,
        time: _utils.timeAgo(newsItem.createdAt),
        onCommentsPressed: () {
          _showNewsCommentsBottomSheet(
            context,
            newsID: newsItem.id,
            initialComments: newsItem.comments ?? [],
            isDarkMode: isDarkMode,
          );
        },
        onLikePressed: () => _newsLikeController.toggleLike(newsItem.id),
        onSharePressed: () {
          final link = 'https://mydama.damakenya.org/news/${newsItem.id}';
          Share.share(
            'Checkout this news article on Dama kenya: ${newsItem.title}\n$link',
            subject: 'Dama Kenya',
          );
        },
      );
    });
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
          Expanded(
            child: RefreshIndicator(
              color: kWhite,
              backgroundColor: kBlue,
              displacement: 40,
              onRefresh: () async {
                _feedController.pagingController.refresh();
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: PagedListView<int, dynamic>(
                    pagingController: _feedController.pagingController,
                    padding: EdgeInsets.zero,
                    builderDelegate: PagedChildBuilderDelegate<dynamic>(
                      itemBuilder: (context, item, index) {
                        return _buildFeedItem(item, isDarkMode);
                      },
                      firstPageProgressIndicatorBuilder:
                          (context) => Column(
                            children: List.generate(
                              3,
                              (index) => BlogCardSkeleton(),
                            ),
                          ),
                      newPageProgressIndicatorBuilder:
                          (context) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kBlue,
                                ),
                              ),
                            ),
                          ),
                      noItemsFoundIndicatorBuilder:
                          (context) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.newspaper_rounded,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No feeds available",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "The feeds will appear here",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      firstPageErrorIndicatorBuilder:
                          (context) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Something went wrong",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed:
                                      () =>
                                          _feedController.pagingController
                                              .refresh(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kBlue,
                                    foregroundColor: kWhite,
                                  ),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                      newPageErrorIndicatorBuilder:
                          (context) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Failed to load more items',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  TextButton(
                                    onPressed:
                                        () =>
                                            _feedController.pagingController
                                                .retryLastFailedRequest(),
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(color: kBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

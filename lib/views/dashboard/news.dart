import 'package:dama/controller/news_comment_contoller.dart';
import 'package:dama/controller/news_controller.dart';
import 'package:dama/controller/news_like_controller.dart';
import 'package:dama/models/news_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/widgets/cards/news_card.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class News extends StatefulWidget {
  final VoidCallback onMenuTap;

  const News({super.key, required this.onMenuTap});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> with AutomaticKeepAliveClientMixin {
  String _formatCategoryName(String category) {
    if (category.toLowerCase() == 'all news') return 'All News';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? imageUrl;
  final NewsController _newsController = Get.put(NewsController());
  final NewsCommentController _commentController = Get.put(
    NewsCommentController(),
  );
  final NewsLikeController _likeController = Get.put(NewsLikeController());
  // Removed unused _fabKey

  String comment = '';
  final Utils _utils = Utils();

  void _addComment(String newsID, String commentText) {
    if (commentText.isNotEmpty) {
      _commentController.addComment(newsID, commentText);
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
    // Only refresh if no data exists yet
    if (_newsController.filteredNews.isEmpty) {
      _newsController.refreshNews();
    }
    // Trending news is now computed automatically in the controller
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    setState(() {
      imageUrl = url;
    });
  }

  void _showCommentsBottomSheet(
    BuildContext context, {
    required String newsID,
    required bool isDarkTheme,
    required List<dynamic> initialComments,
  }) {
    if (!_commentController.comments.containsKey(newsID)) {
      _commentController.initializeComments(newsID, initialComments);
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
              final currentComments = _commentController.comments[newsID] ?? [];

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
                      _addComment(newsID, newComment);
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

  /// Build a compact popular news card
  Widget _buildPopularCard(NewsModel news, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => SelectedNewsScreen(
                  roles: news.author.roles,
                  newsId: news.id,
                  authorID: news.author.id,
                  profileImageUrl: news.author.profilePicture,
                  title: news.title,
                  imageUrl: news.imageUrl,
                  author: '${news.author.firstName} ${news.author.lastName}',
                  createdAt: _utils.timeAgo(news.createdAt),
                  description: news.description,
                  comments: news.comments,
                  sources: news.sources,
                  likes: news.likes,
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
            // News image with gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 75,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      news.imageUrl,
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
                news.title,
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
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    return Container(
      color: isDarkMode ? kDarkThemeBg : kBGColor,
      child: Column(
        children: [
          // Category filter above news list
          Obx(() {
            // Show loading indicator when fetching categories
            if (_newsController.isLoadingCategories.value &&
                _newsController.categories.isEmpty) {
              return Container(
                color: isDarkMode ? kBlack : kWhite,
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBlue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Loading categories...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show placeholder if no categories
            if (_newsController.categories.isEmpty) {
              return SizedBox.shrink();
            }

            final currentSelectedCategory =
                _newsController.selectedCategory.value;
            return Container(
              color: isDarkMode ? kBlack : kWhite,
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title (no search)
                  Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 10),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? kWhite : kBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Category chips with counts
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _newsController.categories.length,
                      itemBuilder: (context, index) {
                        final category = _newsController.categories[index];
                        final isSelected = currentSelectedCategory == category;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _newsController.selectCategory(category);
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            key: ValueKey('${category}_$isSelected'),
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            clipBehavior: Clip.antiAlias,
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
                                    fontSize: 11,
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
          // Popular News Section
          Obx(() {
            final filteredPopular = _newsController.filteredPopularNews;
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
                            color: kRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('🔥', style: TextStyle(fontSize: 14)),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Popular News',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  filteredPopular.isEmpty
                      ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No popular news available yet.',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? kWhite.withOpacity(0.7)
                                    : kBlack.withOpacity(0.7),
                          ),
                        ),
                      )
                      : SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 12, right: 4),
                          itemCount: filteredPopular.length,
                          itemBuilder: (context, index) {
                            final news = filteredPopular[index];
                            return _buildPopularCard(news, isDarkMode);
                          },
                        ),
                      ),
                ],
              ),
            );
          }),
          Expanded(
            child: RefreshIndicator(
              color: kWhite,
              backgroundColor: kBlue,
              displacement: 40,
              onRefresh: () => _newsController.refreshNews(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: Obx(() {
                    final filteredNews = _newsController.filteredNews;

                    // Show loading indicator when fetching news
                    if (_newsController.isLoadingNews.value &&
                        filteredNews.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: kBlue),
                            SizedBox(height: 16),
                            Text(
                              "Loading news...",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (filteredNews.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.newspaper,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No news available",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "The news will appear here",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredNews.length,
                      itemBuilder: (context, index) {
                        final news = filteredNews[index];
                        final newsID = news.id;
                        if (!_likeController.likedStatus.containsKey(newsID)) {
                          _likeController.initializeLikeStatus(
                            newsID,
                            news.likes,
                          );
                        }
                        return Obx(() {
                          final isLiked =
                              _likeController.likedStatus[newsID] ?? false;
                          final likeCount =
                              _likeController.likeCount[newsID] ??
                              news.likes.length;
                          final commentCount =
                              _commentController.comments[news.id]?.length ??
                              news.comments.length;
                          return NewsCard(
                            category: news.category ?? '',
                            roles: news.author.roles,
                            onProfileClicked: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => OtherUserProfile(
                                        userID: news.author.id,
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
                                        roles: news.author.roles,
                                        newsId: news.id,
                                        authorID: news.author.id,
                                        profileImageUrl:
                                            news.author.profilePicture,
                                        title: news.title,
                                        imageUrl: news.imageUrl,
                                        author:
                                            '${news.author.firstName} ${news.author.lastName}',
                                        createdAt: _utils.timeAgo(
                                          news.createdAt,
                                        ),
                                        description: news.description,
                                        comments: news.comments,
                                        sources: news.sources,
                                        likes: news.likes,
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
                            profileImageUrl: news.author.profilePicture,
                            fullName:
                                '${news.author.firstName} ${news.author.lastName}',
                            heading: news.title,
                            description: news.description,
                            imageUrl: news.imageUrl,
                            time: _utils.timeAgo(news.createdAt),
                            onCommentsPressed: () {
                              _showCommentsBottomSheet(
                                context,
                                isDarkTheme: isDarkMode,
                                newsID: news.id,
                                initialComments: news.comments,
                              );
                            },
                            onLikePressed:
                                () => _likeController.toggleLike(news.id),
                            onSharePressed: () {
                              final link =
                                  'https://mydama.damakenya.org/news/${news.id}';
                              Share.share(
                                'Checkout this news article on Dama kenya: ${news.title}\n$link',
                                subject: 'Dama Kenya',
                              );
                            },
                          );
                        });
                      },
                    );
                  }),
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

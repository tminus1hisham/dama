import 'package:dama/controller/article_count_controller.dart';
import 'package:dama/controller/fetchUserProfile.dart';
import 'package:dama/controller/news_comment_contoller.dart';
import 'package:dama/controller/news_like_controller.dart';
import 'package:flutter/services.dart';
import 'package:dama/models/blogs_model.dart' show SourceReference;
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/sources_references_section.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectedNewsScreen extends StatefulWidget {
  const SelectedNewsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.createdAt,
    required this.description,
    required this.profileImageUrl,
    this.userId = '',
    required this.authorID,
    required this.newsId,
    required this.comments,
    required this.roles,
    this.sources = const [],
    this.likes = const [],
  });

  final String title;
  final String authorID;
  final String imageUrl;
  final String author;
  final String description;
  final String createdAt;
  final String userId;
  final String profileImageUrl;
  final String newsId;
  final List<dynamic> comments;
  final List roles;
  final List<SourceReference> sources;
  final List<dynamic> likes;

  @override
  State<SelectedNewsScreen> createState() => _SelectedNewsScreenState();
}

class _SelectedNewsScreenState extends State<SelectedNewsScreen> {
  final FetchUserProfileController _fetchUserProfileController = Get.put(
    FetchUserProfileController(),
  );

  String news = '';
  bool _isScrollingBlocked = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  final NewsCommentController _commentController = Get.put(
    NewsCommentController(),
  );

  final NewsLikeController _likeController = Get.put(
    NewsLikeController(),
  );

  final ArticleCountController _articleCountController = Get.put(
    ArticleCountController(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _fetchUserProfileController.fetchUserProfile(widget.userId);
    }
    // _checkArticleLimit();
    _loadData();
    // Only initialize if not already tracked to preserve state from list view
    if (!_likeController.likedStatus.containsKey(widget.newsId)) {
      _likeController.initializeLikeStatus(widget.newsId, widget.likes);
    }
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');

    setState(() {
      imageUrl = url;
      firstName = fetchedFirstName;
      memberId = fetchedMemberId;
      lastName = fetchedLastName;
      title = fetchedTitle;
      bio = fetchedBio ?? '';
    });
  }

  Future<void> _checkArticleLimit() async {
    try {
      bool canRead =
          await _articleCountController.checkArticleLimitBeforeReading();
      if (!canRead) {
        setState(() {
          _isScrollingBlocked = true;
        });
        // Show bottom sheet immediately after setting the state
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   _showSubscriptionBottomSheet();
        // });
      }
    } catch (e) {
      // If there's an error, allow reading (fail gracefully)
      print('Error checking article limit: $e');
    }
  }

  void _addComment(String blogID, String commentText) {
    // if (_isScrollingBlocked) {
    //   _showSubscriptionBottomSheet();
    //   return;
    // }

    if (commentText.isNotEmpty) {
      _commentController.addComment(blogID, commentText);
      setState(() {
        news = '';
      });
    } else {
      Get.snackbar('Error', 'Please enter a comment');
    }
  }

  void _showCommentsBottomSheet(
    BuildContext context, {
    required String newsId,
    required bool isDarkTheme,
    required List<dynamic> initialComments,
  }) {
    // if (_isScrollingBlocked) {
    //   _showSubscriptionBottomSheet();
    //   return;
    // }

    if (!_commentController.comments.containsKey(newsId)) {
      _commentController.initializeComments(newsId, initialComments);
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
              final currentComments = _commentController.comments[newsId] ?? [];

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
                      _addComment(newsId, newComment);
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

  // void _showSubscriptionBottomSheet() {
  //   SubscriptionBottomSheet.show(
  //     context: context,
  //     title: 'Premium Content Locked',
  //     subtitle:
  //         'You\'ve reached your news article limit. Upgrade to continue reading unlimited news and access exclusive content.',
  //     onUpgrade: () {
  //       Navigator.pop(context);
  //       Navigator.pop(context);
  //       Navigator.pushNamed(context, AppRoutes.plans);
  //     },
  //     onDismiss: () {
  //       Navigator.pop(context);
  //       Navigator.pop(context);
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    bool isAdminOrManager =
        widget.roles.contains('admin') || widget.roles.contains('manager');

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        children: [
          TopNavigationbar(title: widget.title),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1500),
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kIsWeb)
                        ProfileCard(
                          isDarkMode: isDarkMode,
                          imageUrl: imageUrl,
                          firstName: firstName,
                          lastName: lastName,
                          title: title,
                          bio: bio,
                        ),
                      if (kIsWeb) SizedBox(width: 10),
                      Expanded(
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: ListView(
                            children: [
                              Center(
                                child: Container(
                                  color: isDarkMode ? kBlack : kWhite,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 250,
                                        color: Colors.grey[200],
                                        child:
                                            (widget.imageUrl.isNotEmpty &&
                                                    Uri.tryParse(
                                                          widget.imageUrl,
                                                        )?.hasAbsolutePath ==
                                                        true)
                                                ? Image.network(
                                                  widget.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                )
                                                : const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSidePadding,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                ProfileAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      kLightGrey,
                                                  backgroundImage:
                                                      kDamaLogo,
                                                  child: null,
                                                  borderColor: Colors.transparent,
                                                  borderWidth: 0,
                                                ),
                                                SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      "DAMA KENYA",
                                                      style: TextStyle(
                                                        color:
                                                            isDarkMode
                                                                ? kWhite
                                                                : kBlack,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: kTitleTextSize,
                                                      ),
                                                    ),
                                                    Text(
                                                      widget.createdAt,
                                                      style: TextStyle(
                                                        color: kGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSidePadding,
                                          vertical: 10,
                                        ),
                                        child: Container(
                                          color:
                                              isDarkMode
                                                  ? kDarkThemeBg
                                                  : kBGColor,
                                          height: 2,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSidePadding,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          widget.title,
                                          style: TextStyle(
                                            fontSize: kLargeHeaderSize,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? kWhite : kBlack,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSidePadding,
                                        ),
                                        child: Html(
                                          data: widget.description,
                                          style: {
                                            "html": Style(
                                              fontSize: FontSize(16.0),
                                              backgroundColor:
                                                  isDarkMode ? kBlack : kWhite,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.justify,
                                              margin: Margins.zero,
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "*": Style(
                                              fontSize: FontSize(16.0),
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              backgroundColor:
                                                  isDarkMode ? kBlack : kWhite,
                                              textAlign: TextAlign.justify,
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "h1": Style(
                                              fontSize: FontSize(24.0),
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.left,
                                              margin: Margins.only(
                                                top: 20,
                                                bottom: 12,
                                              ),
                                            ),
                                            "h2": Style(
                                              fontSize: FontSize(20.0),
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.left,
                                              margin: Margins.only(
                                                top: 18,
                                                bottom: 10,
                                              ),
                                            ),
                                            "h3": Style(
                                              fontSize: FontSize(18.0),
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.left,
                                              margin: Margins.only(
                                                top: 16,
                                                bottom: 8,
                                              ),
                                            ),
                                            "p": Style(
                                              fontSize: FontSize(16.0),
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.justify,
                                              margin: Margins.only(
                                                bottom: 16,
                                              ),
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "strong": Style(
                                              fontSize: FontSize(16.0),
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.justify,
                                            ),
                                            "em": Style(
                                              fontSize: FontSize(16.0),
                                              fontStyle: FontStyle.italic,
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.justify,
                                            ),
                                            "li": Style(
                                              fontSize: FontSize(16.0),
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              textAlign: TextAlign.justify,
                                              margin: Margins.only(
                                                bottom: 8,
                                              ),
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "ul": Style(
                                              margin: Margins.only(
                                                bottom: 16,
                                              ),
                                            ),
                                            "ol": Style(
                                              margin: Margins.only(
                                                bottom: 16,
                                              ),
                                            ),
                                            "blockquote": Style(
                                              fontSize: FontSize(16.0),
                                              fontStyle: FontStyle.italic,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                              margin: Margins.only(
                                                top: 16,
                                                bottom: 16,
                                                left: 16,
                                              ),
                                              padding: HtmlPaddings.only(
                                                left: 12,
                                              ),
                                              border: Border(
                                                left: BorderSide(
                                                  color: isDarkMode
                                                      ? Colors.grey[700]!
                                                      : Colors.grey[300]!,
                                                  width: 3,
                                                ),
                                              ),
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "body": Style(
                                              fontSize: FontSize(16.0),
                                              backgroundColor:
                                                  isDarkMode ? kBlack : kWhite,
                                              textAlign: TextAlign.justify,
                                              margin: Margins.zero,
                                              lineHeight: LineHeight(1.4),
                                            ),
                                            "br": Style(
                                              margin: Margins.zero,
                                              padding: HtmlPaddings.zero,
                                              display: Display.inline,
                                            ),
                                            "div": Style(
                                              margin: Margins.only(bottom: 12),
                                            ),
                                          },
                                        ),
                                      ),
                                      // Sources & References section
                                      if (widget.sources.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: kSidePadding,
                                          ),
                                          child: SourcesReferencesSection(
                                            sources: widget.sources,
                                            isDarkMode: isDarkMode,
                                          ),
                                        ),
                                      
                                      // Interaction Section (Like, Comment, Share)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSidePadding,
                                          vertical: 16,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? kDarkCard : kLightGrey,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Obx(() {
                                            final isLiked = _likeController.likedStatus[widget.newsId] ?? false;
                                            final likeCount = _likeController.likeCount[widget.newsId] ?? widget.likes.length;
                                            final commentCount = _commentController.comments[widget.newsId]?.length ?? widget.comments.length;
                                            
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                // Like Button
                                                _buildInteractionButton(
                                                  icon: isLiked ? FontAwesomeIcons.solidThumbsUp : FontAwesomeIcons.thumbsUp,
                                                  label: '$likeCount',
                                                  color: isLiked ? kBlue : (isDarkMode ? kWhite : kGrey),
                                                  onTap: () => _likeController.toggleLike(widget.newsId),
                                                ),
                                                // Comment Button
                                                _buildInteractionButton(
                                                  icon: FontAwesomeIcons.comment,
                                                  label: '$commentCount',
                                                  color: isDarkMode ? kWhite : kGrey,
                                                  onTap: () {
                                                    _showCommentsBottomSheet(
                                                      context,
                                                      isDarkTheme: isDarkMode,
                                                      newsId: widget.newsId,
                                                      initialComments: widget.comments,
                                                    );
                                                  },
                                                ),
                                                // Share Button
                                                _buildInteractionButton(
                                                  icon: Icons.share,
                                                  label: 'Share',
                                                  color: isDarkMode ? kWhite : kGrey,
                                                  onTap: () {
                                                    final link = 'https://mydama.damakenya.org/news/${widget.newsId}';
                                                    Clipboard.setData(ClipboardData(text: link));
                                                    Get.snackbar(
                                                      'Link Copied',
                                                      'News link copied to clipboard',
                                                      snackPosition: SnackPosition.BOTTOM,
                                                      margin: EdgeInsets.all(15),
                                                      backgroundColor: isDarkMode ? kDarkCard : kWhite,
                                                      colorText: isDarkMode ? kWhite : kBlack,
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: kNormalTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
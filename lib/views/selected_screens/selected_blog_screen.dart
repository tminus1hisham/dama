import 'package:dama/controller/article_count_controller.dart';
import 'package:dama/controller/comment_controller.dart';
import 'package:dama/controller/fetchUserProfile.dart';
import 'package:dama/models/blogs_model.dart' show SourceReference;
import 'package:dama/routes/routes.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/modals/comment_bottomsheet.dart';
import 'package:dama/widgets/modals/subscription_modal.dart';
import 'package:dama/widgets/sources_references_section.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectedBlogScreen extends StatefulWidget {
  const SelectedBlogScreen({
    super.key,
    required this.authorId,
    required this.title,
    required this.imageUrl,
    this.author = '',
    required this.createdAt,
    required this.description,
    this.profileImageUrl = '',
    this.userId = '',
    required this.blogId,
    required this.comments,
    required this.roles,
    this.sources = const [],
  });

  final String title;
  final String authorId;
  final String imageUrl;
  final String author;
  final String description;
  final DateTime createdAt;
  final String profileImageUrl;
  final String userId;
  final String blogId;
  final List<dynamic> comments;
  final List roles;
  final List<SourceReference> sources;

  @override
  State<SelectedBlogScreen> createState() => _SelectedBlogScreenState();
}

class _SelectedBlogScreenState extends State<SelectedBlogScreen> {
  final Utils _utils = Utils();
  final FetchUserProfileController _fetchUserProfileController = Get.put(
    FetchUserProfileController(),
  );
  final ArticleCountController _articleCountController = Get.put(
    ArticleCountController(),
  );

  final CommentController _commentController = Get.put(CommentController());
  String comment = '';
  bool _isScrollingBlocked = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _fetchUserProfileController.fetchUserProfile(widget.userId);
    }

    _loadData();

    // _checkArticleLimit();
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
    // _showSubscriptionBottomSheet();
    //   return;
    // }

    if (commentText.isNotEmpty) {
      _commentController.addComment(blogID, commentText);
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
    required bool isDarkTheme,
    required List<dynamic> initialComments,
  }) {
    // if (_isScrollingBlocked) {
    //   _showSubscriptionBottomSheet();
    //   return;
    // }

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

  void _showSubscriptionBottomSheet() {
    SubscriptionBottomSheet.show(
      context: context,
      title: 'Premium Content Locked',
      subtitle:
          'You\'ve reached your article limit. Upgrade to continue reading unlimited articles and access exclusive content.',
      onUpgrade: () {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.plans);
      },
      onDismiss: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    bool isAdminOrManager =
        widget.roles.contains('admin') || widget.roles.contains('manager');
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Stack(
        children: [
          Column(
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
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (
                                  ScrollNotification scrollInfo,
                                ) {
                                  if (_isScrollingBlocked) {
                                    return true;
                                  }
                                  return false;
                                },
                                child: ListView(
                                  physics:
                                      _isScrollingBlocked
                                          ? NeverScrollableScrollPhysics()
                                          : AlwaysScrollableScrollPhysics(),
                                  children: [
                                    // Blog content container
                                    Container(
                                      color: isDarkMode ? kBlack : kWhite,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Blog image
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
                                                              Icons
                                                                  .broken_image,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                    )
                                                    : const Center(
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                          SizedBox(height: 10),

                                          // Author info and comments
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: kSidePadding,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Author info
                                                Obx(() {
                                                  final userProfile =
                                                      _fetchUserProfileController
                                                          .profile
                                                          .value;
                                                  final authorName =
                                                      widget
                                                                  .userId
                                                                  .isNotEmpty &&
                                                              userProfile !=
                                                                  null
                                                          ? '${userProfile.firstName} ${userProfile.lastName}'
                                                          : widget.author;
                                                  final profileImage =
                                                      widget
                                                                  .userId
                                                                  .isNotEmpty &&
                                                              userProfile !=
                                                                  null
                                                          ? userProfile
                                                              .profilePicture
                                                          : widget
                                                              .profileImageUrl;

                                                  return Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          // if (_isScrollingBlocked) {
                                                          //   _showSubscriptionBottomSheet();
                                                          //   return;
                                                          // }
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => OtherUserProfile(
                                                                    userID:
                                                                        widget
                                                                            .authorId,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        child: CircleAvatar(
                                                          radius: 25,
                                                          backgroundColor:
                                                              kLightGrey,
                                                          backgroundImage:
                                                              isAdminOrManager
                                                                  ? kDamaLogo
                                                                  : (profileImage !=
                                                                      null)
                                                                  ? NetworkImage(
                                                                    profileImage,
                                                                  )
                                                                  : null,
                                                          child:
                                                              (!isAdminOrManager &&
                                                                      (profileImage
                                                                              .isEmpty ||
                                                                          profileImage ==
                                                                              'null'))
                                                                  ? Icon(
                                                                    Icons
                                                                        .person,
                                                                    size: 30,
                                                                    color:
                                                                        kGrey,
                                                                  )
                                                                  : null,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            isAdminOrManager
                                                                ? "DAMA KENYA"
                                                                : authorName,
                                                            style: TextStyle(
                                                              color:
                                                                  isDarkMode
                                                                      ? kWhite
                                                                      : kBlack,
                                                              fontSize:
                                                                  kMidText,
                                                            ),
                                                          ),
                                                          Text(
                                                            _utils.timeAgo(
                                                              widget.createdAt,
                                                            ),
                                                            style: TextStyle(
                                                              color: kGrey,
                                                              fontSize:
                                                                  kNormalTextSize,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                }),

                                                // Comments button
                                                Obx(() {
                                                  final commentCount =
                                                      _commentController
                                                          .comments[widget
                                                              .blogId]
                                                          ?.length ??
                                                      0;
                                                  return GestureDetector(
                                                    onTap: () {
                                                      _showCommentsBottomSheet(
                                                        context,
                                                        isDarkTheme: isDarkMode,
                                                        blogID: widget.blogId,
                                                        initialComments:
                                                            widget.comments,
                                                      );
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          FontAwesomeIcons
                                                              .comment,
                                                          color: kGrey,
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          'Comments $commentCount',
                                                          style: TextStyle(
                                                            color: kGrey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),

                                          // Divider
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

                                          SizedBox(height: 5),

                                          // Blog title
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: kSidePadding,
                                              vertical: 10,
                                            ),
                                            child: Text(
                                              widget.title,
                                              style: TextStyle(
                                                color:
                                                    isDarkMode
                                                        ? kWhite
                                                        : kBlack,
                                                fontSize: kBigTextSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5),

                                          // Blog content
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
                                                      isDarkMode
                                                          ? kBlack
                                                          : kWhite,
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  textAlign: TextAlign.left,
                                                  margin: Margins.zero,
                                                ),
                                                "*": Style(
                                                  fontSize: FontSize(16.0),
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  backgroundColor:
                                                      isDarkMode
                                                          ? kBlack
                                                          : kWhite,
                                                  textAlign: TextAlign.left,
                                                ),
                                                "h2": Style(
                                                  fontSize: FontSize(16.0),
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  textAlign: TextAlign.left,
                                                ),
                                                "p": Style(
                                                  fontSize: FontSize(20.0),
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  textAlign: TextAlign.left,
                                                  margin: Margins.zero,
                                                ),
                                                "strong": Style(
                                                  fontSize: FontSize(16.0),
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  textAlign: TextAlign.left,
                                                  margin: Margins.zero,
                                                ),
                                                "em": Style(
                                                  fontSize: FontSize(20.0),
                                                  fontStyle: FontStyle.italic,
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  textAlign: TextAlign.left,
                                                  margin: Margins.zero,
                                                ),
                                                "body": Style(
                                                  fontSize: FontSize(16.0),
                                                  backgroundColor:
                                                      isDarkMode
                                                          ? kBlack
                                                          : kWhite,
                                                  textAlign: TextAlign.left,
                                                  margin: Margins.zero,
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
                                          SizedBox(height: 20),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
        ],
      ),
    );
  }
}

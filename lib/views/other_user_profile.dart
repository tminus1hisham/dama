import 'package:dama/controller/chat_controller.dart';
import 'package:dama/controller/conversations_controller.dart';
import 'package:dama/controller/fetchUserProfile.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/chat/chat_screen.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherUserProfile extends StatefulWidget {
  const OtherUserProfile({super.key, required this.userID});

  final String userID;

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  final FetchUserProfileController _fetchUserProfileController = Get.put(
    FetchUserProfileController(),
  );
  final ConversationsController _conversationsController = Get.put(
    ConversationsController(),
  );

  String currentUserId = '';
  String? conversationId;
  bool isPreparingChat = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadData();
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

  final ChatController _chatController = Get.put(ChatController());

  Future<void> _initializeData() async {
    currentUserId = await StorageService.getData("userId") ?? '';
    await _fetchUserProfileController.fetchUserProfile(widget.userID);
  }

  Future<void> _startOrFindConversation() async {
    setState(() {
      isPreparingChat = true;
    });

    try {
      // First try to find existing conversation
      await _conversationsController.fetchUserConversations(currentUserId);
      final existingConversation = _conversationsController.conversations
          .firstWhereOrNull(
            (conv) => conv.participants.any((p) => p.id == widget.userID),
          );

      if (existingConversation != null) {
        conversationId = existingConversation.id;
      } else {
        // If no conversation exists, create a new one
        final token = await StorageService.getData("access_token") ?? '';
        conversationId = await _chatController.initConversation(
          currentUserId,
          widget.userID,
          token,
        );
      }

      if (conversationId != null) {
        _navigateToChatScreen();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to start conversation: ${e.toString()}');
    } finally {
      setState(() {
        isPreparingChat = false;
      });
    }
  }

  void _navigateToChatScreen() {
    final user = _fetchUserProfileController.profile.value;
    if (user == null || conversationId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              conversationId: conversationId!,
              currentUserId: currentUserId,
              otherUserName: '${user.firstName} ${user.lastName}',
              otherUserImage: user.profilePicture,
            ),
      ),
    );
  }

  Future<void> _callUser(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      Get.snackbar('Error', 'Could not launch phone app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Obx(() {
        if (_fetchUserProfileController.isLoading.value) {
          return Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(child: customSpinner),
          );
        }

        final user = _fetchUserProfileController.profile.value;

        if (user == null) {
          return Center(child: Text("User profile not found"));
        }

        bool isAdminOrManager =
            user.roles.contains('admin') || user.roles.contains('manager');

        return Stack(
          children: [
            Column(
              children: [
                TopNavigationbar(
                  title:
                      isAdminOrManager
                          ? "DAMA KENYA"
                          : '${user.firstName} ${user.lastName}',
                ),
                SizedBox(height: 10),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1250),
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
                          child: Column(
                            children: [
                              Container(
                                color: isDarkMode ? kBlack : kWhite,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 50),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Image.asset(
                                        "images/profile_bg.png",
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: -40,
                                        left: 20,
                                        child: Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundColor: kLightGrey,
                                              backgroundImage:
                                                  isAdminOrManager
                                                      ? kDamaLogo
                                                      : (user
                                                          .profilePicture
                                                          .isNotEmpty)
                                                      ? NetworkImage(
                                                        user.profilePicture,
                                                      )
                                                      : null,
                                              child:
                                                  (!isAdminOrManager &&
                                                          (user
                                                              .profilePicture
                                                              .isEmpty))
                                                      ? const Icon(
                                                        Icons.person,
                                                        size: 30,
                                                        color: kGrey,
                                                      )
                                                      : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                color: isDarkMode ? kBlack : kWhite,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isAdminOrManager
                                                    ? "DAMA KENYA"
                                                    : '${user.firstName} ${user.lastName}',
                                                style: TextStyle(
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: kMidText,
                                                ),
                                              ),
                                              if (!isAdminOrManager) ...[
                                                Text(
                                                  user.title,
                                                  style: TextStyle(
                                                    fontSize: kMidText,
                                                    color:
                                                        isDarkMode
                                                            ? kWhite
                                                            : kBlack,
                                                  ),
                                                ),
                                                Text(
                                                  user.company,
                                                  style: TextStyle(
                                                    fontSize: kMidText,
                                                    color:
                                                        isDarkMode
                                                            ? kWhite
                                                            : kBlack,
                                                  ),
                                                ),
                                              ],

                                              SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: CustomButton(
                                            callBackFunction:
                                                _startOrFindConversation,
                                            label: "Message",
                                            backgroundColor: kBlue,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        // Expanded(
                                        //   child: Padding(
                                        //     padding: EdgeInsets.only(right: 10),
                                        //     child: GestureDetector(
                                        //       onTap: () {
                                        //         if (user.phoneNumber != null && user.phoneNumber.isNotEmpty) {
                                        //           _callUser(user.phoneNumber);
                                        //         } else {
                                        //           Get.snackbar(
                                        //             "Dama Kenya",
                                        //             "Phone number for this user is not available",
                                        //             backgroundColor: kBlue,
                                        //             colorText: Colors.white,
                                        //           );
                                        //         }
                                        //       },
                                        //       child: Container(
                                        //         height: 50,
                                        //         decoration: BoxDecoration(
                                        //           border: Border.all(color: kBlue, width: 1),
                                        //           borderRadius: BorderRadius.circular(8),
                                        //         ),
                                        //         child: Center(
                                        //           child: Text(
                                        //             "Call",
                                        //             style: TextStyle(color: kBlue, fontSize: 15, fontWeight: FontWeight.bold),
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                        GestureDetector(
                                          onTap: () {
                                            final link =
                                                'https://mydama.damakenya.org/${user.id}';
                                            Share.share(
                                              '${user.firstName} ${user.lastName}\n$link',
                                              subject: 'Dama Kenya',
                                            );
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: kBlue,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.share,
                                              color: kBlue,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                      ],
                                    ),

                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                color: isDarkMode ? kBlack : kWhite,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kSidePadding,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Bio',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: kBigTextSize,
                                        ),
                                      ),
                                      Text(
                                        user.brief,
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kGrey,
                                          fontSize: kNormalTextSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isPreparingChat)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              ),
          ],
        );
      }),
    );
  }
}

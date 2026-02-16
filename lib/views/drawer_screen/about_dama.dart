import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        children: [
          TopNavigationbar(title: "About Us"),
          SizedBox(height: 10),
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
                        child: Center(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              Container(
                                color: isDarkMode ? kBlack : kWhite,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        'About Us',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: kBigTextSize,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        style: TextStyle(
                                          fontSize: kNormalTextSize,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                        "DAMA Kenya (Nairobi Chapter) is the leading professional community for data management excellence in Kenya, operating under the global umbrella of DAMA International. Since our inception, we’ve been at the forefront of advancing data governance, analytics, and AI adoption across East Africa’s thriving digital economy.",
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    SizedBox(
                                      child: Image.asset(
                                        'images/about_us.png',
                                        width: double.infinity,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        'Vision',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: kBigTextSize,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        style: TextStyle(
                                          fontSize: kNormalTextSize,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                        "To equip professionals with DMBOK® frameworks, CDMP certifications, and peer networks that drive data maturity across industries.",
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        'Mission',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: kBigTextSize,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: kSidePadding,
                                      ),
                                      child: Text(
                                        style: TextStyle(
                                          fontSize: kNormalTextSize,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                        "A Kenya where every organization leverages data as a strategic advantage.",
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                  ],
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
}

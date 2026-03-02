import 'package:dama/controller/global_search_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/cards/blog_search_card.dart';
import 'package:dama/widgets/cards/event_search_card.dart';
import 'package:dama/widgets/cards/news_search_card.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/cards/resource_search_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final GlobalSearchController _searchController =
      Get.find<GlobalSearchController>();
  String firstName = '';
  String imageUrl = '';
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

  int selectedTab = 0;

  final List<String> tabNames = ["All", "Blogs", "News", "Resources", "Events"];

  // Track expanded state for each section
  Map<String, bool> expandedSections = {
    'blogs': false,
    'news': false,
    'resources': false,
    'events': false,
    'users': false,
  };

  Widget _buildPillButton(String text, int index) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : kWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? kBlue : kGrey),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kWhite : kGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(String sectionKey, bool isDarkMode) {
    final isExpanded = expandedSections[sectionKey] ?? false;

    return Container(
      color: isDarkMode ? kBlack : kWhite,
      width: double.infinity,
      margin: EdgeInsets.only(top: 1),
      child: TextButton(
        onPressed: () {
          setState(() {
            expandedSections[sectionKey] = !isExpanded;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isExpanded ? "Show Less" : "See All Results",
          style: TextStyle(
            color: kGrey,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionWithShowMore(
    String sectionKey,
    String title,
    List<dynamic> items,
    Widget Function(dynamic item) cardBuilder,
    bool isDarkMode,
  ) {
    List<Widget> content = [];
    final isExpanded = expandedSections[sectionKey] ?? false;
    final displayCount = (isExpanded || items.length <= 3) ? items.length : 3;

    content.add(SizedBox(height: 5));
    content.add(_buildSectionTitle(title, isDarkMode));

    // Add the cards
    content.addAll(
      List.generate(displayCount, (index) => cardBuilder(items[index])),
    );

    if (items.length > 3) {
      content.add(_buildSeeAllButton(sectionKey, isDarkMode));
    }

    return content;
  }

  Widget _buildFilteredContent(Map<String, dynamic> results, bool isDarkMode) {
    List<Widget> content = [];

    switch (selectedTab) {
      case 0: // All
        content = _buildAllContent(results, isDarkMode);
        break;
      case 1: // Blogs
        if (results['blogs']?.isNotEmpty ?? false) {
          content.addAll(
            _buildSectionWithShowMore(
              'blogs',
              'Blogs',
              results['blogs'],
              (blog) => BlogSearchCard(blog: blog),
              isDarkMode,
            ),
          );
        }
        break;
      case 2: // News
        if (results['news']?.isNotEmpty ?? false) {
          content.addAll(
            _buildSectionWithShowMore(
              'news',
              'News',
              results['news'],
              (news) => NewsSearchCard(news: news),
              isDarkMode,
            ),
          );
        }
        break;
      case 3: // Resources
        if (results['resources']?.isNotEmpty ?? false) {
          content.addAll(
            _buildSectionWithShowMore(
              'resources',
              'Resources',
              results['resources'],
              (resource) => ResourceSearchCard(resource: resource),
              isDarkMode,
            ),
          );
        }
        break;
      case 4: // Events
        if (results['events']?.isNotEmpty ?? false) {
          content.addAll(
            _buildSectionWithShowMore(
              'events',
              'Events',
              results['events'],
              (event) => EventSearchCard(event: event),
              isDarkMode,
            ),
          );
        }
        break;
    }

    if (content.isEmpty) {
      return Column(
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            selectedTab == 0
                ? "No results found for \"${widget.query}\""
                : "No ${tabNames[selectedTab].toLowerCase()} found for \"${widget.query}\"",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            "Try searching with different keywords",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAllContent(Map<String, dynamic> results, bool isDarkMode) {
    List<Widget> content = [];

    // Exclude users from home page search - only show blogs, news, events, resources
    if (results['blogs']?.isNotEmpty ?? false) {
      content.addAll(
        _buildSectionWithShowMore(
          'blogs',
          'Blogs',
          results['blogs'],
          (blog) => BlogSearchCard(blog: blog),
          isDarkMode,
        ),
      );
    }

    if (results['news']?.isNotEmpty ?? false) {
      content.addAll(
        _buildSectionWithShowMore(
          'news',
          'News',
          results['news'],
          (news) => NewsSearchCard(news: news),
          isDarkMode,
        ),
      );
    }

    if (results['events']?.isNotEmpty ?? false) {
      content.addAll(
        _buildSectionWithShowMore(
          'events',
          'Events',
          results['events'],
          (event) => EventSearchCard(event: event),
          isDarkMode,
        ),
      );
    }

    if (results['resources']?.isNotEmpty ?? false) {
      content.addAll(
        _buildSectionWithShowMore(
          'resources',
          'Resources',
          results['resources'],
          (resource) => ResourceSearchCard(resource: resource),
          isDarkMode,
        ),
      );
    }

    return content;
  }

  @override
  void initState() {
    super.initState();
    // Perform search only once when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.performSearch(widget.query);
    });
    _loadData();
  }

  String _truncateTitle(String text) {
    List<String> words = text.split(' ');
    if (words.length <= 4) {
      return text;
    } else {
      return '${words.sublist(0, 4).join(' ')} ...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          color: isDarkMode ? kBlack : kWhite,
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios),
                    color: kGrey,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? kDarkCard : kBGColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          _truncateTitle(widget.query),
                          style: TextStyle(
                            fontSize: kMidText,
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 5),
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
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: isDarkMode ? kBlack : kWhite,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _buildPillButton("All", 0),
                                        const SizedBox(width: 10),
                                        _buildPillButton("Blogs", 1),
                                        const SizedBox(width: 10),
                                        _buildPillButton("News", 2),
                                        const SizedBox(width: 10),
                                        _buildPillButton("Resources", 3),
                                        const SizedBox(width: 10),
                                        _buildPillButton("Events", 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                color: kWhite,
                                backgroundColor: kBlue,
                                displacement: 40,
                                onRefresh: () async {
                                  _searchController.performSearch(widget.query);
                                },
                                child: Obx(() {
                                  if (_searchController.isLoading.value) {
                                    return Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: Center(child: customSpinner),
                                    );
                                  }

                                  final results =
                                      _searchController.searchResults;
                                  if (results.values.every(
                                    (value) =>
                                        value == null ||
                                        (value is List && value.isEmpty),
                                  )) {
                                    return Column(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "No results found for \"${widget.query}\"",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Try searching with different keywords",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return _buildFilteredContent(
                                    results,
                                    isDarkMode,
                                  );
                                }),
                              ),
                            ),
                          ],
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

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Container(
      color: isDarkMode ? kDarkThemeBg : kWhite,
      child: Padding(
        padding: EdgeInsets.only(top: 10, left: 15),
        child: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

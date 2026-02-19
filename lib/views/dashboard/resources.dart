import 'package:dama/controller/resource_controller.dart';
import 'package:dama/controller/user_resources_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/views/selected_screens/selected_resource_screen.dart';
import 'package:dama/widgets/cards/resources_card.dart';
import 'package:dama/widgets/shimmer/resources_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class Resources extends StatefulWidget {
  final VoidCallback onMenuTap;

  const Resources({super.key, required this.onMenuTap});

  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final ResourceController _resourceController = Get.put(ResourceController());
  final UserResourceController _userResourceController = Get.put(
    UserResourceController(),
  );

  bool _isLoading = false;
  int selectedTab = 0;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  // Scroll controller for pagination
  final ScrollController _allResourcesScrollController = ScrollController();
  final ScrollController _myResourcesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _resourceController.fetchResources();
    _userResourceController.fetchUserResources();
    _loadData();
    _setupScrollListeners();
  }

  void _setupScrollListeners() {
    _allResourcesScrollController.addListener(_onAllResourcesScroll);
    _myResourcesScrollController.addListener(_onMyResourcesScroll);
  }

  void _onAllResourcesScroll() {
    if (_allResourcesScrollController.position.pixels >=
            _allResourcesScrollController.position.maxScrollExtent - 200 &&
        !_resourceController.isLoadingMore.value &&
        _resourceController.hasMore.value) {
      _resourceController.loadMoreResources();
    }
  }

  void _onMyResourcesScroll() {
    // My resources pagination can be added later if needed
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');

    setState(() {
      imageUrl = url;
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _resourceController.refreshResources();
    await _userResourceController.fetchUserResources();
    setState(() {
      _isLoading = false;
    });
  }

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

  @override
  void dispose() {
    _allResourcesScrollController.dispose();
    _myResourcesScrollController.dispose();
    _tabController.dispose();
    super.dispose();
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
          SizedBox(height: 5),
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildPillButton("All Resources", 0),
                    const SizedBox(width: 10),
                    _buildPillButton("My Resources", 1),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                // All Resources Tab with Pagination
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Obx(() {
                        if (_resourceController.isLoading.value &&
                            _resourceController.resourceList.isEmpty) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: 3,
                            itemBuilder:
                                (context, index) => ResourcesCardShimmer(),
                          );
                        } else if (_resourceController.resourceList.isEmpty) {
                          return ListView(
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
                                      Icons.folder_copy,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No resource available",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "THe resources will appear here",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: _allResourcesScrollController,
                          padding: const EdgeInsets.all(0),
                          itemCount: _resourceController.resourceList.length +
                              (_resourceController.hasMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the bottom
                            if (index >=
                                _resourceController.resourceList.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: kBlue,
                                  ),
                                ),
                              );
                            }

                            final resource =
                                _resourceController.resourceList[index];
                            // Check if user has purchased this resource
                            final isPurchased = _userResourceController
                                .resourceList
                                .any((r) => r.id == resource.id);

                            return ResourcesCard(
                              heading: resource.title,
                              imageUrl: resource.resourceImageUrl,
                              rating: resource.averageRating,
                              price: resource.price,
                              isPurchased: isPurchased,
                              onReadNowPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      title: resource.title,
                                      pdfUrl: resource.resourceLink,
                                    ),
                                  ),
                                );
                              },
                              onPressed: () {
                                if (isPurchased) {
                                  // Already purchased - open PDF directly
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PDFViewerPage(
                                        title: resource.title,
                                        pdfUrl: resource.resourceLink,
                                      ),
                                    ),
                                  );
                                } else if (resource.price > 0) {
                                  // Not purchased - navigate to payment modal
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SelectedResourceScreen(
                                        resourceID: resource.id,
                                        isPaid: false,
                                        autoShowPayment: true,
                                        title: resource.title,
                                        imageUrl: resource.resourceImageUrl,
                                        description: resource.description,
                                        price: resource.price,
                                        viewUrl: resource.resourceLink,
                                        date: resource.createdAt,
                                        rating: resource.averageRating,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Free resource - open directly
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PDFViewerPage(
                                        title: resource.title,
                                        pdfUrl: resource.resourceLink,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
                // My Resources Tab
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Obx(() {
                        if (_userResourceController.isLoading.value ||
                            _isLoading) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: 3,
                            itemBuilder:
                                (context, index) => ResourcesCardShimmer(),
                          );
                        } else if (_userResourceController
                            .resourceList
                            .isEmpty) {
                          return ListView(
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
                                      Icons.folder_copy,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No resource available",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Your resources will appear here",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: _myResourcesScrollController,
                          padding: const EdgeInsets.all(0),
                          itemCount:
                              _userResourceController.resourceList.length,
                          itemBuilder: (context, index) {
                            final resource =
                                _userResourceController.resourceList[index];
                            return ResourcesCard(
                              heading: resource.title,
                              imageUrl: resource.resourceImageUrl,
                              rating: resource.averageRating,
                              price: resource.price,
                              isPurchased: true,
                              onReadNowPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      title: resource.title,
                                      pdfUrl: resource.resourceLink,
                                    ),
                                  ),
                                );
                              },
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => SelectedResourceScreen(
                                          resourceID: resource.id,
                                          isPaid: resource.price > 0,
                                          title: resource.title,
                                          imageUrl: resource.resourceImageUrl,
                                          description: resource.description,
                                          price: resource.price,
                                          viewUrl: resource.resourceLink,
                                          date: resource.createdAt,
                                          rating: resource.averageRating,
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
                            );
                          },
                        );
                      }),
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

  @override
  bool get wantKeepAlive => true;
}

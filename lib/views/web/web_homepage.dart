import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WebDashboardLayout extends StatefulWidget {
  final Widget child;
  final String imageUrl;
  final String firstName;
  final String lastName;
  final VoidCallback onMenuTap;
  final Function(String) onSearchSubmitted;
  final VoidCallback onChatTap;

  const WebDashboardLayout({
    super.key,
    required this.child,
    required this.imageUrl,
    required this.firstName,
    required this.lastName,
    required this.onMenuTap,
    required this.onSearchSubmitted,
    required this.onChatTap,
  });

  @override
  State<WebDashboardLayout> createState() => _WebDashboardLayoutState();
}

class _WebDashboardLayoutState extends State<WebDashboardLayout> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 70,
            color: isDarkMode ? kBlack : kWhite,
            child: Row(
              children: [
                // Logo Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Placeholder for DAMA logo
                      Container(
                        width: 120,
                        height: 40,
                        color: kBlue,
                        child: Center(
                          child: Text(
                            'DAMA',
                            style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'KENYA NAIROBI',
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 40),

                // Search Bar
                Expanded(
                  child: Container(
                    height: 40,
                    constraints: BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: widget.onSearchSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search, color: kGrey, size: 20),
                        filled: true,
                        fillColor:
                            isDarkMode ? kDarkThemeBg : Color(0xFFF0F0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),

                Spacer(),

                // Navigation Items
                Row(
                  children: [
                    _buildNavItem('Home', isDarkMode, true),
                    _buildNavItem('Blogs', isDarkMode, false),
                    _buildNavItem('News', isDarkMode, false),
                    _buildNavItem('Resources', isDarkMode, false),
                    _buildNavItem('Events', isDarkMode, false),
                  ],
                ),

                SizedBox(width: 30),

                // Notification and Profile
                Row(
                  children: [
                    // Notification bell
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: isDarkMode ? kWhite : kBlack,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 10),

                    // Profile Avatar
                    GestureDetector(
                      onTap: widget.onMenuTap,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            widget.imageUrl.isNotEmpty
                                ? NetworkImage(widget.imageUrl)
                                : null,
                        child:
                            widget.imageUrl.isEmpty
                                ? Icon(Icons.person, size: 20, color: kWhite)
                                : null,
                      ),
                    ),

                    SizedBox(width: 20),
                  ],
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar - User Profile
                Container(
                  width: 280,
                  color: isDarkMode ? kBlack : kWhite,
                  child: Column(
                    children: [
                      SizedBox(height: 30),

                      // User Profile Section
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            widget.imageUrl.isNotEmpty
                                ? NetworkImage(widget.imageUrl)
                                : null,
                        child:
                            widget.imageUrl.isEmpty
                                ? Icon(Icons.person, size: 50, color: kWhite)
                                : null,
                      ),

                      SizedBox(height: 15),

                      Text(
                        '${widget.firstName} ${widget.lastName}',
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Sr. UX Designer',
                        // Placeholder - you can pass this as parameter
                        style: TextStyle(color: kGrey, fontSize: 14),
                      ),

                      SizedBox(height: 10),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View Profile',
                          style: TextStyle(color: kBlue),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Bio/Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Hello 👋 I\'m Aneta, an Architect turned UX Designer. I help businesses mitigate risks by strategically balancing needs, solving problems and making trade-off decisions. I have over 5 years of experience working on creating digital products in various industries, from health, safety, and environment to education and fintech. I help businesses increase their value for customers, improve their offering, earn more money and win new markets.',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? kWhite.withOpacity(0.8)
                                    : Colors.grey[600],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: Container(
                    color: isDarkMode ? kDarkThemeBg : Color(0xFFF5F5F5),
                    child: widget.child,
                  ),
                ),

                // Right Sidebar - My Resources
                Container(
                  width: 300,
                  color: isDarkMode ? kBlack : kWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'My Resources',
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          children: [
                            _buildResourceItem(
                              'A Leader\'s Handbook for Success: 17 Traits of a Successful Leader',
                              'assets/book1.png', // Placeholder image path
                              isDarkMode,
                            ),
                            _buildResourceItem(
                              'What Happens Next: A Traveler\'s Guide Through the End of This Age by Max',
                              'assets/book2.png', // Placeholder image path
                              isDarkMode,
                            ),
                            _buildResourceItem(
                              'Chaos: Charles Manson, the CIA, and the Secret History of the Sixties by',
                              'assets/book3.png', // Placeholder image path
                              isDarkMode,
                            ),
                            _buildResourceItem(
                              'Never Finished: Unshackle Your Mind and Win the War Within by David Goggins',
                              'assets/book4.png', // Placeholder image path
                              isDarkMode,
                            ),
                            _buildResourceItem(
                              'A Leader\'s Handbook for Success: 17 Traits of a Successful Leader',
                              'assets/book5.png', // Placeholder image path
                              isDarkMode,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'View More',
                            style: TextStyle(color: kBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            height: 50,
            color: isDarkMode ? kBlack : kWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Copyright 2024    All rights Reserved',
                    style: TextStyle(color: kGrey, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Privacy policy',
                          style: TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 20),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, bool isDarkMode, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? kBlue : (isDarkMode ? kWhite : kBlack),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceItem(String title, String imagePath, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover placeholder
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.book, color: Colors.grey[600]),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 5),

                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read Now',
                    style: TextStyle(color: kBlue, fontSize: 12),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

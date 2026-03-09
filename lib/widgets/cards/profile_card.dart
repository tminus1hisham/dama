import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.isDarkMode,
    required this.imageUrl,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.bio,
    this.hasMembership = false,
    this.membershipName,
    this.memberId,
  });

  final bool isDarkMode;
  final String imageUrl;
  final String firstName;
  final String lastName;
  final String title;
  final String bio;
  final bool hasMembership;
  final String? membershipName;
  final String? memberId;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 350, minWidth: 280),
      decoration: BoxDecoration(
        color: isDarkMode ? kBlack : kWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kGrey.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SizedBox(height: 30),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.asset(
                  "images/profile_bg.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: -50,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kWhite, width: 3),
                        ),
                        child: ProfileAvatar(
                          radius: 50,
                          backgroundColor: kLightGrey,
                          backgroundImage:
                              imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                          child:
                              imageUrl.isEmpty
                                  ? Icon(Icons.person, size: 40, color: kGrey)
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 70),

          Text(
            '$firstName $lastName',
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontSize: kTitleTextSize,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 5),

          Text(
            title.isNotEmpty ? title : 'Sr. UX Designer',
            style: TextStyle(color: kGrey, fontSize: kNormalTextSize),
          ),

          SizedBox(height: 5),

          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Text('View Profile', style: TextStyle(color: kBlue)),
          ),

          SizedBox(height: 20),

          Container(height: 3, color: isDarkMode ? kDarkThemeBg : kBGColor),

          // Bio/Description placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              bio,
              style: TextStyle(
                color: isDarkMode ? kWhite : kBlack,
                fontSize: 16,
                // height: 1.4,
              ),
            ),
          ),

          Container(height: 3, color: isDarkMode ? kDarkThemeBg : kBGColor),

          // Membership Status Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Status',
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                if (hasMembership) ...[
                  // Glass Grey Membership Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ACTIVE Status
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Professional Member
                            Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color:
                                      isDarkMode ? kWhite : Colors.grey[700],
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  membershipName ?? 'Professional Member',
                                  style: TextStyle(
                                    color:
                                        isDarkMode ? kWhite : Colors.grey[800],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // All premium benefits unlocked
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_open,
                                  color:
                                      isDarkMode
                                          ? kWhite.withOpacity(0.7)
                                          : Colors.grey[600],
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'All premium benefits unlocked',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? kWhite.withOpacity(0.7)
                                            : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Manage Plan Button
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.plans);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.settings,
                                          color:
                                              isDarkMode
                                                  ? kWhite
                                                  : Colors.grey[700],
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Manage Plan',
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? kWhite
                                                    : Colors.grey[800],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          isDarkMode
                                              ? kWhite
                                              : Colors.grey[700],
                                      size: 16,
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
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? kDarkThemeBg : kBGColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not a member yet',
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Unlock exclusive benefits and resources',
                          style: TextStyle(color: kGrey, fontSize: 13),
                        ),
                        SizedBox(height: 12),
                        // Membership benefits - always show default benefits when no membership
                        ..._buildBenefitsList(''),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.plans,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Upgrade Today',
                              style: TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get benefits based on membership type
  List<Widget> _buildBenefitsList(String membershipName) {
    final lower = membershipName.toLowerCase();
    List<String> benefits;

    if (lower.contains('student')) {
      benefits = [
        'Mentorship',
        'Training & Resources',
        'Event Discounts',
        'Free Career Consultation',
        'Job Platform & Forum Access',
      ];
    } else if (lower.contains('professional')) {
      benefits = [
        'Exclusive Member Area Access',
        'Training & Resources',
        'Event Discounts',
        'Networking Opportunities',
        'Job Platform & Forum Access',
      ];
    } else if (lower.contains('corporate')) {
      benefits = [
        'Company Certification',
        'High Visibility',
        'Event Perks',
        'Premium Training',
        'Exclusive Networking',
      ];
    } else {
      // Default benefits when no specific membership type
      benefits = [
        'Access to exclusive content',
        'Networking opportunities',
        'Event discounts',
        'Professional development',
        'Community support',
      ];
    }

    return benefits
        .map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: kBlue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(color: kGrey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

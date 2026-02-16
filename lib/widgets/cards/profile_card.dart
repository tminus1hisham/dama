import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
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
                        child: CircleAvatar(
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 5),

          Text(
            title.isNotEmpty ? title : 'Sr. UX Designer',
            style: TextStyle(color: kGrey, fontSize: 18),
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
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: kGreen, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            membershipName ?? 'Active Member',
                            style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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

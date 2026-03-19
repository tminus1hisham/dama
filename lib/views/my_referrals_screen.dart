import 'package:dama/controller/referral_controller.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:dama/utils/theme_provider.dart';

class MyReferralsScreen extends StatefulWidget {
  const MyReferralsScreen({super.key});

  @override
  State<MyReferralsScreen> createState() => _MyReferralsScreenState();
}

class _MyReferralsScreenState extends State<MyReferralsScreen> {
  late ReferralController _referralController;
  late TextEditingController _referralEmailController;

  @override
  void initState() {
    super.initState();
    _referralEmailController = TextEditingController();
    debugPrint('🔵🔵🔵 [MyReferralsScreen] initState() CALLED 🔵🔵🔵');
    try {
      _referralController = Get.find<ReferralController>();
      debugPrint('🔵 Controller found successfully');
      _referralController.fetchMyReferrals();
      debugPrint('🔵 fetchMyReferrals() called from initState');
    } catch (e) {
      debugPrint('❌ Error initializing MyReferralsScreen: $e');
    }
  }

  @override
  void dispose() {
    _referralEmailController.dispose();
    super.dispose();
  }

  void _sendReferralInvite() async {
    final emailOrPhone = _referralEmailController.text.trim();

    if (emailOrPhone.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an email address or phone number',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final success = await _referralController.sendInvite(emailOrPhone);
    if (success) {
      Get.snackbar(
        'Success',
        'Invitation sent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      _referralEmailController.clear();
      _referralController.fetchMyReferrals();
    }
  }

  String _formatPhoneWithCountryCode(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!digitsOnly.startsWith('254')) {
      return '254${digitsOnly.replaceFirst(RegExp(r'^0'), '')}';
    }
    return digitsOnly;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkBG : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? kDarkCard : kWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
        ),
        title: Text(
          'My Referrals',
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _referralController.fetchMyReferrals(),
            icon: Icon(Icons.refresh, color: isDarkMode ? kWhite : kBlack),
          ),
        ],
      ),
      body: Obx(
        () => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Refer a Friend Invite Section (at top)
                _buildReferralInviteSection(isDarkMode),
                const SizedBox(height: 32),

                // Referral History Heading
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people, color: kBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referral History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? kWhite : kBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track the colleagues and friends you\'ve invited to DAMA Kenya.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? kGrey : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats Overview
                _buildStatsGrid(isDarkMode),
                const SizedBox(height: 28),

                // Recent Invites Section
                _buildRecentInvitesSection(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralInviteSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.grey[800] ?? Colors.grey
                  : Colors.grey[200] ?? Colors.grey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_add,
                  color: kBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refer a Friend',
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invite your friends or colleagues to join DAMA Kenya. Stand a chance to receive a free membership or free training!',
                      style: TextStyle(
                        color: isDarkMode ? kGrey : Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email/Phone input
          TextField(
            controller: _referralEmailController,
            decoration: InputDecoration(
              hintText: 'Email or phone number',
              helperText: 'Phone: 254XXXXXXXXX or 0XXXXXXXXX',
              helperStyle: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                fontSize: 12,
              ),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDarkMode ? kDarkThemeBg : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Send Invite button
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _referralController.isSendingInvite.value
                        ? null
                        : _sendReferralInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  disabledBackgroundColor: kBlue.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _referralController.isSendingInvite.value
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(kWhite),
                            strokeWidth: 2,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: kWhite,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Send Invite',
                              style: TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDarkMode,
                title: 'Total Invites',
                value: _referralController.totalReferrals.value.toString(),
                icon: Icons.people,
                iconBackgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                isDarkMode,
                title: 'Successfully Joined',
                value: _referralController.successfulReferrals.value.toString(),
                icon: Icons.check_circle_outline,
                iconBackgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDarkMode, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.grey[800] ?? Colors.grey
                  : Colors.grey[300] ?? Colors.grey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBackgroundColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBackgroundColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? kGrey : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvitesSection(bool isDarkMode) {
    if (_referralController.isLoading.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your referrals...',
                style: TextStyle(
                  color: isDarkMode ? kGrey : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final referrals = _referralController.referralData.value?.referrals ?? [];

    if (referrals.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.grey[800] ?? Colors.grey
                    : Colors.grey[200] ?? Colors.grey,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No referrals yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You haven't invited anyone to DAMA Kenya yet.\nStart referring friends to earn rewards!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? kGrey : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Go refer a friend',
                  style: TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.grey[800] ?? Colors.grey
                  : Colors.grey[200] ?? Colors.grey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              padding: const EdgeInsets.all(16),
              child: Text(
                'Recent Invites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: referrals.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
              itemBuilder: (context, index) {
                final referral = referrals[index];
                final initials =
                    ((referral.referredUserName ?? 'SI')
                            .split(' ')
                            .map((e) => e.isEmpty ? '' : e[0])
                            .join())
                        .toUpperCase();
                final isEmail =
                    referral.referredUserEmail?.contains('@') ?? false;
                final displayValue =
                    referral.referredUserEmail ??
                    referral.referredUserId ??
                    'Unknown';
                final statusLabel =
                    referral.status == 'completed' ? 'Completed' : 'Pending';
                final statusColor =
                    referral.status == 'completed'
                        ? Colors.green
                        : Colors.orange;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kBlue.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: kBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isEmail
                                            ? 'Invited via Email'
                                            : 'Invited via Phone',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      isEmail
                                          ? Icons.mail_outline
                                          : Icons.phone_outlined,
                                      size: 16,
                                      color:
                                          isDarkMode ? kGrey : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isEmail
                                            ? displayValue
                                            : _formatPhoneWithCountryCode(
                                              displayValue,
                                            ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? kGrey
                                                  : Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDarkMode ? kGrey : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            referral.createdAt != null
                                ? 'Sent ${_formatDate(referral.createdAt!)}'
                                : 'Date unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? kGrey : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

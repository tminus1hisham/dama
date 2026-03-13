import 'package:dama/controller/referral_controller.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ReferralInviteModal extends StatefulWidget {
  final VoidCallback onClose;

  const ReferralInviteModal({super.key, required this.onClose});

  @override
  State<ReferralInviteModal> createState() => _ReferralInviteModalState();
}

class _ReferralInviteModalState extends State<ReferralInviteModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  late ReferralController _referralController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _referralController = Get.find<ReferralController>();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendInvite() async {
    final emailOrPhone = _emailController.text.trim();

    if (emailOrPhone.isEmpty) {
      _showToast('Please enter an email or phone number', isError: true);
      return;
    }

    final success = await _referralController.sendInvite(emailOrPhone);

    if (mounted) {
      if (success) {
        _showToast('Invitation sent successfully!', isError: false);
        _emailController.clear();
        // Auto close after success
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        final errorMsg =
            _referralController.errorMessage.value.isNotEmpty
                ? _referralController.errorMessage.value
                : 'Failed to send invitation. Please try again.';
        _showToast(errorMsg, isError: true);
      }
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kRed : kGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Obx(() => _buildCard(context, isDarkMode)),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDarkMode) {
    return Container(
      // Gradient border effect
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: kBlue.withOpacity(0.15), width: 1),
        ),
        color: isDarkMode ? const Color(0xFF1e293b) : const Color(0xFFF8FAFC),
        elevation: 20,
        shadowColor: kBlue.withOpacity(0.15),
        child: Stack(
          children: [
            // Decorative gradient circles
            Positioned(
              top: -60,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [kBlue.withOpacity(0.15), kBlue.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(90),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF64748B).withOpacity(0.15)
                                  : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Glowing icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: kBlue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kBlue, Colors.blue[900]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kBlue.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: kWhite,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'Invite a Colleague',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? kWhite : kBlack,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle with emphasis
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isDarkMode
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(text: 'Grow the '),
                        TextSpan(
                          text: 'DAMA Kenya',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' community! Share exclusive resources and expert insights with your peers.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call to action text
                  Text(
                    'Refer a friend and stand a chance to receive a free membership or free training!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kBlue,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Input with gradient border effect
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          kBlue.withOpacity(0.15),
                          Colors.blue[600]!.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kBlue.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: isDarkMode ? const Color(0xFF020817) : kWhite,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              enabled:
                                  !_referralController.isSendingInvite.value,
                              decoration: InputDecoration(
                                hintText: 'Email address or phone number',
                                hintStyle: TextStyle(
                                  color:
                                      isDarkMode
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              onSubmitted: (_) => _sendInvite(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              height: 56,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      _referralController.isSendingInvite.value
                                          ? null
                                          : _sendInvite,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [kBlue, Colors.blue[900]!],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child:
                                            _referralController
                                                    .isSendingInvite
                                                    .value
                                                ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                          Color
                                                        >(kWhite),
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                                : Icon(
                                                  Icons.send,
                                                  color: kWhite,
                                                  size: 20,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer text
                  Text(
                    'They will receive a personalized invitation link to join.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      child: SingleChildScrollView(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Obx(() => _buildCard(context, isDarkMode)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDarkMode) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kBlue.withOpacity(0.2), width: 1),
      ),
      color: isDarkMode ? const Color(0xFF0f1419) : kWhite,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Glowing icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBlue, Colors.blue[800]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_add,
                color: kWhite,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Invite a Colleague',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? kWhite : kBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFa0aec0)
                      : const Color(0xFF4a5568),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Grow the '),
                  TextSpan(
                    text: 'DAMA Kenya',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const TextSpan(
                    text: ' community! Share exclusive resources and expert insights with your peers.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Call to action
            Text(
              'Refer a friend and stand a chance to receive a free membership or free training!',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kBlue,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Input + button row wrapped in unified pill container
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1a2332)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kBlue.withOpacity(0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      enabled: !_referralController.isSendingInvite.value,
                      decoration: InputDecoration(
                        hintText: 'Email or phone no.',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) => _sendInvite(),
                    ),
                  ),

                  // Send Invite pill button
                  GestureDetector(
                    onTap: _referralController.isSendingInvite.value
                        ? null
                        : _sendInvite,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6BFF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: _referralController.isSendingInvite.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Send Invite',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Transform.rotate(
                                  angle: -0.785398,
                                  child: const Icon(Icons.send, color: Colors.black, size: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Footer text
            Text(
              'They will receive a personalized invitation link to join.',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

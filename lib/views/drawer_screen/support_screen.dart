import 'dart:ui';

import 'package:dama/controller/support_controller.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late final SupportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SupportController>();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Feedback'),
        centerTitle: false,
        backgroundColor: isDarkMode ? kDarkCard : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDarkMode ? kDarkText : Colors.black),
        titleTextStyle: TextStyle(
          color: isDarkMode ? kDarkText : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF0e1521) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Gradient
              _buildHeaderSection(isDarkMode),
              const SizedBox(height: 16),
              // Form Section
              if (isMobile)
                _buildMobileLayout(isDarkMode)
              else
                _buildDesktopLayout(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBlue.withOpacity(0.1),
            kBlue.withOpacity(0.05),
            isDarkMode ? const Color(0xFF0e1521) : Colors.grey[100]!,
          ],
        ),
        border: Border.all(color: kBlue.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Decorative blur elements
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kLightBlue.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBlue.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(color: kBlue.withOpacity(0.05), blurRadius: 8),
                    ],
                  ),
                  child: Icon(Icons.stars, color: kBlue, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'How can we help?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kDarkText : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'re here to help and answer any question you might have. We look forward to hearing from you.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? const Color(0xFFAEAEAE) : kGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isDarkMode) {
    return Column(
      children: [
        _buildContactInfoMobile(isDarkMode),
        const SizedBox(height: 12),
        _buildFormCard(isDarkMode),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Contact Info Sidebar
          Expanded(flex: 2, child: _buildContactInfoDesktop(isDarkMode)),
          // Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildFormFields(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoMobile(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactItem(
            icon: Icons.mail_outline,
            title: 'Email Us',
            subtitle: 'support@damakenya.org',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),
          _buildContactItem(
            icon: Icons.help_outline,
            title: 'Knowledge Base',
            subtitle: 'Our frequently asked questions is coming soon.',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoDesktop(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [const Color(0xFF1a222f), const Color(0xFF111820)]
                  : [const Color(0xFF1e293b), const Color(0xFF0f172a)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blurred circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withOpacity(0.2),
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
                shape: BoxShape.circle,
                color: kLightBlue.withOpacity(0.2),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.message, color: kBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildContactItemDesktop(
                  icon: Icons.mail,
                  title: 'Email Us',
                  subtitle: 'support@damakenya.org',
                ),
                const SizedBox(height: 32),
                _buildContactItemDesktop(
                  icon: Icons.help_center,
                  title: 'Knowledge Base',
                  subtitle: 'Our frequently asked questions is coming soon.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kBlue, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kDarkText : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? const Color(0xFFAEAEAE) : kGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItemDesktop({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
            ],
          ),
          child: Icon(
            icon,
            color: icon == Icons.mail ? kLightBlue : Colors.green[300],
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[200],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: SingleChildScrollView(child: _buildFormFields(isDarkMode)),
    );
  }

  Widget _buildFormFields(bool isDarkMode) {
    return Obx(() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabeledInput(
              label: 'Full Name',
              hint: 'John Doe',
              value: controller.fullName.value,
              error: controller.fullNameError.value,
              onChanged: (value) => controller.fullName.value = value,
              icon: Icons.person,
              isDarkMode: isDarkMode,
              controller: controller.fullNameController,
            ),
            const SizedBox(height: 12),
            _buildLabeledInput(
              label: 'Email Address',
              hint: 'john@example.com',
              value: controller.email.value,
              error: controller.emailError.value,
              onChanged: (value) => controller.email.value = value,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              isDarkMode: isDarkMode,
              controller: controller.emailController,
            ),
            const SizedBox(height: 12),
            _buildLabeledTextarea(
              label: 'How can we help?',
              hint:
                  'Please describe your issue, feedback, or question in detail...',
              value: controller.message.value,
              error: controller.messageError.value,
              onChanged: (value) => controller.message.value = value,
              isDarkMode: isDarkMode,
              controller: controller.messageController,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  disabledBackgroundColor: kBlue.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    controller.isLoading.value
                        ? null
                        : () => controller.sendMessage(),
                child:
                    controller.isLoading.value
                        ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                          strokeWidth: 2,
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Send Message',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildLabeledInput({
    required String label,
    required String hint,
    required String value,
    required String error,
    required Function(String) onChanged,
    required IconData icon,
    required bool isDarkMode,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? kDarkText : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? kDarkText : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color:
                  isDarkMode
                      ? const Color(0xFF7E99A3).withOpacity(0.5)
                      : kGrey.withOpacity(0.5),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                size: 18,
                color:
                    isDarkMode
                        ? const Color(0xFF7E99A3)
                        : kGrey.withOpacity(0.6),
              ),
            ),
            filled: true,
            fillColor:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    error.isNotEmpty
                        ? kRed.withOpacity(0.5)
                        : (isDarkMode ? kGlassBorder : Colors.grey[300]!),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    error.isNotEmpty
                        ? kRed.withOpacity(0.5)
                        : (isDarkMode ? kGlassBorder : Colors.grey[300]!),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: kRed),
            ),
          ),
      ],
    );
  }

  Widget _buildLabeledTextarea({
    required String label,
    required String hint,
    required String value,
    required String error,
    required Function(String) onChanged,
    required bool isDarkMode,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? kDarkText : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 6,
          minLines: 4,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? kDarkText : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color:
                  isDarkMode
                      ? const Color(0xFF7E99A3).withOpacity(0.5)
                      : kGrey.withOpacity(0.5),
            ),
            filled: true,
            fillColor:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    error.isNotEmpty
                        ? kRed.withOpacity(0.5)
                        : (isDarkMode ? kGlassBorder : Colors.grey[300]!),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    error.isNotEmpty
                        ? kRed.withOpacity(0.5)
                        : (isDarkMode ? kGlassBorder : Colors.grey[300]!),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: kRed),
            ),
          ),
      ],
    );
  }
}

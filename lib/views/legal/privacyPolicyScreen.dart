import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/legal_widgets.dart'; // Import the legal widgets
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Privacy Policy Screen
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBlack : kWhite,
      appBar: AppBar(
        backgroundColor: isDarkMode ? kDarkCard : kLightGrey,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: _PrivacyPolicyContent(isDarkMode: isDarkMode),
    );
  }
}

/// Privacy Policy content widget
class _PrivacyPolicyContent extends StatelessWidget {
  final bool isDarkMode;

  const _PrivacyPolicyContent({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use the functions from legal_widgets (without underscores)
          buildHeader('Privacy Policy', isDarkMode),
          buildLastUpdated('February 11, 2026', isDarkMode),
          const SizedBox(height: 20),

          buildParagraph(
            "At Dama Kenya, accessible from https://damakenya.org, one of our main priorities is the privacy of our visitors. This Privacy Policy document contains types of information that is collected and recorded by Dama Kenya and how we use it.",
            isDarkMode,
          ),
          buildParagraph(
            "If you have additional questions or require more information about our Privacy Policy, do not hesitate to contact us.",
            isDarkMode,
          ),
          buildParagraph(
            "This Privacy Policy applies only to our online activities and is valid for visitors to our website with regards to the information that they shared and/or collect in Dama Kenya. This policy is not applicable to any information collected offline or via channels other than this website.",
            isDarkMode,
          ),

          buildSectionTitle('CONSENT', isDarkMode),
          buildParagraph(
            "By using our website, you hereby consent to our Privacy Policy and agree to its terms.",
            isDarkMode,
          ),

          buildSectionTitle('INFORMATION WE COLLECT', isDarkMode),
          buildParagraph(
            "The personal information that you are asked to provide, and the reasons why you are asked to provide it, will be made clear to you at the point we ask you to provide your personal information.",
            isDarkMode,
          ),
          buildParagraph(
            "If you contact us directly, we may receive additional information about you such as your name, email address, phone number, the contents of the message and/or attachments you may send us, and any other information you may choose to provide.",
            isDarkMode,
          ),
          buildParagraph(
            "When you register for an Account, we may ask for your contact information, including items such as name, company name, address, email address, and telephone number.",
            isDarkMode,
          ),

          buildSectionTitle('HOW WE USE YOUR INFORMATION', isDarkMode),
          buildParagraph(
            "We use the information we collect in various ways, including to:",
            isDarkMode,
          ),
          buildBulletPoint(
            "Provide, operate, and maintain our website",
            isDarkMode,
          ),
          buildBulletPoint(
            "Improve, personalize, and expand our website",
            isDarkMode,
          ),
          buildBulletPoint(
            "Understand and analyze how you use our website",
            isDarkMode,
          ),
          buildBulletPoint(
            "Develop new products, services, features, and functionality",
            isDarkMode,
          ),
          buildBulletPoint(
            "Communicate with you, either directly or through one of our partners, including for customer service, to provide you with updates and other information relating to the website, and for marketing and promotional purposes",
            isDarkMode,
          ),
          buildBulletPoint("Send you emails", isDarkMode),
          buildBulletPoint("Find and prevent fraud", isDarkMode),

          buildSectionTitle('LOG FILES', isDarkMode),
          buildParagraph(
            "Dama Kenya follows a standard procedure of using log files. These files log visitors when they visit websites. All hosting companies do this and a part of hosting services' analytics. The information collected by log files include internet protocol (IP) addresses, browser type, Internet Service Provider (ISP), date and time stamp, referring/exit pages, and possibly the number of clicks. These are not linked to any information that is personally identifiable. The purpose of the information is for analyzing trends, administering the site, tracking users' movement on the website, and gathering demographic information.",
            isDarkMode,
          ),

          buildSectionTitle('COOKIES AND WEB BEACONS', isDarkMode),
          buildParagraph(
            "Like any other website, Dama Kenya uses 'cookies'. These cookies are used to store information including visitors' preferences, and the pages on the website that the visitor accessed or visited. The information is used to optimize the users' experience by customizing our web page content based on visitors' browser type and/or other information.",
            isDarkMode,
          ),

          buildSectionTitle(
            'ADVERTISING PARTNERS PRIVACY POLICIES',
            isDarkMode,
          ),
          buildParagraph(
            "You may consult this list to find the Privacy Policy for each of the advertising partners of Dama Kenya.",
            isDarkMode,
          ),
          buildParagraph(
            "Third-party ad servers or ad networks uses technologies like cookies, JavaScript, or Web Beacons that are used in their respective advertisements and links that appear on Dama Kenya, which are sent directly to users' browser. They automatically receive your IP address when this occurs. These technologies are used to measure the effectiveness of their advertising campaigns and/or to personalize the advertising content that you see on websites that you visit.",
            isDarkMode,
          ),
          buildParagraph(
            "Note that Dama Kenya has no access to or control over these cookies that are used by third-party advertisers.",
            isDarkMode,
          ),

          buildSectionTitle('THIRD PARTY PRIVACY POLICIES', isDarkMode),
          buildParagraph(
            "Dama Kenya's Privacy Policy does not apply to other advertisers or websites. Thus, we are advising you to consult the respective Privacy Policies of these third-party ad servers for more detailed information. It may include their practices and instructions about how to opt-out of certain options.",
            isDarkMode,
          ),
          buildParagraph(
            "You can choose to disable cookies through your individual browser options. To know more detailed information about cookie management with specific web browsers, it can be found at the browsers' respective websites.",
            isDarkMode,
          ),

          buildSectionTitle(
            'CCPA PRIVACY RIGHTS (DO NOT SELL MY PERSONAL INFORMATION)',
            isDarkMode,
          ),
          buildParagraph(
            "Under the CCPA, among other rights, California consumers have the right to:",
            isDarkMode,
          ),
          buildBulletPoint(
            "Request that a business that collects a consumer's personal data disclose the categories and specific pieces of personal data that a business has collected about consumers.",
            isDarkMode,
          ),
          buildBulletPoint(
            "Request that a business delete any personal data about the consumer that a business has collected.",
            isDarkMode,
          ),
          buildBulletPoint(
            "Request that a business that sells a consumer's personal data, not sell the consumer's personal data.",
            isDarkMode,
          ),
          buildParagraph(
            "If you make a request, we have one month to respond to you. If you would like to exercise any of these rights, please contact us.",
            isDarkMode,
          ),

          buildSectionTitle('GDPR DATA PROTECTION RIGHTS', isDarkMode),
          buildParagraph(
            "We would like to make sure you are fully aware of all of your data protection rights. Every user is entitled to the following:",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to access – You have the right to request copies of your personal data. We may charge you a small fee for this service.",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to rectification – You have the right to request that we correct any information you believe is inaccurate. You also have the right to request that we complete the information you believe is incomplete.",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to erasure – You have the right to request that we erase your personal data, under certain conditions.",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to restrict processing – You have the right to request that we restrict the processing of your personal data, under certain conditions.",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to object to processing – You have the right to object to our processing of your personal data, under certain conditions.",
            isDarkMode,
          ),
          buildBulletPoint(
            "The right to data portability – You have the right to request that we transfer the data that we have collected to another organization, or directly to you, under certain conditions.",
            isDarkMode,
          ),
          buildParagraph(
            "If you make a request, we have one month to respond to you. If you would like to exercise any of these rights, please contact us.",
            isDarkMode,
          ),

          buildSectionTitle('CHILDREN\'S INFORMATION', isDarkMode),
          buildParagraph(
            "Another part of our priority is adding protection for children while using the internet. We encourage parents and guardians to observe, participate in, and/or monitor and guide their online activity.",
            isDarkMode,
          ),
          buildParagraph(
            "Dama Kenya does not knowingly collect any Personal Identifiable Information from children under the age of 13. If you think that your child provided this kind of information on our website, we strongly encourage you to contact us immediately and we will do our best efforts to promptly remove such information from our records.",
            isDarkMode,
          ),

          buildSectionTitle('CHANGES TO THIS PRIVACY POLICY', isDarkMode),
          buildParagraph(
            "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.",
            isDarkMode,
          ),
          buildParagraph(
            "We will let you know via email and/or a prominent notice on our Service, prior to the change becoming effective and update the 'Last updated' date at the top of this Privacy Policy.",
            isDarkMode,
          ),
          buildParagraph(
            "You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.",
            isDarkMode,
          ),

          buildSectionTitle('CONTACT US', isDarkMode),
          buildParagraph(
            "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at:",
            isDarkMode,
          ),
          buildContactInfo(isDarkMode, includePhone: true),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

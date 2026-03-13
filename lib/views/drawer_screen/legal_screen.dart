import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Legal documents screen - Terms & Conditions only
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
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
          'Terms & Conditions',
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: _TermsOfUseContent(isDarkMode: isDarkMode),
    );
  }
}

/// Terms of Use content widget
class _TermsOfUseContent extends StatelessWidget {
  final bool isDarkMode;

  const _TermsOfUseContent({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Terms of Use', isDarkMode),
          _buildLastUpdated('February 11, 2026', isDarkMode),
          const SizedBox(height: 20),

          _buildSectionTitle('AGREEMENT TO OUR LEGAL TERMS', isDarkMode),
          _buildParagraph(
            "We are Dama Kenya ('Company', 'we', 'us', or 'our'), a company registered in Kenya at Western Heights, Karuna Rd, Westlands, Nairobi.",
            isDarkMode,
          ),
          _buildParagraph(
            "We operate the website https://damakenya.org (the 'Site'), as well as any other related products and services that refer or link to these legal terms (the 'Legal Terms') (collectively, the 'Services').",
            isDarkMode,
          ),
          _buildParagraph(
            "DAMA Kenya Nairobi is the Kenyan Chapter of the International Data Management Association, the leading international organization for data management professionals. We are dedicated to creating a Kenya where every organization leverages data as a strategic advantage.",
            isDarkMode,
          ),
          _buildParagraph(
            "You can contact us by phone at +254 797 302 010, email at info@damakenya.org, or by mail to Western Heights, Karuna Rd, Westlands, Nairobi, Kenya.",
            isDarkMode,
          ),
          _buildParagraph(
            "These Legal Terms constitute a legally binding agreement made between you, whether personally or on behalf of an entity ('you'), and Dama Kenya, concerning your access to and use of the Services. You agree that by accessing the Services, you have read, understood, and agreed to be bound by all of these Legal Terms. IF YOU DO NOT AGREE WITH ALL OF THESE LEGAL TERMS, THEN YOU ARE EXPRESSLY PROHIBITED FROM USING THE SERVICES AND YOU MUST DISCONTINUE USE IMMEDIATELY.",
            isDarkMode,
          ),
          _buildParagraph(
            "The Services are intended for users who are at least 18 years old. Persons under the age of 18 are not permitted to use or register for the Services.",
            isDarkMode,
          ),
          _buildParagraph(
            "We recommend that you print a copy of these Legal Terms for your records.",
            isDarkMode,
          ),

          _buildSectionTitle('1. OUR SERVICES', isDarkMode),
          _buildParagraph(
            "The information provided when using the Services is not intended for distribution to or use by any person or entity in any jurisdiction or country where such distribution or use would be contrary to law or regulation or which would subject us to any registration requirement within such jurisdiction or country. Accordingly, those persons who choose to access the Services from other locations do so on their own initiative and are solely responsible for compliance with local laws, if and to the extent local laws are applicable.",
            isDarkMode,
          ),

          _buildSectionTitle('2. INTELLECTUAL PROPERTY RIGHTS', isDarkMode),
          _buildSubsectionTitle('Our intellectual property', isDarkMode),
          _buildParagraph(
            "We are the owner or the licensee of all intellectual property rights in our Services, including all source code, databases, functionality, software, website designs, audio, video, text, photographs, and graphics in the Services (collectively, the 'Content'), as well as the trademarks, service marks, and logos contained therein (the 'Marks').",
            isDarkMode,
          ),
          _buildParagraph(
            "Our Content and Marks are protected by copyright and trademark laws (and various other intellectual property rights and unfair competition laws) and treaties around the world.",
            isDarkMode,
          ),
          _buildParagraph(
            "The Content and Marks are provided in or through the Services 'AS IS' for your personal, non-commercial use or internal business purpose only.",
            isDarkMode,
          ),
          _buildSubsectionTitle('Your use of our Services', isDarkMode),
          _buildParagraph(
            "Subject to your compliance with these Legal Terms, including the 'PROHIBITED ACTIVITIES' section below, we grant you a non-exclusive, non-transferable, revocable licence to:",
            isDarkMode,
          ),
          _buildBulletPoint("access the Services; and", isDarkMode),
          _buildBulletPoint(
            "download or print a copy of any portion of the Content to which you have properly gained access,",
            isDarkMode,
          ),
          _buildParagraph(
            "solely for your personal, non-commercial use or internal business purpose.",
            isDarkMode,
          ),

          _buildSectionTitle('3. USER REPRESENTATIONS', isDarkMode),
          _buildParagraph(
            "By using the Services, you represent and warrant that: (1) all registration information you submit will be true, accurate, current, and complete; (2) you will maintain the accuracy of such information and promptly update such registration information as necessary; (3) you have the legal capacity and you agree to comply with these Legal Terms; (4) you are not a minor in the jurisdiction in which you reside; (5) you will not access the Services through automated or non-human means, whether through a bot, script or otherwise; (6) you will not use the Services for any illegal or unauthorised purpose; and (7) your use of the Services will not violate any applicable law or regulation.",
            isDarkMode,
          ),

          _buildSectionTitle('4. USER REGISTRATION', isDarkMode),
          _buildParagraph(
            "You may be required to register to use the Services. You agree to keep your password confidential and will be responsible for all use of your account and password. We reserve the right to remove, reclaim, or change a username you select if we determine, in our sole discretion, that such username is inappropriate, obscene, or otherwise objectionable.",
            isDarkMode,
          ),

          _buildSectionTitle('5. PURCHASES AND PAYMENT', isDarkMode),
          _buildParagraph(
            "We accept the following forms of payment: Mobile Money (M-Pesa) and other electronic means.",
            isDarkMode,
          ),
          _buildParagraph(
            "You agree to provide current, complete, and accurate purchase and account information for all purchases made via the Services. You further agree to promptly update account and payment information, including email address, payment method, and payment card expiration date, so that we can complete your transactions and contact you as needed. Sales tax will be added to the price of purchases as deemed required by us. We may change prices at any time. All payments shall be in KSH.",
            isDarkMode,
          ),

          _buildSectionTitle('6. SUBSCRIPTIONS', isDarkMode),
          _buildSubsectionTitle('Billing and Renewal', isDarkMode),
          _buildParagraph(
            "Your subscription will continue and automatically renew unless cancelled. You consent to our charging your payment method on a recurring basis without requiring your prior approval for each recurring charge, until such time as you cancel the applicable order. The length of your billing cycle is annual.",
            isDarkMode,
          ),
          _buildSubsectionTitle('Free Trial', isDarkMode),
          _buildParagraph(
            "We offer a 365-day free trial to new users who register with the Services. The account will not be charged and the subscription will be suspended until upgraded to a paid version at the end of the free trial.",
            isDarkMode,
          ),
          _buildSubsectionTitle('Cancellation', isDarkMode),
          _buildParagraph(
            "All purchases are non-refundable. You can cancel your subscription at any time by contacting us using the contact information provided below. Your cancellation will take effect at the end of the current paid term. If you have any questions or are unsatisfied with our Services, please email us at info@damakenya.org.",
            isDarkMode,
          ),

          _buildSectionTitle('7. SOFTWARE', isDarkMode),
          _buildParagraph(
            "We may include software for use in connection with our Services. If such software is accompanied by an end user licence agreement ('EULA'), the terms of the EULA will govern your use of the software. If such software is not accompanied by a EULA, then we grant to you a non-exclusive, revocable, personal, and non-transferable licence to use such software solely in connection with our services and in accordance with these Legal Terms.",
            isDarkMode,
          ),

          _buildSectionTitle('8. PROHIBITED ACTIVITIES', isDarkMode),
          _buildParagraph(
            "You may not access or use the Services for any purpose other than that for which we make the Services available. The Services may not be used in connection with any commercial endeavours except those that are specifically endorsed or approved by us.",
            isDarkMode,
          ),
          _buildParagraph(
            "As a user of the Services, you agree not to:",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Systematically retrieve data or other content from the Services to create or compile, directly or indirectly, a collection, compilation, database, or directory without written permission from us.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Trick, defraud, or mislead us and other users, especially in any attempt to learn sensitive account information such as user passwords.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Circumvent, disable, or otherwise interfere with security-related features of the Services.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Disparage, tarnish, or otherwise harm, in our opinion, us and/or the Services.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Use any information obtained from the Services in order to harass, abuse, or harm another person.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Make improper use of our support services or submit false reports of abuse or misconduct.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Use the Services in a manner inconsistent with any applicable laws or regulations.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Upload or transmit viruses, Trojan horses, or other material that interferes with any party's uninterrupted use and enjoyment of the Services.",
            isDarkMode,
          ),

          _buildSectionTitle('9. USER GENERATED CONTRIBUTIONS', isDarkMode),
          _buildParagraph(
            "The Services may invite you to chat, contribute to, or participate in blogs, message boards, online forums, and other functionality. Contributions may be viewable by other users of the Services and through third-party websites.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Your Contributions are not false, inaccurate, or misleading.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Your Contributions are not obscene, lewd, lascivious, filthy, violent, harassing, libellous, slanderous, or otherwise objectionable.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Your Contributions do not ridicule, mock, disparage, intimidate, or abuse anyone.",
            isDarkMode,
          ),
          _buildBulletPoint(
            "Your Contributions do not violate any applicable law, regulation, or rule.",
            isDarkMode,
          ),

          _buildSectionTitle('10. CONTRIBUTION LICENCE', isDarkMode),
          _buildParagraph(
            "By posting your Contributions to any part of the Services or making Contributions accessible to the Services by linking your account from the Services to any of your social networking accounts, you automatically grant us an unrestricted, unlimited, irrevocable, perpetual, non-exclusive, transferable, royalty-free, fully-paid, worldwide right, and licence to host, use, copy, reproduce, disclose, sell, resell, publish, broadcast, retitle, archive, store, cache, publicly perform, publicly display, reformat, translate, transmit, excerpt (in whole or in part), and distribute such Contributions.",
            isDarkMode,
          ),

          _buildSectionTitle('11. GUIDELINES FOR REVIEWS', isDarkMode),
          _buildParagraph(
            "We may provide you areas on the Services to leave reviews or ratings. When posting a review, you must comply with the following criteria: (1) you should have firsthand experience with the person/entity being reviewed; (2) your reviews should not contain offensive profanity, or abusive, racist, offensive, or hateful language; (3) your reviews should not contain discriminatory references based on religion, race, gender, national origin, age, marital status, sexual orientation, or disability.",
            isDarkMode,
          ),

          _buildSectionTitle('12. SOCIAL MEDIA', isDarkMode),
          _buildParagraph(
            "As part of the functionality of the Services, you may link your account with online accounts you have with third-party service providers. You understand that we may access, make available, and store any content that you have provided to and stored in your Third-Party Account.",
            isDarkMode,
          ),

          _buildSectionTitle('13. SERVICES MANAGEMENT', isDarkMode),
          _buildParagraph(
            "We reserve the right, but not the obligation, to: (1) monitor the Services for violations of these Legal Terms; (2) take appropriate legal action against anyone who, in our sole discretion, violates the law or these Legal Terms; (3) refuse, restrict access to, limit the availability of, or disable any of your Contributions; (4) remove from the Services or otherwise disable all files and content that are excessive in size or are in any way burdensome to our systems.",
            isDarkMode,
          ),

          _buildSectionTitle('14. PRIVACY POLICY', isDarkMode),
          _buildParagraph(
            "We care about data privacy and security. Please review our Privacy Policy. By using the Services, you agree to be bound by our Privacy Policy, which is incorporated into these Legal Terms.",
            isDarkMode,
          ),

          _buildSectionTitle('15. COPYRIGHT INFRINGEMENTS', isDarkMode),
          _buildParagraph(
            "We respect the intellectual property rights of others. If you believe that any material available on or through the Services infringes upon any copyright you own or control, please immediately notify us using the contact information provided below.",
            isDarkMode,
          ),

          _buildSectionTitle('16. TERM AND TERMINATION', isDarkMode),
          _buildParagraph(
            "These Legal Terms shall remain in full force and effect while you use the Services. WE RESERVE THE RIGHT TO, IN OUR SOLE DISCRETION AND WITHOUT NOTICE OR LIABILITY, DENY ACCESS TO AND USE OF THE SERVICES, TO ANY PERSON FOR ANY REASON OR FOR NO REASON.",
            isDarkMode,
          ),

          _buildSectionTitle('17. MODIFICATIONS AND INTERRUPTIONS', isDarkMode),
          _buildParagraph(
            "We reserve the right to change, modify, or remove the contents of the Services at any time or for any reason at our sole discretion without notice. We cannot guarantee the Services will be available at all times. We may experience hardware, software, or other problems or need to perform maintenance related to the Services, resulting in interruptions, delays, or errors.",
            isDarkMode,
          ),

          _buildSectionTitle('18. GOVERNING LAW', isDarkMode),
          _buildParagraph(
            "These Legal Terms shall be governed by and defined following the laws of Kenya. Dama Kenya and yourself irrevocably consent that the courts of Kenya shall have exclusive jurisdiction to resolve any dispute which may arise in connection with these Legal Terms.",
            isDarkMode,
          ),

          _buildSectionTitle('19. DISPUTE RESOLUTION', isDarkMode),
          _buildParagraph(
            "Binding Arbitration: Any dispute arising out of or in connection with these Legal Terms, including any question regarding its existence, validity, or termination, shall be referred to and finally resolved by the International Commercial Arbitration Court.",
            isDarkMode,
          ),

          _buildSectionTitle('20. CORRECTIONS', isDarkMode),
          _buildParagraph(
            "There may be information on the Services that contains typographical errors, inaccuracies, or omissions, including descriptions, pricing, availability, and various other information. We reserve the right to correct any errors, inaccuracies, or omissions and to change or update the information on the Services at any time, without prior notice.",
            isDarkMode,
          ),

          _buildSectionTitle('21. DISCLAIMER', isDarkMode),
          _buildParagraph(
            "The Services are provided on an as-is and as-available basis. You agree that your use of the Services will be at your sole risk. To the fullest extent permitted by law, we disclaim all warranties, express or implied, in connection with the Services and your use thereof.",
            isDarkMode,
          ),

          _buildSectionTitle('22. LIMITATIONS OF LIABILITY', isDarkMode),
          _buildParagraph(
            "In no event will we or our directors, employees, or agents be liable to you or any third party for any direct, indirect, consequential, exemplary, incidental, special, or punitive damages, including lost profit, lost revenue, loss of data, or other damages arising from your use of the Services.",
            isDarkMode,
          ),

          _buildSectionTitle('23. INDEMNIFICATION', isDarkMode),
          _buildParagraph(
            "You agree to defend, indemnify, and hold us harmless, including our subsidiaries, affiliates, and all of our respective officers, agents, partners, and employees, from and against any loss, damage, liability, claim, or demand, including reasonable attorneys' fees and expenses, made by any third party due to or arising out of your Contributions, use of the Services, or breach of these Legal Terms.",
            isDarkMode,
          ),

          _buildSectionTitle('24. USER DATA', isDarkMode),
          _buildParagraph(
            "We will maintain certain data that you transmit to the Services for the purpose of managing the performance of the Services, as well as data relating to your use of the Services. Although we perform regular routine backups of data, you are solely responsible for all data that you transmit or that relates to any activity you have undertaken using the Services.",
            isDarkMode,
          ),

          _buildSectionTitle(
            '25. ELECTRONIC COMMUNICATIONS, TRANSACTIONS, AND SIGNATURES',
            isDarkMode,
          ),
          _buildParagraph(
            "Visiting the Services, sending us emails, and completing online forms constitute electronic communications. You consent to receive electronic communications, and you agree that all agreements, notices, disclosures, and other communications we provide to you electronically, via email and on the Services, satisfy any legal requirement that such communication be in writing.",
            isDarkMode,
          ),

          _buildSectionTitle('26. SMS TEXT MESSAGING', isDarkMode),
          _buildParagraph(
            "By opting into any text messaging program, you expressly consent to receive text messages (SMS) to your mobile number.",
            isDarkMode,
          ),

          _buildSectionTitle('27. MISCELLANEOUS', isDarkMode),
          _buildParagraph(
            "These Legal Terms and any policies or operating rules posted by us on the Services or in respect to the Services constitute the entire agreement and understanding between you and us. Our failure to exercise or enforce any right or provision of these Legal Terms shall not operate as a waiver of such right or provision. These Legal Terms operate to the fullest extent permissible by law.",
            isDarkMode,
          ),

          _buildSectionTitle('28. CONTACT US', isDarkMode),
          _buildParagraph(
            "In order to resolve a complaint regarding the Services or to receive further information regarding use of the Services, please contact us at:",
            isDarkMode,
          ),
          _buildContactInfo(isDarkMode, includePhone: true),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Helper widgets for building legal document content
Widget _buildHeader(String title, bool isDarkMode) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? kWhite : kBlack,
    ),
  );
}

Widget _buildLastUpdated(String date, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'Last updated $date',
      style: TextStyle(
        fontSize: 14,
        color: isDarkMode ? const Color(0xFFa0a8b8) : kGrey,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

Widget _buildSectionTitle(String title, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? kWhite : kBlack,
      ),
    ),
  );
}

Widget _buildSubsectionTitle(String title, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? const Color(0xFFe0e0e0) : const Color(0xFF333333),
      ),
    ),
  );
}

Widget _buildParagraph(String text, bool isDarkMode, {bool isItalic = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      ),
    ),
  );
}

Widget _buildBulletPoint(String text, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 15,
            color: kBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color:
                  isDarkMode
                      ? const Color(0xFFd0d0d0)
                      : const Color(0xFF444444),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildContactInfo(bool isDarkMode, {bool includePhone = false}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDarkMode ? kDarkCard : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkMode ? kGlassBorder : const Color(0xFFE0E0E0),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dama Kenya',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? kWhite : kBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Western Heights, Karuna Rd\nWestlands, Nairobi\nKenya',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color:
                isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
          ),
        ),
        if (includePhone) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: kBlue),
              const SizedBox(width: 8),
              Text(
                '+254 797 302 010',
                style: TextStyle(fontSize: 14, color: kBlue),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.email, size: 16, color: kBlue),
            const SizedBox(width: 8),
            Text(
              'info@damakenya.org',
              style: TextStyle(fontSize: 14, color: kBlue),
            ),
          ],
        ),
      ],
    ),
  );
}

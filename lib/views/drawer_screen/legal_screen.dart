import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Legal documents screen with tabs for Privacy Policy, Terms of Use, and Cookie Policy
class LegalScreen extends StatefulWidget {
  final int initialTab;
  
  const LegalScreen({super.key, this.initialTab = 0});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Legal',
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: kBlue,
          unselectedLabelColor: isDarkMode ? kGrey : Colors.grey[600],
          indicatorColor: kBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Use'),
            Tab(text: 'Cookie Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PrivacyPolicyContent(isDarkMode: isDarkMode),
          _TermsOfUseContent(isDarkMode: isDarkMode),
          _CookiePolicyContent(isDarkMode: isDarkMode),
        ],
      ),
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
          _buildHeader('Privacy Policy', isDarkMode),
          _buildLastUpdated('February 11, 2026', isDarkMode),
          const SizedBox(height: 20),
          
          _buildParagraph(
            "This Privacy Notice for Dama Kenya ('we', 'us', or 'our'), describes how and why we might access, collect, store, use, and/or share ('process') your personal information when you use our services ('Services'), including when you:",
            isDarkMode,
          ),
          _buildBulletPoint("Visit our website at https://damakenya.org or any website of ours that links to this Privacy Notice", isDarkMode),
          _buildBulletPoint("Engage with us in other related ways, including any marketing or events", isDarkMode),
          
          _buildParagraph(
            "Questions or concerns? Reading this Privacy Notice will help you understand your privacy rights and choices. We are responsible for making decisions about how your personal information is processed. If you do not agree with our policies and practices, please do not use our Services. If you still have any questions or concerns, please contact us at info@damakenya.org.",
            isDarkMode,
          ),
          
          _buildSectionTitle('SUMMARY OF KEY POINTS', isDarkMode),
          _buildParagraph(
            "This summary provides key points from our Privacy Notice, but you can find out more details about any of these topics by clicking the link following each key point or by using our table of contents below to find the section you are looking for.",
            isDarkMode,
          ),
          
          _buildBulletPoint("What personal information do we process? When you visit, use, or navigate our Services, we may process personal information depending on how you interact with us and the Services, the choices you make, and the products and features you use.", isDarkMode),
          _buildBulletPoint("Do we process any sensitive personal information? We do not process sensitive personal information.", isDarkMode),
          _buildBulletPoint("Do we collect any information from third parties? We do not collect any information from third parties.", isDarkMode),
          _buildBulletPoint("How do we process your information? We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law.", isDarkMode),
          _buildBulletPoint("In what situations and with which parties do we share personal information? We may share information in specific situations and with specific third parties.", isDarkMode),
          _buildBulletPoint("How do we keep your information safe? We have adequate organisational and technical processes and procedures in place to protect your personal information.", isDarkMode),
          _buildBulletPoint("What are your rights? Depending on where you are located geographically, the applicable privacy law may mean you have certain rights regarding your personal information.", isDarkMode),
          _buildBulletPoint("How do you exercise your rights? The easiest way to exercise your rights is by visiting https://damakenya.org/, or by contacting us.", isDarkMode),
          
          _buildSectionTitle('1. WHAT INFORMATION DO WE COLLECT?', isDarkMode),
          _buildSubsectionTitle('Personal information you disclose to us', isDarkMode),
          _buildParagraph(
            "In Short: We collect personal information that you provide to us.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We collect personal information that you voluntarily provide to us when you register on the Services, express an interest in obtaining information about us or our products and Services, when you participate in activities on the Services, or otherwise when you contact us.",
            isDarkMode,
          ),
          _buildParagraph(
            "Personal Information Provided by You. The personal information that we collect depends on the context of your interactions with us and the Services, the choices you make, and the products and features you use. The personal information we collect may include the following:",
            isDarkMode,
          ),
          _buildBulletPoint("names", isDarkMode),
          _buildBulletPoint("phone numbers", isDarkMode),
          _buildBulletPoint("email addresses", isDarkMode),
          _buildBulletPoint("job titles", isDarkMode),
          _buildBulletPoint("usernames", isDarkMode),
          _buildBulletPoint("passwords", isDarkMode),
          _buildBulletPoint("contact preferences", isDarkMode),
          _buildBulletPoint("contact or authentication data", isDarkMode),
          
          _buildParagraph("Sensitive Information. We do not process sensitive information.", isDarkMode),
          
          _buildParagraph(
            "Payment Data. We may collect data necessary to process your payment if you choose to make purchases, such as your payment instrument number, and the security code associated with your payment instrument. All payment data is handled and stored by M-pesa. You may find their privacy notice link(s) here: https://www.m-pesa.africa/privacy.",
            isDarkMode,
          ),
          
          _buildParagraph(
            "Social Media Login Data. We may provide you with the option to register with us using your existing social media account details, like your Facebook, X, or other social media account. If you choose to register in this way, we will collect certain profile information about you from the social media provider.",
            isDarkMode,
          ),
          
          _buildParagraph(
            "All personal information that you provide to us must be true, complete, and accurate, and you must notify us of any changes to such personal information.",
            isDarkMode,
          ),
          
          _buildSectionTitle('2. HOW DO WE PROCESS YOUR INFORMATION?', isDarkMode),
          _buildParagraph(
            "In Short: We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We process your personal information for a variety of reasons, depending on how you interact with our Services, including:",
            isDarkMode,
          ),
          _buildBulletPoint("To facilitate account creation and authentication and otherwise manage user accounts.", isDarkMode),
          _buildBulletPoint("To request feedback. We may process your information when necessary to request feedback and to contact you about your use of our Services.", isDarkMode),
          _buildBulletPoint("To protect our Services. We may process your information as part of our efforts to keep our Services safe and secure, including fraud monitoring and prevention.", isDarkMode),
          
          _buildSectionTitle('3. WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?', isDarkMode),
          _buildParagraph(
            "In Short: We may share information in specific situations described in this section and/or with the following third parties.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We may need to share your personal information in the following situations:",
            isDarkMode,
          ),
          _buildBulletPoint("Business Transfers. We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.", isDarkMode),
          
          _buildSectionTitle('4. DO WE USE COOKIES AND OTHER TRACKING TECHNOLOGIES?', isDarkMode),
          _buildParagraph(
            "In Short: We may use cookies and other tracking technologies to collect and store your information.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We may use cookies and similar tracking technologies (like web beacons and pixels) to gather information when you interact with our Services. Some online tracking technologies help us maintain the security of our Services and your account, prevent crashes, fix bugs, save your preferences, and assist with basic site functions.",
            isDarkMode,
          ),
          
          _buildSectionTitle('5. HOW DO WE HANDLE YOUR SOCIAL LOGINS?', isDarkMode),
          _buildParagraph(
            "In Short: If you choose to register or log in to our Services using a social media account, we may have access to certain information about you.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "Our Services offer you the ability to register and log in using your third-party social media account details (like your Facebook or X logins). Where you choose to do this, we will receive certain profile information about you from your social media provider. The profile information we receive may vary depending on the social media provider concerned, but will often include your name, email address, friends list, and profile picture, as well as other information you choose to make public on such a social media platform.",
            isDarkMode,
          ),
          
          _buildSectionTitle('6. HOW LONG DO WE KEEP YOUR INFORMATION?', isDarkMode),
          _buildParagraph(
            "In Short: We keep your information for as long as necessary to fulfil the purposes outlined in this Privacy Notice unless otherwise required by law.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We will only keep your personal information for as long as it is necessary for the purposes set out in this Privacy Notice, unless a longer retention period is required or permitted by law (such as tax, accounting, or other legal requirements). No purpose in this notice will require us keeping your personal information for longer than the period of time in which users have an account with us.",
            isDarkMode,
          ),
          
          _buildSectionTitle('7. HOW DO WE KEEP YOUR INFORMATION SAFE?', isDarkMode),
          _buildParagraph(
            "In Short: We aim to protect your personal information through a system of organisational and technical security measures.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We have implemented appropriate and reasonable technical and organisational security measures designed to protect the security of any personal information we process. However, despite our safeguards and efforts to secure your information, no electronic transmission over the Internet or information storage technology can be guaranteed to be 100% secure, so we cannot promise or guarantee that hackers, cybercriminals, or other unauthorised third parties will not be able to defeat our security and improperly collect, access, steal, or modify your information.",
            isDarkMode,
          ),
          
          _buildSectionTitle('8. DO WE COLLECT INFORMATION FROM MINORS?', isDarkMode),
          _buildParagraph(
            "In Short: We do not knowingly collect data from or market to children under 18 years of age.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We do not knowingly collect, solicit data from, or market to children under 18 years of age, nor do we knowingly sell such personal information. By using the Services, you represent that you are at least 18 or that you are the parent or guardian of such a minor and consent to such minor dependent's use of the Services. If we learn that personal information from users less than 18 years of age has been collected, we will deactivate the account and take reasonable measures to promptly delete such data from our records. If you become aware of any data we may have collected from children under age 18, please contact us at info@damakenya.org.",
            isDarkMode,
          ),
          
          _buildSectionTitle('9. WHAT ARE YOUR PRIVACY RIGHTS?', isDarkMode),
          _buildParagraph(
            "In Short: You may review, change, or terminate your account at any time, depending on your country, province, or state of residence.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "Withdrawing your consent: If we are relying on your consent to process your personal information, which may be express and/or implied consent depending on the applicable law, you have the right to withdraw your consent at any time. You can withdraw your consent at any time by contacting us.",
            isDarkMode,
          ),
          _buildSubsectionTitle('Account Information', isDarkMode),
          _buildParagraph(
            "If you would at any time like to review or change the information in your account or terminate your account, you can:",
            isDarkMode,
          ),
          _buildBulletPoint("Log in to your account settings and update your user account.", isDarkMode),
          _buildBulletPoint("Contact us using the contact information provided.", isDarkMode),
          _buildParagraph(
            "Upon your request to terminate your account, we will deactivate or delete your account and information from our active databases. However, we may retain some information in our files to prevent fraud, troubleshoot problems, assist with any investigations, enforce our legal terms and/or comply with applicable legal requirements.",
            isDarkMode,
          ),
          
          _buildSectionTitle('10. CONTROLS FOR DO-NOT-TRACK FEATURES', isDarkMode),
          _buildParagraph(
            "Most web browsers and some mobile operating systems and mobile applications include a Do-Not-Track ('DNT') feature or setting you can activate to signal your privacy preference not to have data about your online browsing activities monitored and collected. At this stage, no uniform technology standard for recognising and implementing DNT signals has been finalised. As such, we do not currently respond to DNT browser signals or any other mechanism that automatically communicates your choice not to be tracked online.",
            isDarkMode,
          ),
          
          _buildSectionTitle('11. DO WE MAKE UPDATES TO THIS NOTICE?', isDarkMode),
          _buildParagraph(
            "In Short: Yes, we will update this notice as necessary to stay compliant with relevant laws.",
            isDarkMode,
            isItalic: true,
          ),
          _buildParagraph(
            "We may update this Privacy Notice from time to time. The updated version will be indicated by an updated 'Revised' date at the top of this Privacy Notice. If we make material changes to this Privacy Notice, we may notify you either by prominently posting a notice of such changes or by directly sending you a notification. We encourage you to review this Privacy Notice frequently to be informed of how we are protecting your information.",
            isDarkMode,
          ),
          
          _buildSectionTitle('12. HOW CAN YOU CONTACT US ABOUT THIS NOTICE?', isDarkMode),
          _buildParagraph(
            "If you have questions or comments about this notice, you may email us at info@damakenya.org or contact us by post at:",
            isDarkMode,
          ),
          _buildContactInfo(isDarkMode),
          
          _buildSectionTitle('13. HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?', isDarkMode),
          _buildParagraph(
            "Based on the applicable laws of your country, you may have the right to request access to the personal information we collect from you, details about how we have processed it, correct inaccuracies, or delete your personal information. You may also have the right to withdraw your consent to our processing of your personal information. These rights may be limited in some circumstances by applicable law. To request to review, update, or delete your personal information, please visit: https://damakenya.org/",
            isDarkMode,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
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
          _buildBulletPoint("download or print a copy of any portion of the Content to which you have properly gained access,", isDarkMode),
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
          _buildParagraph("As a user of the Services, you agree not to:", isDarkMode),
          _buildBulletPoint("Systematically retrieve data or other content from the Services to create or compile, directly or indirectly, a collection, compilation, database, or directory without written permission from us.", isDarkMode),
          _buildBulletPoint("Trick, defraud, or mislead us and other users, especially in any attempt to learn sensitive account information such as user passwords.", isDarkMode),
          _buildBulletPoint("Circumvent, disable, or otherwise interfere with security-related features of the Services.", isDarkMode),
          _buildBulletPoint("Disparage, tarnish, or otherwise harm, in our opinion, us and/or the Services.", isDarkMode),
          _buildBulletPoint("Use any information obtained from the Services in order to harass, abuse, or harm another person.", isDarkMode),
          _buildBulletPoint("Make improper use of our support services or submit false reports of abuse or misconduct.", isDarkMode),
          _buildBulletPoint("Use the Services in a manner inconsistent with any applicable laws or regulations.", isDarkMode),
          _buildBulletPoint("Upload or transmit viruses, Trojan horses, or other material that interferes with any party's uninterrupted use and enjoyment of the Services.", isDarkMode),
          
          _buildSectionTitle('9. USER GENERATED CONTRIBUTIONS', isDarkMode),
          _buildParagraph(
            "The Services may invite you to chat, contribute to, or participate in blogs, message boards, online forums, and other functionality. Contributions may be viewable by other users of the Services and through third-party websites.",
            isDarkMode,
          ),
          _buildBulletPoint("Your Contributions are not false, inaccurate, or misleading.", isDarkMode),
          _buildBulletPoint("Your Contributions are not obscene, lewd, lascivious, filthy, violent, harassing, libellous, slanderous, or otherwise objectionable.", isDarkMode),
          _buildBulletPoint("Your Contributions do not ridicule, mock, disparage, intimidate, or abuse anyone.", isDarkMode),
          _buildBulletPoint("Your Contributions do not violate any applicable law, regulation, or rule.", isDarkMode),
          
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
          
          _buildSectionTitle('25. ELECTRONIC COMMUNICATIONS, TRANSACTIONS, AND SIGNATURES', isDarkMode),
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

/// Cookie Policy content widget
class _CookiePolicyContent extends StatelessWidget {
  final bool isDarkMode;
  
  const _CookiePolicyContent({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Cookie Policy', isDarkMode),
          _buildLastUpdated('March 06, 2026', isDarkMode),
          const SizedBox(height: 20),
          
          _buildParagraph(
            'This Cookie Policy explains how Dama Kenya ("Company," "we," "us," and "our") uses cookies and similar technologies to recognize you when you visit our website at https://damakenya.org ("Website"). It explains what these technologies are and why we use them, as well as your rights to control our use of them.',
            isDarkMode,
          ),
          _buildParagraph(
            "In some cases we may use cookies to collect personal information, or that becomes personal information if we combine it with other information.",
            isDarkMode,
          ),
          
          _buildSectionTitle('What are cookies?', isDarkMode),
          _buildParagraph(
            "Cookies are small data files that are placed on your computer or mobile device when you visit a website. Cookies are widely used by website owners in order to make their websites work, or to work more efficiently, as well as to provide reporting information.",
            isDarkMode,
          ),
          _buildParagraph(
            'Cookies set by the website owner (in this case, Dama Kenya) are called "first-party cookies." Cookies set by parties other than the website owner are called "third-party cookies." Third-party cookies enable third-party features or functionality to be provided on or through the website (e.g., advertising, interactive content, and analytics). The parties that set these third-party cookies can recognize your computer both when it visits the website in question and also when it visits certain other websites.',
            isDarkMode,
          ),
          
          _buildSectionTitle('Why do we use cookies?', isDarkMode),
          _buildParagraph(
            'We use first- and third-party cookies for several reasons. Some cookies are required for technical reasons in order for our Website to operate, and we refer to these as "essential" or "strictly necessary" cookies. Other cookies also enable us to track and target the interests of our users to enhance the experience on our Online Properties. Third parties serve cookies through our Website for advertising, analytics, and other purposes. This is described in more detail below.',
            isDarkMode,
          ),
          
          _buildSectionTitle('How can I control cookies?', isDarkMode),
          _buildParagraph(
            "You have the right to decide whether to accept or reject cookies. You can exercise your cookie rights by setting your preferences in the Cookie Preference Center. The Cookie Preference Center allows you to select which categories of cookies you accept or reject. Essential cookies cannot be rejected as they are strictly necessary to provide you with services.",
            isDarkMode,
          ),
          _buildParagraph(
            "The Cookie Preference Center can be found in the notification banner and on our Website. If you choose to reject cookies, you may still use our Website though your access to some functionality and areas of our Website may be restricted. You may also set or amend your web browser controls to accept or refuse cookies.",
            isDarkMode,
          ),
          
          _buildSectionTitle('Cookies we use', isDarkMode),
          _buildParagraph(
            "The specific types of first- and third-party cookies served through our Website and the purposes they perform are described below (please note that the specific cookies served may vary depending on the specific Online Properties you visit):",
            isDarkMode,
          ),
          _buildSubsectionTitle('Unclassified cookies:', isDarkMode),
          _buildParagraph(
            "These are cookies that have not yet been categorized. We are in the process of classifying these cookies with the help of their providers.",
            isDarkMode,
          ),
          _buildBulletPoint("Name: theme", isDarkMode),
          _buildBulletPoint("Provider: damakenya.org", isDarkMode),
          _buildBulletPoint("Type: html_local_storage", isDarkMode),
          _buildBulletPoint("Expires in: persistent", isDarkMode),
          
          _buildSectionTitle('How can I control cookies on my browser?', isDarkMode),
          _buildParagraph(
            "As the means by which you can refuse cookies through your web browser controls vary from browser to browser, you should visit your browser's help menu for more information. The following is information about how to manage cookies on the most popular browsers:",
            isDarkMode,
          ),
          _buildBulletPoint("Chrome", isDarkMode),
          _buildBulletPoint("Internet Explorer", isDarkMode),
          _buildBulletPoint("Firefox", isDarkMode),
          _buildBulletPoint("Safari", isDarkMode),
          _buildBulletPoint("Edge", isDarkMode),
          _buildBulletPoint("Opera", isDarkMode),
          
          _buildParagraph(
            "In addition, most advertising networks offer you a way to opt out of targeted advertising. If you would like to find out more information, please visit:",
            isDarkMode,
          ),
          _buildBulletPoint("Digital Advertising Alliance", isDarkMode),
          _buildBulletPoint("Digital Advertising Alliance of Canada", isDarkMode),
          _buildBulletPoint("European Interactive Digital Advertising Alliance", isDarkMode),
          
          _buildSectionTitle('What about other tracking technologies, like web beacons?', isDarkMode),
          _buildParagraph(
            'Cookies are not the only way to recognize or track visitors to a website. We may use other, similar technologies from time to time, like web beacons (sometimes called "tracking pixels" or "clear gifs"). These are tiny graphics files that contain a unique identifier that enables us to recognize when someone has visited our Website or opened an email including them. This allows us, for example, to monitor the traffic patterns of users from one page within a website to another, to deliver or communicate with cookies, to understand whether you have come to the website from an online advertisement displayed on a third-party website, to improve site performance, and to measure the success of email marketing campaigns. In many instances, these technologies are reliant on cookies to function properly, and so declining cookies will impair their functioning.',
            isDarkMode,
          ),
          
          _buildSectionTitle('Do you use Flash cookies or Local Shared Objects?', isDarkMode),
          _buildParagraph(
            'Websites may also use so-called "Flash Cookies" (also known as Local Shared Objects or "LSOs") to, among other things, collect and store information about your use of our services, fraud prevention, and for other site operations.',
            isDarkMode,
          ),
          _buildParagraph(
            "If you do not want Flash Cookies stored on your computer, you can adjust the settings of your Flash player to block Flash Cookies storage using the tools contained in the Website Storage Settings Panel. You can also control Flash Cookies by going to the Global Storage Settings Panel and following the instructions.",
            isDarkMode,
          ),
          _buildParagraph(
            "Please note that setting the Flash Player to restrict or limit acceptance of Flash Cookies may reduce or impede the functionality of some Flash applications.",
            isDarkMode,
          ),
          
          _buildSectionTitle('Do you serve targeted advertising?', isDarkMode),
          _buildParagraph(
            "Third parties may serve cookies on your computer or mobile device to serve advertising through our Website. These companies may use information about your visits to this and other websites in order to provide relevant advertisements about goods and services that you may be interested in. They may also employ technology that is used to measure the effectiveness of advertisements. They can accomplish this by using cookies or web beacons to collect information about your visits to this and other sites in order to provide relevant advertisements about goods and services of potential interest to you. The information collected through this process does not enable us or them to identify your name, contact details, or other details that directly identify you unless you choose to provide these.",
            isDarkMode,
          ),
          
          _buildSectionTitle('How often will you update this Cookie Policy?', isDarkMode),
          _buildParagraph(
            "We may update this Cookie Policy from time to time in order to reflect, for example, changes to the cookies we use or for other operational, legal, or regulatory reasons. Please therefore revisit this Cookie Policy regularly to stay informed about our use of cookies and related technologies.",
            isDarkMode,
          ),
          _buildParagraph(
            "The date at the top of this Cookie Policy indicates when it was last updated.",
            isDarkMode,
          ),
          
          _buildSectionTitle('Where can I get further information?', isDarkMode),
          _buildParagraph(
            "If you have any questions about our use of cookies or other technologies, please email us at support@damakenya.com or by post to:",
            isDarkMode,
          ),
          _buildParagraph(
            "Dama Kenya\nKenya, Nairobi",
            isDarkMode,
          ),
          
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
              color: isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
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
            color: isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
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
                style: TextStyle(
                  fontSize: 14,
                  color: kBlue,
                ),
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
              style: TextStyle(
                fontSize: 14,
                color: kBlue,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

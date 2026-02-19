import 'dart:io';

import 'package:dama/controller/article_count_controller.dart';
import 'package:dama/controller/auth_controller.dart';
import 'package:dama/controller/payment_controller.dart';
import 'package:dama/controller/plans_controller.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/plans_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/shimmer/plan_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Plan detail data for view details popup
class PlanDetailData {
  final String title;
  final String amount;
  final List<String> features;
  final List<String> benefits;
  final String? status;

  PlanDetailData({
    required this.title,
    required this.amount,
    required this.features,
    required this.benefits,
    this.status,
  });
}

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final PlansController _plansController = Get.put(PlansController());
  final PaymentController _paymentController = Get.put(PaymentController());
  final ArticleCountController _articleCountController = Get.put(
    ArticleCountController(),
  );

  final Utils _utils = Utils();
  
  String? completePhoneNumber;
  String? countryCode = '+254';
  late final GlobalKey<ScaffoldState> _planKey;

  // Use nullable boolean to track loading state
  final Rx<bool?> membershipExpired = Rx<bool?>(null);
  
  // Track membership certificate availability
  final RxBool hasMembershipCertificate = false.obs;
  final RxString memberId = ''.obs;
  final RxString membershipCertificateUrl = ''.obs;
  final RxString membershipCertificateDownloadUrl = ''.obs;

  @override
  void initState() {
    super.initState();
    _planKey = GlobalKey();
    // Check membership expiration first, before plans are loaded
    _checkUserPlanStatus();
    // Check membership certificate availability
    _checkMembershipCertificateStatus();
  }
  
  // Check if user has a membership certificate - first from local storage, then API
  Future<void> _checkMembershipCertificateStatus() async {
    try {
      // First, try to load from local storage (set during login)
      final localHasMembership = await StorageService.getData('hasMembership');
      final localMemberId = await StorageService.getData('memberId');
      final localMembershipExp = await StorageService.getData('membershipExp');
      final localCertUrl = await StorageService.getData('membershipCertificate');
      final localCertDownloadUrl = await StorageService.getData('membershipCertificateDownload');
      
      print('[PlansScreen] Local storage - hasMembership: $localHasMembership, certUrl: $localCertUrl, certDownloadUrl: $localCertDownloadUrl');
      
      // Check if membership is still valid (not expired)
      bool isMembershipValid = localHasMembership == true;
      if (isMembershipValid && localMembershipExp != null && localMembershipExp.toString().isNotEmpty) {
        try {
          final expiryDate = DateTime.parse(localMembershipExp.toString());
          if (expiryDate.isBefore(DateTime.now())) {
            isMembershipValid = false;
          }
        } catch (e) {
          // If parsing fails, assume membership is valid
        }
      }
      
      // Update state from local storage
      hasMembershipCertificate.value = isMembershipValid;
      memberId.value = localMemberId?.toString() ?? '';
      membershipCertificateUrl.value = localCertUrl?.toString() ?? '';
      membershipCertificateDownloadUrl.value = localCertDownloadUrl?.toString() ?? '';
      
      // If we have certificate URLs from local storage, we're done
      if (localCertUrl != null && localCertUrl.toString().isNotEmpty) {
        print('[PlansScreen] Using certificate URLs from local storage');
        return;
      }
      
      // Otherwise, fetch from API
      final userId = await StorageService.getData('userId');
      if (userId == null) {
        hasMembershipCertificate.value = false;
        return;
      }
      
      print('[PlansScreen] Fetching certificate data from API...');
      final apiService = ApiService();
      final profileData = await apiService.fetchUserProfile(userId.toString());
      
      if (profileData != null && profileData['user'] != null) {
        final user = profileData['user'];
        final hasMembership = user['hasMembership'] ?? false;
        final storedMemberId = user['memberId'] ?? '';
        final membershipExp = user['membershipExp'];
        
        // Extract certificate URLs from the API response
        final certUrl = user['membershipCertificate'] ?? '';
        final certDownloadUrl = user['membershipCertificateDownload'] ?? '';
        
        print('[PlansScreen] API returned - certUrl: $certUrl, certDownloadUrl: $certDownloadUrl');
        
        // Check if membership is still valid (not expired)
        bool isMembershipValid = hasMembership;
        if (hasMembership && membershipExp != null) {
          try {
            final expiryDate = DateTime.parse(membershipExp);
            if (expiryDate.isBefore(DateTime.now())) {
              isMembershipValid = false;
            }
          } catch (e) {
            // If parsing fails, assume membership is valid
          }
        }
        
        hasMembershipCertificate.value = isMembershipValid;
        memberId.value = storedMemberId.toString();
        membershipCertificateUrl.value = certUrl.toString();
        membershipCertificateDownloadUrl.value = certDownloadUrl.toString();
        
        // Update local storage with latest data
        await StorageService.storeData({
          'hasMembership': isMembershipValid,
          'memberId': storedMemberId,
          'membershipExp': membershipExp ?? '',
          'membershipCertificate': certUrl.toString(),
          'membershipCertificateDownload': certDownloadUrl.toString(),
        });
      }
    } catch (e) {
      print('[PlansScreen] Error checking certificate status: $e');
      // On error, try to use whatever we have in local storage
      try {
        final localHasMembership = await StorageService.getData('hasMembership');
        final localMemberId = await StorageService.getData('memberId');
        final localCertUrl = await StorageService.getData('membershipCertificate');
        final localCertDownloadUrl = await StorageService.getData('membershipCertificateDownload');
        
        hasMembershipCertificate.value = localHasMembership == true;
        memberId.value = localMemberId?.toString() ?? '';
        membershipCertificateUrl.value = localCertUrl?.toString() ?? '';
        membershipCertificateDownloadUrl.value = localCertDownloadUrl?.toString() ?? '';
      } catch (_) {
        hasMembershipCertificate.value = false;
      }
    }
  }
  
  // Show membership certificate dialog
  void _showMembershipCertificateDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : kWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Membership Certificate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Certificate Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Certificate Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kBlue, kBlue.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.card_membership,
                            size: 50,
                            color: kWhite,
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Certificate Title
                        Text(
                          'DAMA Kenya',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Professional Membership Certificate',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        
                        // Member ID
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Member ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                memberId.value.isNotEmpty ? memberId.value : 'N/A',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Membership Status
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Active Member',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // View Certificate Button - Opens PDF viewer
                      CustomButton(
                        callBackFunction: () {
                          Navigator.of(context).pop();
                          _viewMembershipCertificate();
                        },
                        label: "View Certificate",
                        backgroundColor: kBlue,
                      ),
                      SizedBox(height: 12),
                      // Download/Share Certificate Button
                      CustomButton(
                        callBackFunction: () {
                          Navigator.of(context).pop();
                          _downloadMembershipCertificate();
                        },
                        label: "Download & Share",
                        backgroundColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        textColor: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Download membership certificate
  void _downloadMembershipCertificate() async {
    // Prefer download URL, fallback to view URL converted to download
    String downloadUrl = membershipCertificateDownloadUrl.value;
    if (downloadUrl.isEmpty && membershipCertificateUrl.value.contains('/verify/')) {
      // Convert verify URL to download URL
      downloadUrl = membershipCertificateUrl.value.replaceAll('/verify/', '/download/');
    }
    
    if (downloadUrl.isEmpty) {
      Get.snackbar(
        'Not Available',
        'Certificate download is not available at the moment.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Show loading indicator
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      print('[PlansScreen] Downloading certificate from: $downloadUrl');
      
      // Download the PDF file
      final response = await http.get(Uri.parse(downloadUrl));
      
      // Close loading dialog
      Get.back();
      
      if (response.statusCode == 200) {
        // Get app documents directory
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'DAMA_Membership_Certificate_${memberId.value}.pdf';
        final file = File('${dir.path}/$fileName');
        
        // Save the file
        await file.writeAsBytes(response.bodyBytes);
        print('[PlansScreen] Certificate saved to: ${file.path}');
        
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'My DAMA Kenya Membership Certificate',
        );
      } else {
        // If download fails, fallback to browser
        print('[PlansScreen] Download failed with status ${response.statusCode}, falling back to browser');
        final uri = Uri.parse(downloadUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Close loading dialog
      Get.back();
      
      print('[PlansScreen] Error downloading certificate: $e');
      
      // Fallback to browser
      try {
        final uri = Uri.parse(downloadUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        Get.snackbar(
          'Error',
          'Failed to download certificate: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
  
  // View membership certificate - opens directly in PDF viewer
  void _viewMembershipCertificate() async {
    // Use download URL for viewing the actual PDF
    final certUrl = membershipCertificateDownloadUrl.value.isNotEmpty 
        ? membershipCertificateDownloadUrl.value 
        : membershipCertificateUrl.value;
    
    print('[PlansScreen] View Certificate clicked, URL: $certUrl');
    
    if (certUrl.isEmpty) {
      Get.snackbar(
        'Not Available',
        'Certificate is not available at the moment.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // For URLs containing '/verify/' - these are API endpoints that return JSON
    // We should use the download URL instead, but if we only have verify URL,
    // construct the download URL from it
    String viewUrl = certUrl;
    if (certUrl.contains('/verify/')) {
      // Convert verify URL to download URL
      viewUrl = certUrl.replaceAll('/verify/', '/download/');
      print('[PlansScreen] Converted verify URL to download URL: $viewUrl');
    }
    
    // Open certificate directly in app (PDF viewer will handle HTML fallback)
    print('[PlansScreen] Opening certificate directly in app: $viewUrl');
    _openCertificateInApp(viewUrl);
  }
  
  void _showCertificateOptionsDialog(String viewUrl) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDark;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.card_membership, color: kBlue),
              SizedBox(width: 12),
              Text(
                'Membership Certificate',
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how you want to access your certificate:',
                style: TextStyle(
                  color: isDarkMode ? kWhite.withOpacity(0.9) : kGrey,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              // Option 1: Download (Browser)
              _buildCertificateOption(
                context: context,
                icon: Icons.download,
                title: 'Download Certificate',
                subtitle: 'Save as PDF to your device',
                isPrimary: true,
                onTap: () {
                  Navigator.pop(context);
                  _openCertificateInBrowser(viewUrl);
                },
              ),
              SizedBox(height: 12),
              // Option 2: View in App
              _buildCertificateOption(
                context: context,
                icon: Icons.visibility,
                title: 'View in App',
                subtitle: 'Preview before downloading',
                isPrimary: false,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  _openCertificateInApp(viewUrl);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: kGrey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCertificateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool? isDarkMode,
  }) {
    final darkMode = isDarkMode ?? false;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary 
              ? kBlue.withOpacity(0.1) 
              : (darkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? kBlue.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPrimary ? kBlue : (darkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : (darkMode ? Colors.white : Colors.grey[700]),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: darkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: darkMode ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: darkMode ? Colors.white.withOpacity(0.4) : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openCertificateInApp(String viewUrl) async {
    print('[PlansScreen] Opening certificate in app: $viewUrl');
    
    // Show loading while we verify the URL is accessible
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      // Quick check to verify URL is accessible
      final accessToken = await StorageService.getData("access_token");
      final response = await http.head(
        Uri.parse(viewUrl),
        headers: accessToken != null && accessToken.isNotEmpty
            ? {'Authorization': 'Bearer $accessToken'}
            : {},
      ).timeout(Duration(seconds: 5));
      
      // Close loading dialog
      Get.back();
      
      print('[PlansScreen] URL check status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 405) {
        // 405 means HEAD not allowed but URL exists, still try to open
        // Navigate to PDF viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              pdfUrl: viewUrl,
              title: 'Membership Certificate',
            ),
          ),
        );
      } else {
        print('[PlansScreen] URL not accessible, opening in browser');
        _openCertificateInBrowser(viewUrl);
      }
    } catch (e) {
      // Close loading dialog
      Get.back();
      
      print('[PlansScreen] URL check failed: $e');
      // If check fails, still try to open PDF viewer - it has its own error handling
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: viewUrl,
            title: 'Membership Certificate',
          ),
        ),
      );
    }
  }

  void _openCertificateInBrowser(String url) async {
    try {
      print('[PlansScreen] Opening certificate in browser/download: $url');
      
      // Show loading indicator
      Get.dialog(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Opening browser...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
      
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      if (launched) {
        // Show success message
        Get.snackbar(
          'Browser Opened',
          'Your certificate is being downloaded. Check your downloads folder.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 4),
        );
      } else {
        // Try fallback
        final fallbackLaunched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!fallbackLaunched) {
          Get.snackbar(
            'Error',
            'Could not open certificate link. Please check if you have a browser installed.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      print('[PlansScreen] Error launching certificate URL: $e');
      Get.snackbar(
        'Error',
        'Failed to open certificate: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Check membership expiration and wait for it to complete
  Future<void> _checkUserPlanStatus() async {
    try {
      bool canRead =
          await _articleCountController.checkArticleLimitBeforeReading();
      membershipExpired.value = !canRead;
    } catch (e) {
      membershipExpired.value = true;
    }
  }

  // Define plan tiers for upgrade/downgrade logic
  int _getPlanTier(String planType) {
    switch (planType.toLowerCase()) {
      case "student":
        return 1;
      case "professional":
        return 2;
      case "corporate":
        return 3;
      default:
        return 0;
    }
  }

  String _getButtonText(String planType) {
    if (!_plansController.hasActivePlan.value) {
      return "Activate";
    }

    String currentPlan = _plansController.currentUserPlan.value;
    String planTypeLower = planType.toLowerCase();

    if (currentPlan == planTypeLower) {
      return "Active";
    }

    int currentTier = _getPlanTier(currentPlan);
    int targetTier = _getPlanTier(planTypeLower);

    if (targetTier > currentTier) {
      return "Upgrade";
    } else if (targetTier < currentTier) {
      return "Downgrade";
    } else {
      return "Activate";
    }
  }

  bool _isButtonEnabled(String planType) {
    if (membershipExpired.value == null) {
      return false;
    }

    if (membershipExpired.value == true) {
      return true;
    }

    if (!_plansController.hasActivePlan.value) {
      return true;
    }

    String currentPlan = _plansController.currentUserPlan.value;
    String planTypeLower = planType.toLowerCase();

    return currentPlan != planTypeLower;
  }

  Color _getButtonColor(String planType, String buttonText) {
    switch (buttonText) {
      case "Active":
        return kGreen;
      case "Upgrade":
        return Colors.orange;
      case "Downgrade":
        return kGrey;
      default:
        // For "Activate", use plan-specific color
        return _getPlanColor(planType);
    }
  }

  Color _getPlanColor(String planType) {
    switch (planType.toLowerCase()) {
      case "student":
        return kBlue;
      case "professional":
        return kYellow;
      case "corporate":
        return kOrange;
      default:
        return kBlue;
    }
  }

  // Get plan detail data for view details popup
  PlanDetailData _getPlanDetailData(String planType) {
    final lower = planType.toLowerCase();
    
    if (lower.contains('student')) {
      return PlanDetailData(
        title: 'Student',
        amount: '6,000',
        features: ['Latest News Updates'],
        benefits: ['Latest News Updates'],
      );
    } else if (lower.contains('professional')) {
      return PlanDetailData(
        title: 'Professional',
        amount: '12,000',
        features: [
          'Exclusive Member Area Access',
          'Training & Resources',
          'Event Discounts',
          'Networking Opportunities',
          'Job Platform & Forum Access',
        ],
        benefits: [
          'Exclusive Member Area Access',
          'Training & Resources',
          'Event Discounts',
          'Networking Opportunities',
          'Job Platform & Forum Access',
        ],
        status: 'Current Plan',
      );
    } else if (lower.contains('corporate')) {
      return PlanDetailData(
        title: 'Corporate',
        amount: '60,000',
        features: [
          'Company Certification',
          'High Visibility',
          'Event Perks',
          'Premium Training',
          'Exclusive Networking',
        ],
        benefits: [
          'Company Certification',
          'High Visibility',
          'Event Perks',
          'Premium Training',
          'Exclusive Networking',
        ],
      );
    } else {
      return PlanDetailData(
        title: planType,
        amount: '0',
        features: [],
        benefits: [],
      );
    }
  }

  // Build the "Not Available" disabled button with lock icon
  Widget _buildNotAvailableButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.lock,
            size: 14,
            color: Colors.grey,
          ),
          SizedBox(width: 8),
          Text(
            "Not Available",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Build the "View Certificate" button for membership certificate
  Widget _buildViewCertificateButton(BuildContext context, bool hasCertificate, bool isDarkMode) {
    if (!hasCertificate) {
      // User doesn't have membership - show disabled button
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.lock,
              size: 14,
              color: Colors.grey,
            ),
            SizedBox(width: 8),
            Text(
              "No Certificate Available",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // User has membership - show active button that opens certificate directly
    return CustomButton(
      callBackFunction: () {
        _viewMembershipCertificate();
      },
      label: "View Certificate",
      backgroundColor: kBlue,
    );
  }

  void _showPlanDetailsPopup(BuildContext context, String planType, bool isDarkMode) {
    final planData = _getPlanDetailData(planType);
    final planLower = planType.toLowerCase();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : kWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        planData.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Ksh ",
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              planData.amount,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "/year",
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Features Included
                        Text(
                          "Features Included",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...planData.features.map((feature) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        SizedBox(height: 24),
                        
                        // Benefits
                        Text(
                          "Benefits",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...planData.benefits.map((benefit) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        // Status badge (if applicable)
                        if (planData.status != null) ...[
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: planData.status == 'Current Plan' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: planData.status == 'Current Plan' 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  planData.status == 'Current Plan' 
                                    ? Icons.check_circle 
                                    : Icons.upgrade,
                                  color: planData.status == 'Current Plan' 
                                    ? Colors.green 
                                    : Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  planData.status!,
                                  style: TextStyle(
                                    color: planData.status == 'Current Plan' 
                                      ? Colors.green 
                                      : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Action buttons based on plan type
                        SizedBox(height: 24),
                        
                        // Student plan: Not Available button
                        if (planLower.contains('student')) ...[
                          _buildNotAvailableButton(),
                        ],
                        
                        // Corporate plan: Upgrade button
                        if (planLower.contains('corporate')) ...[
                          CustomButton(
                            callBackFunction: () {
                              Navigator.of(context).pop();
                              // Find the corporate plan and show payment bottom sheet
                              final corporatePlan = _plansController.plansList.firstWhereOrNull(
                                (p) => p.membership.toLowerCase().contains('corporate'),
                              );
                              if (corporatePlan != null) {
                                final icon = FontAwesomeIcons.building;
                                _showFullMessageBottomSheet(
                                  context,
                                  corporatePlan.membership,
                                  isDarkMode,
                                  corporatePlan.price,
                                  icon,
                                  corporatePlan.id,
                                  corporatePlan.type,
                                );
                              }
                            },
                            label: "Upgrade",
                            backgroundColor: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullMessageBottomSheet(
    BuildContext context,
    String membership,
    bool isDark,
    int amount,
    IconData icon,
    String planID,
    String plan,
  ) {
    // Check if button should be enabled before showing bottom sheet
    if (!_isButtonEnabled(membership)) {
      Get.snackbar(
        'Info',
        'This is your current active plan',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String buttonText = _getButtonText(membership);
            Color buttonColor = _getButtonColor(membership, buttonText);

            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: kBGColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Icon(
                            membership.toLowerCase() == "student"
                                ? FontAwesomeIcons.graduationCap
                                : membership.toLowerCase() == "professional"
                                ? FontAwesomeIcons.briefcase
                                : FontAwesomeIcons.building,
                            size: 30,
                            color: kBlue,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Text(
                          membership,
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            color: isDark ? kWhite : kBlack,
                          ),
                        ),
                      ),

                      // Show current plan status using controller observables
                      Obx(() {
                        if (_plansController.hasActivePlan.value &&
                            membershipExpired.value != true) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: kSidePadding,
                            ),
                            child: Container(
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Current Plan: ${_plansController.currentUserPlan.value.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.lock, color: kGrey, size: 15),
                            SizedBox(width: 10),
                            Text(
                              "Payments are secure & encrypted",
                              style: TextStyle(color: kGrey),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phone Number *",
                              style: TextStyle(
                                color: isDark ? kWhite : kBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: kNormalTextSize,
                              ),
                            ),
                            SizedBox(height: 8),
                            IntlPhoneField(
                              decoration: InputDecoration(
                                hintText: "7*******",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: kBlue, width: 1.0),
                                ),
                              ),
                              style: TextStyle(
                                color: isDark ? kWhite : kBlack,
                              ),
                              dropdownTextStyle: TextStyle(
                                color: isDark ? kWhite : kBlack,
                              ),
                              dropdownIcon: Icon(
                                Icons.arrow_drop_down,
                                color: isDark ? kWhite : kBlack,
                              ),
                              initialCountryCode: 'KE',
                              onChanged: (PhoneNumber phone) {
                                completePhoneNumber = phone.completeNumber;
                              },
                              onCountryChanged: (country) {
                                countryCode = '+${country.dialCode}';
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Text(
                          'Breakdown',
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            color: isDark ? kWhite : kBlack,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "KES $amount",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? kWhite : kBlack,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text("/year", style: TextStyle(color: kGrey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Container(height: 1, color: kGrey),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total",
                              style: TextStyle(
                                color: isDark ? kWhite : kBlack,
                                fontSize: kBigTextSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "KES $amount",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: kBigTextSize,
                                color: isDark ? kWhite : kBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                        child: CustomButton(
                          callBackFunction:
                              buttonText == "Active"
                                  ? null
                                  : () {
                                    if (completePhoneNumber != null && completePhoneNumber!.isNotEmpty) {
                                      _payForPlan(
                                        context,
                                        amount,
                                        planID,
                                        completePhoneNumber!,
                                        plan,
                                        isDark,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a phone number',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                          label: "Confirm $buttonText",
                          backgroundColor:
                              buttonText == "Active"
                                  ? buttonColor.withOpacity(0.6)
                                  : buttonColor,
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _payForPlan(
    BuildContext context,
    price,
    planID,
    phoneNumber,
    plan,
    isDark,
  ) async {
    _paymentController.amountToPay.value = price;
    _paymentController.model.value = 'Plan';
    _paymentController.object_id.value = planID;
    _paymentController.phoneNumber.value = phoneNumber;

    final result = await _paymentController.pay(context);

    // Refresh both controller and local membership status
    await _plansController.refreshPlanStatus();
    await _checkUserPlanStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _planKey.currentContext;
      if (context != null && context.mounted) {
        showSuccessPlanPurchase(context, plan, price, isDark);
      } else {
        ScaffoldMessenger.of(
          _planKey.currentContext!,
        ).showSnackBar(SnackBar(content: Text('Payment successful!')));
      }
    });
  }

  void showSuccessPlanPurchase(
    BuildContext context,
    String? plan,
    int price,
    bool isDark,
  ) {
    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
      backgroundColor: isDark ? kBlack : kWhite,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            bottom: true,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 100),
                  SizedBox(height: 20),
                  Text(
                    'Subscription Confirmed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Thank you for subscribing to the $plan plan.",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'KES: $price',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return SafeArea(
      bottom: true,
      child: Obx(
        () => Stack(
          children: [
            Scaffold(
              key: _planKey,
              backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: isDarkMode ? kBlack : kWhite,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 30,
                        left: kSidePadding,
                        right: kSidePadding,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    color: isDarkMode ? kWhite : kBlack,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Membership Icon
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.workspace_premium,
                                color: kBlue,
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_membership,
                                  color: isDarkMode ? kWhite : kBlack,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Membership Plans",
                                  style: TextStyle(
                                    color: isDarkMode ? kWhite : kBlack,
                                    fontSize: kBigTextSize + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Subtitle
                            Text(
                              "Upgrade your DAMA experience",
                              style: TextStyle(
                                color: isDarkMode ? kGrey : kGrey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 600),
                        child: Obx(() {
                          // Wait for membership expiration check to complete first
                          if (membershipExpired.value == null) {
                            return ListView(
                              children: List.generate(
                                3,
                                (_) => const PlanCardSkeleton(),
                              ),
                            );
                          }

                          // Then wait for plans to load and plan status to be checked
                          if (_plansController.isLoading.value ||
                              _plansController.isLoadingPlanStatus.value) {
                            return ListView(
                              children: List.generate(
                                3,
                                (_) => const PlanCardSkeleton(),
                              ),
                            );
                          }

                          if (_plansController.plansList.isEmpty) {
                            return Center(child: Text("No plans available"));
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _plansController.plansList.length,
                            itemBuilder: (context, index) {
                              final plan = _plansController.plansList[index];
                              String buttonText = _getButtonText(
                                plan.membership,
                              );
                              bool isEnabled = _isButtonEnabled(
                                plan.membership,
                              );
                              Color buttonColor = _getButtonColor(
                                plan.membership,
                                buttonText,
                              );
                              final planLower = plan.membership.toLowerCase();
                              final icon = planLower == "student"
                                  ? FontAwesomeIcons.graduationCap
                                  : planLower == "professional"
                                      ? FontAwesomeIcons.briefcase
                                      : FontAwesomeIcons.building;
                              
                              // Determine button configuration based on plan type
                              if (planLower == "student") {
                                // Student: Not Available button + View Details
                                return plansCard(
                                  icon: icon,
                                  amount: plan.price.toString(),
                                  plan: plan.membership,
                                  buttonText: "View Details",
                                  isEnabled: true,
                                  buttonColor: kBlue,
                                  onPrimaryClick: () => _showPlanDetailsPopup(
                                    context,
                                    plan.membership,
                                    isDarkMode,
                                  ),
                                  showViewDetails: false,
                                  secondaryButton: _buildNotAvailableButton(),
                                );
                              } else if (planLower == "professional") {
                                // Professional: Active (disabled) + View Certificate + View Details
                                return Obx(() => plansCard(
                                  icon: icon,
                                  amount: plan.price.toString(),
                                  plan: plan.membership,
                                  buttonText: "Active",
                                  isEnabled: false,
                                  buttonColor: Colors.green,
                                  onPrimaryClick: () {},
                                  onViewDetails: () => _showPlanDetailsPopup(
                                    context,
                                    plan.membership,
                                    isDarkMode,
                                  ),
                                  showViewDetails: true,
                                  secondaryButton: _buildViewCertificateButton(
                                    context, 
                                    hasMembershipCertificate.value,
                                    isDarkMode,
                                  ),
                                ));
                              } else {
                                // Corporate: Upgrade + View Details
                                return plansCard(
                                  icon: icon,
                                  amount: plan.price.toString(),
                                  plan: plan.membership,
                                  buttonText: buttonText == "Active" ? "Active" : "Upgrade",
                                  isEnabled: buttonText != "Active",
                                  buttonColor: buttonText == "Active" ? Colors.green : Colors.orange,
                                  onPrimaryClick: () => _showFullMessageBottomSheet(
                                    context,
                                    plan.membership,
                                    isDarkMode,
                                    plan.price,
                                    icon,
                                    plan.id,
                                    plan.type,
                                  ),
                                  onViewDetails: () => _showPlanDetailsPopup(
                                    context,
                                    plan.membership,
                                    isDarkMode,
                                  ),
                                  showViewDetails: true,
                                );
                              }
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_paymentController.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              ),
          ],
        ),
      ),
    );
  }
}

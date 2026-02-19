import 'dart:async';

import 'package:dama/controller/update_user_profile_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ProfessionalDetails extends StatefulWidget {
  const ProfessionalDetails({super.key});

  @override
  State<ProfessionalDetails> createState() => _ProfessionalDetailsState();
}

class _ProfessionalDetailsState extends State<ProfessionalDetails> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _briefBioController = TextEditingController();

  String userImageUrl = '';
  String firstName = '';
  String middleName = '';
  String lastName = '';
  String selectedNationality = '';
  String selectedCounty = '';
  String phoneNumber = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    print('=== PROFESSIONAL DETAILS - LOADING DATA ===');
    
    String? image = await StorageService.getData("userImageUrl");
    String? fName = await StorageService.getData("firstName");
    String? mName = await StorageService.getData("middleName");
    String? lName = await StorageService.getData("lastName");
    String? nationality = await StorageService.getData("selectedNationality");
    String? county = await StorageService.getData("selectedCounty");
    String? phone = await StorageService.getData("phoneNumber");
    String? userId = await StorageService.getData("userId");
    String? storedPassword = await StorageService.getData("password");
    
    // Load LinkedIn-specific data
    String? linkedInTitle = await StorageService.getData("title");
    String? linkedInCompany = await StorageService.getData("company");
    String? linkedInBrief = await StorageService.getData("brief");

    print('[ProfDetails] Loaded Data:');
    print('  userId: $userId');
    print('  firstName: $fName');
    print('  lastName: $lName');
    print('  nationality (from selectedNationality): $nationality');
    print('  county: $county');
    print('  phone: $phone');
    print('  password: ${storedPassword != null ? "[SET]" : "[EMPTY]"}');
    print('  linkedInTitle: $linkedInTitle');
    print('  linkedInCompany: $linkedInCompany');
    print('==========================================');

    setState(() {
      userImageUrl = image ?? '';
      firstName = fName ?? '';
      middleName = mName ?? '';
      lastName = lName ?? '';
      selectedNationality = nationality ?? '';
      selectedCounty = county ?? '';
      phoneNumber = phone ?? '';
      password = storedPassword ?? '';
      
      // Pre-populate LinkedIn data if available
      _titleController.text = linkedInTitle ?? '';
      _companyController.text = linkedInCompany ?? '';
      _briefBioController.text = linkedInBrief ?? '';
    });
    
    print('[ProfDetails] State updated:');
    print('  selectedNationality: $selectedNationality');
  }

  final GlobalKey<FormState> _professionalKey = GlobalKey<FormState>();

  final UpdateUserProfileController updateUserProfileController = Get.put(
    UpdateUserProfileController(),
  );

  final AuthService _authService = AuthService();

  void _submitDetails() async {
    print('=== PROFESSIONAL DETAILS - SUBMITTING ===');
    
    if (!_professionalKey.currentState!.validate()) {
      print('Validation failed');
      return;
    }

    print('Setting controller values:');
    print('  firstName: $firstName');
    print('  lastName: $lastName');
    print('  phoneNumber: $phoneNumber');
    print('  nationality: $selectedNationality');
    print('  password: ${password.isNotEmpty ? "[SET]" : "[EMPTY]"}');
    print('  title: ${_titleController.text}');
    print('  company: ${_companyController.text}');
    print('  brief: ${_briefBioController.text}');

    updateUserProfileController.profilePicture.value = userImageUrl;
    updateUserProfileController.firstName.value = firstName;
    updateUserProfileController.middleName.value = middleName;
    updateUserProfileController.lastName.value = lastName;
    updateUserProfileController.nationality.value = selectedNationality;
    updateUserProfileController.county.value = selectedCounty;
    updateUserProfileController.phoneNumber.value = phoneNumber.replaceAll(
      '+',
      '',
    );
    updateUserProfileController.title.value = _titleController.text;
    updateUserProfileController.company.value = _companyController.text;
    updateUserProfileController.brief.value = _briefBioController.text;
    
    // Set password and password_set flag
    if (password.isNotEmpty) {
      updateUserProfileController.password.value = password;
      updateUserProfileController.passwordSet.value = true;
      print('  password_set: true');
    }

    // Call update and wait for completion using a completer
    final completer = Completer<void>();
    
    // Listen for loading state changes
    ever(updateUserProfileController.isLoading, (bool loading) {
      if (!loading && !completer.isCompleted) {
        completer.complete();
      }
    });
    
    // Trigger the update
    print('Triggering updateUser...');
    updateUserProfileController.updateUser();
    
    // Wait for update to complete
    await completer.future;
    print('Update completed');
    
    // After successful professional details submission, initiate 2FA for all users
    // including LinkedIn users (to verify phone number via OTP)
    print('Initiating 2FA...');
    await _initiate2faAndNavigate();
  }

  Future<void> _initiate2faAndNavigate() async {
    print('=== 2FA INITIATION STARTED ===');
    try {
      // Verify we have required data
      final token = await StorageService.getData('access_token');
      final userId = await StorageService.getData('userId');
      final email = await StorageService.getData('email');
      final phone = await StorageService.getData('phoneNumber');
      
      print('[2FA] Data from Storage:');
      print('  Token exists: ${token != null && token.isNotEmpty}');
      print('  Token length: ${token?.length ?? 0}');
      print('  UserId: $userId');
      print('  Email: $email');
      print('  Phone: $phone');
      print('================================');
      
      // Show loading
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Store OTP flow flag for professional details flow
      await StorageService.storeData({'otp_flow': 'professional_details'});
      print('[2FA] Stored otp_flow flag');
      
      // Call initiate2fa API to trigger OTP
      print('[2FA] Calling initiate2fa endpoint...');
      final result = await _authService.initiate2fa();
      
      // Close loading dialog
      Get.back();

      print('[2FA] initiate2fa returned: $result');

      if (result != null) {
        print('[2FA] OTP initiated successfully, navigating to OTP screen');
        Get.offAllNamed(AppRoutes.otp);
      } else {
        print('[2FA] initiate2fa returned null, but still navigating to OTP screen');
        Get.offAllNamed(AppRoutes.otp);
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('[2FA] Error in _initiate2faAndNavigate: $e');
      
      // Show error but still allow user to proceed to OTP
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Notice",
        "Could not send OTP: $e",
        colorText: kWhite,
        backgroundColor: kOrange.withOpacity(0.9),
        duration: Duration(seconds: 5),
      );
      
      // Still navigate to OTP screen so user can try
      Future.delayed(Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.otp);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _briefBioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Obx(
      () => Scaffold(
        backgroundColor:  isDarkMode ? kDarkThemeBg : kWhite,
        body: Form(
          key: _professionalKey,
          child: Stack(
            children: [
              ListView(
                children: [
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: kSidePadding,
                            vertical: 5,
                          ),
                          child: Text(
                            'Step 2 of 3',
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlue,
                              fontSize: kNormalTextSize,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: kSidePadding,
                            bottom: 10,
                          ),
                          child: Text(
                            "Fill in your professional details",
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                              fontSize: kBigTextSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Text(
                            'We need your personal infomation to setup your profile.',
                            style: TextStyle(fontSize: kNormalTextSize, color: isDarkMode ? kWhite : kBlack),
                          ),
                        ),
                        InputField(
                          controller: _titleController,
                          hintText: "Accountant",
                          label: "Title:",
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "This field is required";
                            }
                            return null;
                          },
                        ),
                        InputField(
                          controller: _companyController,
                          hintText: "Karatasi Brands",
                          label: "Company / Institution",
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "This field is required";
                            }
                            return null;
                          },
                        ),
                        InputField(
                          controller: _briefBioController,
                          hintText: "Type your bio here",
                          label: "Brief Bio:",
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "This field is required";
                            }
                            return null;
                          },
                          maxLines: 6,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: kSidePadding,
                          ),
                          child: CustomButton(
                            callBackFunction: () {
                              _submitDetails();
                            },
                            label: "Finish",
                            backgroundColor: kBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (updateUserProfileController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(child: customSpinner),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

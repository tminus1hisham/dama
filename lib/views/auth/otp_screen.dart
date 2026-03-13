import 'package:dama/controller/otp_verification_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.isReset = false, this.newPassword = ''});

  final bool isReset;
  final String newPassword;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController pinController;
  late final FocusNode focusNode;

  final OtpVerificationController _authController = Get.put(
    OtpVerificationController(),
  );

  String? userId;
  String? phoneNumber;
  bool isPhoneUpdate = false;
  String _otpFlow =
      'login'; // 'login' or 'registration' or 'professional_details' or 'phone_update'
  String _pageTitle = 'OTP Verification';
  String _pageSubtitle = 'We sent an OTP verification to the registered number';
  String _buttonLabel = 'Verify Phone Number';
  String _stepIndicator =
      ''; // Empty for login flow, 'Step 3 of 3' for profile setup

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    focusNode = FocusNode();

    // Check if this is a phone update flow from profile settings
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map) {
      isPhoneUpdate = arguments['isPhoneUpdate'] ?? false;
      phoneNumber = arguments['phone'];
      if (isPhoneUpdate) {
        _otpFlow = 'phone_update';
        _pageTitle = 'Verify Phone Number';
        _pageSubtitle = 'Enter the OTP sent to your new phone number';
        _buttonLabel = 'Verify Number';
        _stepIndicator = '';
      }
    }

    _fetchData().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    });
  }

  Future<void> _fetchData() async {
    String? fetchedUserId = await StorageService.getData('userId');
    String? otpFlow = await StorageService.getData('otp_flow');
    setState(() {
      userId = fetchedUserId;
      if (!isPhoneUpdate) {
        _otpFlow = otpFlow ?? 'login';
      }
      // Update text based on flow
      if (_otpFlow == 'professional_details') {
        _pageTitle = 'Verify Your Phone';
        _pageSubtitle =
            'Enter the OTP sent to your phone to complete your profile setup';
        _buttonLabel = 'Verify & Continue';
        _stepIndicator = 'Step 3 of 3';
      } else if (_otpFlow == 'registration') {
        _pageTitle = 'Verify Your Phone';
        _pageSubtitle =
            'Enter the OTP sent to your phone to complete registration';
        _buttonLabel = 'Verify & Continue';
        _stepIndicator = '';
      }
    });
  }

  void _verifyOtp() async {
    final enteredOtp = pinController.text.trim();

    if (isPhoneUpdate && phoneNumber != null) {
      // Phone update verification flow
      _authController.otp.value = enteredOtp;
      _authController.verifyPhoneUpdate(enteredOtp, phoneNumber!);
      return;
    }

    // Regular login/registration OTP verification
    if (userId == null || userId!.isEmpty) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "User ID not found. Please try logging in again.",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return;
    }

    _authController.otp.value = enteredOtp;
    _authController.userId.value = userId!;

    _authController.verifyOtp(context);
  }

  void _resendOtp() {
    // Show info message about OTP resend
    // NOTE: Backend doesn't have a dedicated resend OTP endpoint currently.
    // For LinkedIn users in the professional_details flow, the OTP should be
    // sent automatically or through alternative backend means.
    Get.snackbar(
      margin: EdgeInsets.only(top: 15, left: 15, right: 15),
      "Info",
      "If you haven't received the OTP, please check your SMS or try logging in again.",
      colorText: kWhite,
      backgroundColor: kBlue.withOpacity(0.9),
      duration: Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    final defaultPinTheme = PinTheme(
      width: screenWidth * 0.19,
      height: screenHeight * 0.09,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBlue),
      ),
    );

    return Obx(
      () => Scaffold(
        backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    if (_stepIndicator.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        child: Text(
                          _stepIndicator,
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlue,
                            fontSize: kNormalTextSize,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Image.asset(
                        'images/light_otp.png',
                        height: screenHeight * 0.1,
                      ),
                    ),
                    Center(
                      child: Text(
                        _pageTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        _pageSubtitle,
                        style: TextStyle(color: isDarkMode ? kWhite : kGrey),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Pinput(
                          length: 6,
                          controller: pinController,
                          focusNode: focusNode,
                          defaultPinTheme: defaultPinTheme,
                          separatorBuilder: (index) => const SizedBox(width: 8),
                          keyboardType: TextInputType.number,
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                          cursor: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 9),
                                width: 30,
                                height: 1,
                                color: kBlue,
                              ),
                            ],
                          ),
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kGreen),
                            ),
                          ),
                          submittedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kGreen),
                            ),
                          ),
                          errorPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(color: kBlue),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      child: CustomButton(
                        backgroundColor: kBlue,
                        callBackFunction: _verifyOtp,
                        label: _buttonLabel,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the OTP? ",
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                            ),
                          ),
                          GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Click Resend',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_authController.isLoading.value)
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

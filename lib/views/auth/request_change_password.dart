import 'package:dama/controller/request_change_password.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

class RequestChangePassword extends StatefulWidget {
  const RequestChangePassword({super.key});

  @override
  State<RequestChangePassword> createState() => _RequestChangePasswordState();
}

class _RequestChangePasswordState extends State<RequestChangePassword> {
  final GlobalKey<FormState> _requestPassowordKey = GlobalKey<FormState>();

  final RequestChangePasswordController _requestController = Get.put(
    RequestChangePasswordController(),
  );

  String? completePhoneNumber;
  String? countryCode = '+254';

  void _requestOtp() async {
    if (!_requestPassowordKey.currentState!.validate()) {
      return;
    }

    _requestController.phone_number.value = completePhoneNumber ?? '';
    _requestController.requestChangePassword(context);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  return SizedBox(
                    width: width > 600 ? 500 : width * 1,
                    child: Form(
                      key: _requestPassowordKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HeroThemeAwareLogo(
                                tag: "logo",
                                height: 100,
                                width: 150,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Center(
                                child: Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                    color: isDarkMode ? kWhite : kBlack,
                                    fontSize: kBigTextSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  "Enter your number to request for OTP",
                                  style: TextStyle(
                                    fontSize: kTitleTextSize,
                                    color: isDarkMode ? kWhite : kBlack,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: kSidePadding,
                                  vertical: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        "Phone Number *",
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                    ),
                                    IntlPhoneField(
                                      decoration: InputDecoration(
                                        hintText: "712345678",
                                        hintStyle: TextStyle(
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
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
                                        color: isDarkMode ? kWhite : kBlack,
                                      ),
                                      dropdownTextStyle: TextStyle(
                                        color: isDarkMode ? kWhite : kBlack,
                                      ),
                                      dropdownIcon: Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode ? kWhite : kBlack,
                                      ),
                                      initialCountryCode: 'KE',
                                      disableLengthCheck: true, // Disable default country-based validation
                                      validator: (PhoneNumber? phone) {
                                        if (phone == null || phone.number.isEmpty) {
                                          return 'Please enter a phone number';
                                        }
                                        if (phone.number.length != 9) {
                                          return 'Phone number must be exactly 9 digits';
                                        }
                                        // Ensure phone number contains only digits
                                        if (!RegExp(r'^[0-9]+$').hasMatch(phone.number)) {
                                          return 'Phone number must contain only digits';
                                        }
                                        return null;
                                      },
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: CustomButton(
                                  callBackFunction: _requestOtp,
                                  label: "Request OTP",
                                  backgroundColor: kBlue,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.04),
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: kNormalTextSize,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: TextStyle(
                                          color: kBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                Get.offAllNamed(
                                                  AppRoutes.login,
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Obx(() {
              if (!_requestController.isLoading.value) return SizedBox.shrink();
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              );
            }),
          ],
        ),
      ),
    );
  }
}
import 'package:dama/controller/request_change_password.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RequestChangePassword extends StatefulWidget {
  const RequestChangePassword({super.key});

  @override
  State<RequestChangePassword> createState() => _RequestChangePasswordState();
}

class _RequestChangePasswordState extends State<RequestChangePassword> {
  final GlobalKey<FormState> _requestPassowordKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  final RequestChangePasswordController _requestController = Get.put(
    RequestChangePasswordController(),
  );

  String normalizePhoneNumber(String input) {
    String cleaned = input.trim().replaceAll(RegExp(r'\s+'), '');

    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.length == 9 && cleaned.startsWith('7')) {
      return '254$cleaned';
    } else if (cleaned.startsWith('254') && cleaned.length == 12) {
      return cleaned;
    }

    return cleaned;
  }

  void _requestOtp() async {
    if (!_requestPassowordKey.currentState!.validate()) {
      return;
    }

    _requestController.phone_number.value = normalizePhoneNumber(
      _phoneNumberController.text,
    );
    _requestController.requestChangePassword(context);
  }

  @override
  void dispose() {
    super.dispose();
    _phoneNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Obx(
      () => Scaffold(
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
                                      fontSize: 15,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: DropdownButton<String>(
                                              value: '+254',
                                              items: [
                                                DropdownMenuItem(
                                                  value: '+254',
                                                  child: Text(
                                                    '+254',
                                                    style: TextStyle(
                                                      color:
                                                          isDarkMode
                                                              ? kWhite
                                                              : kBlack,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: null,
                                              underline: SizedBox(),
                                              style: TextStyle(
                                                color:
                                                    isDarkMode
                                                        ? kWhite
                                                        : kBlack,
                                              ),
                                              dropdownColor:
                                                  isDarkMode
                                                      ? kDarkThemeBg
                                                      : kWhite,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _phoneNumberController,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return "This field is required";
                                                }
                                                return null;
                                              },
                                              keyboardType: TextInputType.phone,
                                              style: TextStyle(
                                                color:
                                                    isDarkMode
                                                        ? kWhite
                                                        : kBlack,
                                              ),
                                              cursorColor:
                                                  isDarkMode ? kWhite : kBlue,
                                              decoration: InputDecoration(
                                                hintText: "7*******",
                                                hintStyle: TextStyle(
                                                  color:
                                                      isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[700],
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.0,
                                                      ),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10.0,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: kBlue,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
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
                                            decoration:
                                                TextDecoration.underline,
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
              if (_requestController.isLoading.value)
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

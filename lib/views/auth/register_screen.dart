import 'package:dama/controller/register_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final RegisterController registerController = Get.find<RegisterController>();
  
  String? completePhoneNumber;
  String? countryCode = '+254';

  final GlobalKey<FormState> _registerKey = GlobalKey<FormState>();

  String fcmToken = '';

  @override
  void initState() {
    super.initState();
    _fetchFcmToken();
  }

  void _fetchFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("Fetched FCM token: $token");
      if (token != null) {
        setState(() {
          fcmToken = token;
        });
      }
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
  }

  void _register() async {
    print("Register button clicked");
    if (!_registerKey.currentState!.validate()) {
      print("Form validation failed");
      return;
    }
    print("Form validation passed");

    // Ensure FCM token is available
    if (fcmToken.isEmpty) {
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        print("Fetched FCM token in register: $token");
        if (token != null) {
          setState(() {
            fcmToken = token;
          });
        }
      } catch (e) {
        print("Error fetching FCM token in register: $e");
      }
    }

    registerController.firstName.value = '';
    registerController.middleName.value = '';
    registerController.lastName.value = '';
    registerController.email.value = _emailController.text;
    registerController.password.value = _passwordController.text;
    registerController.phone.value = completePhoneNumber ?? '';
    registerController.fcmToken.value = fcmToken;
    print("FCM Token: $fcmToken");
    print("Calling register controller");
    registerController.register(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Obx(
      () => Scaffold(
        backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double width = constraints.maxWidth;

                      return SizedBox(
                        width: width > 600 ? 500 : width * 1,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Form(
                              key: _registerKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  HeroThemeAwareLogo(
                                    tag: "logo",
                                    height: 80,
                                    width: 120,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Center(
                                    child: Text(
                                      "Create Account",
                                      style: TextStyle(
                                        color: isDarkMode ? kWhite : kBlack,
                                        fontSize: kBigTextSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      "Stay updated in your professional world",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDarkMode ? kWhite : kBlack,
                                      ),
                                    ),
                                  ),
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
                                        FormField<String>(
                                          validator: (value) {
                                            if (completePhoneNumber == null || completePhoneNumber!.isEmpty) {
                                              return "Phone number is required";
                                            }
                                            return null;
                                          },
                                          builder: (FormFieldState<String> state) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                IntlPhoneField(
                                                  decoration: InputDecoration(
                                                    hintText: "7*******",
                                                    hintStyle: TextStyle(
                                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                                    ),
                                                    errorText: state.errorText ?? (registerController.phoneError.value.isEmpty ? null : registerController.phoneError.value),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                      borderSide: BorderSide(color: kBlue, width: 1.0),
                                                    ),
                                                    errorBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                      borderSide: BorderSide(color: Colors.red, width: 1.0),
                                                    ),
                                                    focusedErrorBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                      borderSide: BorderSide(color: Colors.red, width: 1.0),
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
                                                  disableLengthCheck: true,
                                                  onChanged: (PhoneNumber phone) {
                                                    completePhoneNumber = phone.completeNumber;
                                                    state.didChange(phone.completeNumber);
                                                  },
                                                  onCountryChanged: (country) {
                                                    countryCode = '+${country.dialCode}';
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  InputField(
                                    controller: _emailController,
                                    hintText: "example@gmail.com",
                                    label: "Email *",
                                    isRequired: true,
                                    errorText: registerController.emailError.value.isEmpty ? null : registerController.emailError.value,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "This field is required";
                                      }
                                      return null;
                                    },
                                  ),
                                  InputField(
                                    controller: _passwordController,
                                    hintText: "******",
                                    label: "Password *",
                                    password: true,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "This field is required";
                                      }
                                      if (value.length < 6) {
                                        return "Password must be at least 6 characters";
                                      }
                                      return null;
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: CustomButton(
                                      callBackFunction: _register,
                                      label: "Create Account",
                                      backgroundColor: kBlue,
                                      isLoading: registerController.isLoading.value,
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
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (registerController.isLoading.value)
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

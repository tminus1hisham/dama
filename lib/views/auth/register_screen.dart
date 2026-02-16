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
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final RegisterController registerController = Get.put(RegisterController());

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

    registerController.firstName.value = _firstNameController.text;
    registerController.middleName.value = _middleNameController.text;
    registerController.lastName.value = _lastNameController.text;
    registerController.email.value = _emailController.text;
    registerController.password.value = _passwordController.text;
    registerController.phone.value = normalizePhoneNumber(
      _phoneNumberController.text,
    );
    registerController.fcmToken.value = fcmToken;
    print("FCM Token: $fcmToken");
    print("Calling register controller");
    registerController.register(context);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;
                    return SizedBox(
                      width: width > 600 ? 500 : width * 1,
                      child: Form(
                        key: _registerKey,
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
                                InputField(
                                  controller: _firstNameController,
                                  hintText: "John",
                                  label: "First Name *",
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "This field is required";
                                    }
                                    return null;
                                  },
                                ),
                                InputField(
                                  controller: _middleNameController,
                                  hintText: "Doe",
                                  label: "Middle Name",
                                  isRequired: false,
                                ),
                                InputField(
                                  controller: _lastNameController,
                                  hintText: "Smith",
                                  label: "Last Name *",
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "This field is required";
                                    }
                                    return null;
                                  },
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: DropdownButton<String>(
                                              value: '+254',
                                              items: [
                                                DropdownMenuItem(
                                                  value: '+254',
                                                  child: Text('+254'),
                                                ),
                                              ],
                                              onChanged: null,
                                              underline: SizedBox(),
                                              style: TextStyle(
                                                color: isDarkMode ? kWhite : kBlack,
                                              ),
                                              dropdownColor: isDarkMode ? kDarkThemeBg : kWhite,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _phoneNumberController,
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return "This field is required";
                                                }
                                                return null;
                                              },
                                              keyboardType: TextInputType.phone,
                                              style: TextStyle(
                                                color: isDarkMode ? kWhite : kBlack,
                                              ),
                                              cursorColor: isDarkMode ? kWhite : kBlue,
                                              decoration: InputDecoration(
                                                hintText: "7*******",
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                InputField(
                                  controller: _emailController,
                                  hintText: "example@gmail.com",
                                  label: "Email *",
                                  isRequired: true,
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
                          ],
                        ),
                      ),
                    );
                  },
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

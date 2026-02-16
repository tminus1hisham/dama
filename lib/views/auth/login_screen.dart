import 'package:dama/controller/auth_controller.dart';
import 'package:dama/controller/linkedin_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/buttons/custom_icon_button.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _auth = LocalAuthentication();
  final _storage = FlutterSecureStorage();
  String isEmailSaved = '';

  Future<bool> fetchEmail() async {
    String? email = await _storage.read(key: 'email');
    setState(() {
      isEmailSaved = email ?? '';
    });
    return email != null && email.isNotEmpty;
  }

  bool isAvailable = false;

  void checkBiometrics() async {
    bool canCheck = await _auth.canCheckBiometrics;
    bool isSupported = await _auth.isDeviceSupported();
    List<BiometricType> availableBiometrics =
        await _auth.getAvailableBiometrics();

    setState(() {
      isAvailable = canCheck && isSupported && availableBiometrics.isNotEmpty;
    });
  }

  String fcmToken = '';

  void _fetchFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        setState(() {
          fcmToken = token;
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    checkBiometrics();
    _fetchFcmToken();
    fetchEmail();
  }

  final AuthController authController = Get.put(AuthController());

  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();

  void _login() {
    if (!_loginKey.currentState!.validate()) {
      return;
    }

    authController.email.value = _emailController.text;
    authController.password.value = _passwordController.text;
    authController.fcmToken.value = fcmToken;
    authController.login(context);
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                              key: _loginKey,
                              child: Column(
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
                                      "Sign In",
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
                                    controller: _emailController,
                                    hintText: "example@gmail.com",
                                    label: "Email *",
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "This field is required";
                                      }
                                      return null;
                                    },
                                  ),
                                  Obx(
                                    () =>
                                        authController
                                                .emailError
                                                .value
                                                .isNotEmpty
                                            ? Padding(
                                              padding: EdgeInsets.only(
                                                left: 10,
                                                right: 10,
                                                bottom: 10,
                                              ),
                                              child: Text(
                                                authController.emailError.value,
                                                style: TextStyle(
                                                  color: kRed,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                            : SizedBox.shrink(),
                                  ),
                                  InputField(
                                    controller: _passwordController,
                                    hintText: "******",
                                    label: "Password *",
                                    password: true,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "This field is required";
                                      }
                                      return null;
                                    },
                                  ),
                                  Obx(
                                    () =>
                                        authController
                                                .passwordError
                                                .value
                                                .isNotEmpty
                                            ? Padding(
                                              padding: EdgeInsets.only(
                                                left: 10,
                                                right: 10,
                                                bottom: 10,
                                              ),
                                              child: Text(
                                                authController
                                                    .passwordError
                                                    .value,
                                                style: TextStyle(
                                                  color: kRed,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                            : SizedBox.shrink(),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: CustomButton(
                                      callBackFunction: _login,
                                      label: "Login",
                                      backgroundColor: kBlue,
                                    ),
                                  ),
                                  // LinkedIn Button
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: CustomIconButton(
                                      icon: FontAwesomeIcons.linkedin,
                                      callBackFunction: () async {
                                        // Use LinkedInController for consistent deep link handling
                                        final linkedInController =
                                            Get.find<LinkedInController>();
                                        await linkedInController
                                            .loginWithLinkedIn(context);
                                      },
                                      label: "Sign In with LinkedIn",
                                    ),
                                  ),
                                  if (isAvailable && isEmailSaved.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: CustomIconButton(
                                        icon: FontAwesomeIcons.fingerprint,
                                        callBackFunction: () {
                                          authController.loginWithBiometrics(
                                            context,
                                          );
                                        },
                                        label: "Sign In with TouchID",
                                      ),
                                    ),
                                  SizedBox(height: screenHeight * 0.02),
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
                                            text: 'Register',
                                            style: TextStyle(
                                              color: kBlue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes.register,
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Forgot password? ",
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontSize: kNormalTextSize,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Forgot Password',
                                            style: TextStyle(
                                              color: kBlue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Get.offAllNamed(
                                                      AppRoutes
                                                          .requestChangePassword,
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
            if (authController.isLoading.value)
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

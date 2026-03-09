import 'package:dama/controller/reset_password_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/theme_aware_logo.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final ResetPasswordController _resetPasswordController = Get.put(
    ResetPasswordController(),
  );

  final GlobalKey<FormState> _resetPasswordKey = GlobalKey<FormState>();

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    String? fetchedUserId = await StorageService.getData('userId');
    setState(() {
      userId = fetchedUserId;
    });
  }

  void _resetPassword() async {
    if (!_resetPasswordKey.currentState!.validate()) {
      return;
    }

    _resetPasswordController.newPassword.value = _passwordController.text;
    _resetPasswordController.userId.value = userId!;
    _resetPasswordController.otp.value = _otpController.text;

    _resetPasswordController.resetPassword(context);
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
                        key: _resetPasswordKey,
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
                                    "Reset Password",
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: kBigTextSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    "Please enter the OTP sent to your registered phone number",
                                    style: TextStyle(
                                      fontSize: kTitleTextSize,
                                      color: isDarkMode ? kWhite : kBlack,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),

                                InputField(
                                  controller: _otpController,
                                  hintText: "123456",
                                  label: "OTP *",
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
                                  hintText: "*******",
                                  label: "New Password *",
                                  password: true,
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
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: CustomButton(
                                    callBackFunction: _resetPassword,
                                    label: "Change Password",
                                    backgroundColor: kBlue,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_resetPasswordController.isLoading.value)
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

import 'package:dama/controller/change_password_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _changePasswordKey = GlobalKey<FormState>();

  final ChangePasswordController _changePasswordController = Get.put(
    ChangePasswordController(),
  );

  String firstName = '';
  String imageUrl = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');

    setState(() {
      imageUrl = url;
      firstName = fetchedFirstName;
      memberId = fetchedMemberId;
      lastName = fetchedLastName;
      title = fetchedTitle;
      bio = fetchedBio ?? '';
    });
  }

  Future<void> _changePassword() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_changePasswordKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Your password does not match",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return;
    }

    _changePasswordController.newPassword.value = _newPasswordController.text;
    _changePasswordController.oldPassword.value =
        _currentPasswordController.text;

    _changePasswordController.changePassword();
  }

  Future<void> _fetchData() async {
    try {
      String? fetchedFirstName = await StorageService.getData('firstName');

      setState(() {
        firstName = fetchedFirstName!;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile data')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Obx(
      () => Scaffold(
        backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  TopNavigationbar(title: "Change Password"),
                  Container(color: isDarkMode ? kBlack : kBGColor, height: 5),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1500),
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kIsWeb)
                              ProfileCard(
                                isDarkMode: isDarkMode,
                                imageUrl: imageUrl,
                                firstName: firstName,
                                lastName: lastName,
                                title: title,
                                bio: bio,
                              ),
                            if (kIsWeb) SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 30,
                                ),
                                color: isDarkMode ? kBlack : kWhite,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double width = constraints.maxWidth;
                                    return SizedBox(
                                      width: width > 1000 ? 800 : width * 1,
                                      child: Container(
                                        child: SingleChildScrollView(
                                          child: Form(
                                            key: _changePasswordKey,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFFcee0f3),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          30,
                                                        ),
                                                    child: Image(
                                                      image: AssetImage(
                                                        'images/Vector.png',
                                                      ),
                                                      height: 60,
                                                      width: 120,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.02,
                                                ),
                                                Center(
                                                  child: Text(
                                                    "Hey, $firstName",
                                                    style: TextStyle(
                                                      color:
                                                          isDarkMode
                                                              ? kWhite
                                                              : kBlack,
                                                      fontSize: kBigTextSize,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Center(
                                                  child: Text(
                                                    "Fill in the details below",
                                                    style: TextStyle(
                                                      fontSize: kNormalTextSize,
                                                      color: kGrey,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.02,
                                                ),
                                                InputField(
                                                  controller:
                                                      _currentPasswordController,
                                                  hintText: "******",
                                                  label: "Old Password *",
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
                                                InputField(
                                                  controller:
                                                      _newPasswordController,
                                                  hintText: "******",
                                                  label: "New Password *",
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
                                                InputField(
                                                  controller:
                                                      _confirmPasswordController,
                                                  hintText: "******",
                                                  label:
                                                      "Confirm New Password *",
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
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: kSidePadding,
                                                    vertical: 10,
                                                  ),
                                                  child: CustomButton(
                                                    callBackFunction:
                                                        _changePassword,
                                                    label: "Save",
                                                    backgroundColor: kBlue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_changePasswordController.isLoading.value)
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

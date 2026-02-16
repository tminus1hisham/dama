import 'package:dama/controller/update_user_profile_controller.dart';
import 'package:dama/routes/routes.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String? image = await StorageService.getData("userImageUrl");
    String? fName = await StorageService.getData("firstName");
    String? mName = await StorageService.getData("middleName");
    String? lName = await StorageService.getData("lastName");
    String? nationality = await StorageService.getData("selectedNationality");
    String? county = await StorageService.getData("selectedCounty");
    String? phone = await StorageService.getData("phoneNumber");

    setState(() {
      userImageUrl = image ?? '';
      firstName = fName ?? '';
      middleName = mName ?? '';
      lastName = lName ?? '';
      selectedNationality = nationality ?? '';
      selectedCounty = county ?? '';
      phoneNumber = phone ?? '';
    });
  }

  final GlobalKey<FormState> _professionalKey = GlobalKey<FormState>();

  final UpdateUserProfileController updateUserProfileController = Get.put(
    UpdateUserProfileController(),
  );

  void _submitDetails() async {
    if (!_professionalKey.currentState!.validate()) {
      return;
    }

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

    updateUserProfileController.updateUser();
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
                            'Step 2 of 2',
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
                              Navigator.pushNamed(context, AppRoutes.login);
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

import 'dart:io';

import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/inputs/custom_dropdown.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../services/local_storage_service.dart';
import '../utils/theme_provider.dart';

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  String? imageUrl;
  String? selectedNationality;
  String? selectedCounty;

  final List<String> nationality = ["Please select", "Kenyan", "Ugandan"];
  final List<String> county = ["Please select", "Nairobi", "Mombasa"];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final phoneNumber = StorageService.getData('phoneNumber');

  void _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await StorageService.storeData({
      'userImageUrl': imageUrl,
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'selectedNationality': selectedNationality,
      'selectedCounty': selectedCounty,
      'phoneNumber': phoneNumber,
    });

    Navigator.pushNamed(context, AppRoutes.professional_details);
  }

  final Utils utils = Utils();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
      });

      File image = File(result.files.single.path!);
      String? uploadedUrl = await utils.uploadPicture(image);

      if (uploadedUrl != null) {
        setState(() {
          imageUrl = uploadedUrl;
        });
      }

      setState(() {
        _isUploading = false;
      });
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: kSidePadding,
                      vertical: 5,
                    ),
                    child: Text(
                      'Step 1 of 2',
                      style: TextStyle(color: isDarkMode ? kWhite : kBlue, fontSize: kNormalTextSize),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: kSidePadding, bottom: 10),
                    child: Text(
                      "Fill in your personal details",
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
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: kSidePadding,
                      vertical: 10,
                    ),
                    child: Text(
                      "Profile Picture",
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: kNormalTextSize,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: kLightGrey,
                            backgroundImage:
                                imageUrl != null && imageUrl!.isNotEmpty
                                    ? NetworkImage(imageUrl!)
                                    : null,
                            child:
                                imageUrl == null
                                    ? Icon(Icons.person, size: 50, color: kGrey)
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: kBlue,
                                child: Icon(
                                  FontAwesomeIcons.pen,
                                  size: 15,
                                  color: kWhite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
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
                    label: "Middle Name *",
                  ),
                  InputField(
                    controller: _lastNameController,
                    hintText: "Doe",
                    label: "Last Name *",
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "This field is required";
                      }
                      return null;
                    },
                  ),
                  CustomDropdown(
                    label: "Nationality",
                    value: selectedNationality,
                    items: nationality,
                    isRequired: true,
                    onChanged:
                        (value) => setState(() => selectedNationality = value),
                  ),
                  CustomDropdown(
                    label: "County",
                    value: selectedCounty,
                    items: county,
                    isRequired: true,
                    onChanged:
                        (value) => setState(() => selectedCounty = value),
                  ),
                  Padding(
                    padding: EdgeInsets.all(kSidePadding),
                    child: CustomButton(
                      callBackFunction: () {
                        _saveData();
                      },
                      label: "Continue",
                      backgroundColor: kBlue,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:dama/controller/register_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/buttons/custom_button.dart';

import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
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
  Country? selectedCountry;
  Country? selectedPhoneCountry;

  // Nationality dropdown removed - no longer required

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLinkedInUser = false;
  String? _authType;

  final RegisterController _registerController = Get.find<RegisterController>();

  @override
  void initState() {
    super.initState();
    // Set default country to Kenya first
    _setDefaultCountry();
    // Check if user logged in with LinkedIn and load data accordingly
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    // Check if user logged in with LinkedIn
    await _checkLinkedInUser();
    // Pre-populate with registration data or LinkedIn data
    _loadRegistrationData();
  }

  Future<void> _checkLinkedInUser() async {
    // Check for authType in user data first, fallback to login_method
    _authType = await StorageService.getData('authType');
    if (_authType == null || _authType!.isEmpty) {
      // Fallback to login_method for backward compatibility
      final loginMethod = await StorageService.getData('login_method');
      if (loginMethod == 'linkedin') {
        _authType = 'linkedin';
      }
    }
    setState(() {
      _isLinkedInUser = _authType == 'linkedin';
    });
  }

  void _setDefaultCountry() {
    // Find Kenya in the country list
    final countries = CountryService().getAll();
    final kenya = countries.firstWhere(
      (country) => country.countryCode == 'KE',
      orElse: () => countries.first,
    );
    // Don't use setState here since this is called in initState
    selectedCountry = kenya;
    selectedPhoneCountry = kenya;
    print('[PersonalDetails] Default country set to: ${kenya.name}');
  }

  void _loadRegistrationData() async {
    // First try to load from registration controller
    if (_registerController.firstName.value.isNotEmpty) {
      _firstNameController.text = _registerController.firstName.value;
    }
    if (_registerController.lastName.value.isNotEmpty) {
      _lastNameController.text = _registerController.lastName.value;
    }

    // For LinkedIn users, load data from storage
    if (_isLinkedInUser) {
      await _loadLinkedInData();
    }
  }

  Future<void> _loadLinkedInData() async {
    // Load LinkedIn profile data from storage
    final storedFirstName = await StorageService.getData('firstName');
    final storedLastName = await StorageService.getData('lastName');
    final storedMiddleName = await StorageService.getData('middleName');
    final storedProfilePicture = await StorageService.getData(
      'profile_picture',
    );
    final storedPhoneNumber = await StorageService.getData('phone_number');

    setState(() {
      if (storedFirstName != null && storedFirstName.isNotEmpty) {
        _firstNameController.text = storedFirstName;
      }
      if (storedLastName != null && storedLastName.isNotEmpty) {
        _lastNameController.text = storedLastName;
      }
      if (storedMiddleName != null && storedMiddleName.isNotEmpty) {
        _middleNameController.text = storedMiddleName;
      }
      if (storedProfilePicture != null && storedProfilePicture.isNotEmpty) {
        imageUrl = storedProfilePicture;
      }
      if (storedPhoneNumber != null && storedPhoneNumber.isNotEmpty) {
        _phoneNumberController.text = storedPhoneNumber;
      }
    });
  }

  void _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('=== PERSONAL DETAILS - SAVING DATA ===');
    print('Is LinkedIn User: $_isLinkedInUser');
    print('Selected Country: ${selectedCountry?.name}');

    // Build phone number with country code if provided
    String? fullPhoneNumber;
    if (_phoneNumberController.text.isNotEmpty &&
        selectedPhoneCountry != null) {
      fullPhoneNumber =
          '+${selectedPhoneCountry!.phoneCode}${_phoneNumberController.text}';
    }
    print('Phone Number: $fullPhoneNumber');

    // Get email for LinkedIn users from storage
    String? email;
    if (_isLinkedInUser) {
      email = await StorageService.getData('email');
      print('LinkedIn Email from storage: $email');
    }

    Map<String, dynamic> dataToSave = {
      'userImageUrl': imageUrl,
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'selectedCountry': selectedCountry?.name,
      'selectedNationality':
          selectedCountry?.name, // Also save as nationality for compatibility
      'phoneNumber': fullPhoneNumber,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
      if (_isLinkedInUser && email != null) 'email': email,
    };

    print('Data to save: $dataToSave');

    await StorageService.storeData(dataToSave);

    // Verify data was stored
    final verifyNationality = await StorageService.getData(
      'selectedNationality',
    );
    print('[Verify] selectedNationality from storage: $verifyNationality');

    print('Personal Details saved successfully');
    print('=====================================');

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
                      'Step 1 of 3',
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlue,
                        fontSize: kNormalTextSize,
                      ),
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
                      style: TextStyle(
                        fontSize: kNormalTextSize,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
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
                          ProfileAvatar(
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
                  // Nationality dropdown removed
                  // Show phone number with country code and password only for LinkedIn users
                  if (_isLinkedInUser) ...[
                    _buildPhoneNumberWithCountryCode(context, isDarkMode),
                    InputField(
                      controller: _passwordController,
                      hintText: "Enter password",
                      label: "Password *",
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Password is required";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                  ],
                  _buildCountryPicker(context, isDarkMode),
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

  Widget _buildCountryPicker(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kSidePadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Country *",
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontWeight: FontWeight.bold,
              fontSize: kNormalTextSize,
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                searchAutofocus: true,
                showSearch: true,
                countryListTheme: CountryListThemeData(
                  backgroundColor: isDarkMode ? kDarkCard : kWhite,
                  textStyle: TextStyle(color: isDarkMode ? kWhite : kBlack),
                  searchTextStyle: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                  inputDecoration: InputDecoration(
                    hintText: 'Search country',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: kBlue),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? kDarkBG : Colors.grey[50],
                  ),
                ),
                onSelect: (Country country) {
                  print('[PersonalDetails] Country selected: ${country.name}');
                  setState(() {
                    selectedCountry = country;
                  });
                },
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? kDarkBG : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  if (selectedCountry != null)
                    Text(
                      selectedCountry!.flagEmoji,
                      style: TextStyle(fontSize: 20),
                    ),
                  if (selectedCountry != null) SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedCountry?.name ?? "Select a country",
                      style: TextStyle(
                        color:
                            selectedCountry != null
                                ? (isDarkMode ? kWhite : kBlack)
                                : (isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                        fontSize: kNormalTextSize,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberWithCountryCode(
    BuildContext context,
    bool isDarkMode,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kSidePadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Phone Number *",
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontWeight: FontWeight.bold,
              fontSize: kNormalTextSize,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    searchAutofocus: true,
                    showSearch: true,
                    countryListTheme: CountryListThemeData(
                      backgroundColor: isDarkMode ? kDarkCard : kWhite,
                      textStyle: TextStyle(color: isDarkMode ? kWhite : kBlack),
                      searchTextStyle: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                      inputDecoration: InputDecoration(
                        hintText: 'Search country',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: kBlue),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? kDarkBG : Colors.grey[50],
                      ),
                    ),
                    onSelect: (Country country) {
                      setState(() {
                        selectedPhoneCountry = country;
                      });
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? kDarkBG : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedPhoneCountry != null) ...[
                        Text(
                          selectedPhoneCountry!.flagEmoji,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '+${selectedPhoneCountry!.phoneCode}',
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontSize: kNormalTextSize,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '+254',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontSize: kNormalTextSize,
                          ),
                        ),
                      ],
                      Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InputField(
                  controller: _phoneNumberController,
                  hintText: "7*******",
                  label: "",
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Phone number is required";
                    }
                    // Remove any non-digit characters for validation
                    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length != 9) {
                      return "Phone number must be exactly 9 digits";
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
                      return "Phone number must contain only digits";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

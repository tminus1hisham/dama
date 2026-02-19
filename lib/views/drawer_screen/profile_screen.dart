import 'dart:io';

import 'package:dama/controller/request_delete_account.dart';
import 'package:dama/controller/role_request_controller.dart';
import 'package:dama/controller/update_user_profile_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/dict_dropdown.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? imageUrl;
  String? firstName;
  String? lastName;
  String? profilePicture;
  String? title;
  String? company;
  String? bio;
  String? email;
  String? phoneNumber;
  String? memberId;
  bool hasMembership = false;
  String? membershipExp;
  String? membershipId;

  bool _isUploading = false;
  bool _isUpdating = false;

  final Utils _utils = Utils();

  final UpdateUserProfileController updateUserProfileController = Get.put(
    UpdateUserProfileController(),
  );

  final RequestDeleteAccountController requestDeleteAccountController = Get.put(
    RequestDeleteAccountController(),
  );

  final RoleRequestController roleRequestController = Get.put(
    RoleRequestController(),
  );

  final Map<String, String> roleOptions = {
    "Please select": "",
    "News Editor": "news_editor",
    "Blogger": "blogger",
  };

  String? selectedRole;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final Utils utils = Utils();

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    loadAppVersion();
    _fetchData().then((_) {
      _firstNameController.text = firstName ?? '';
      _lastNameController.text = lastName ?? '';
      _titleController.text = title ?? '';
      _bioController.text = bio ?? '';
      _emailController.text = email ?? '';
      _phoneController.text = phoneNumber ?? '';
    });
  }

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  void loadAppVersion() async {
    String version = await getAppVersion();
    setState(() {
      _appVersion = version;
    });
  }

  Future<void> _fetchData() async {
    try {
      String? fetchedProfilePicture = await StorageService.getData(
        'profile_picture',
      );
      String? fetchedLastName = await StorageService.getData('lastName');
      String? fetchedFirstName = await StorageService.getData('firstName');
      String? fetchedTitle = await StorageService.getData('title');
      String? fetchedCompany = await StorageService.getData('company');
      String? fetchedBio = await StorageService.getData('brief');
      String? fetchedEmail = await StorageService.getData('email');
      String? fetchedPhoneNumber = await StorageService.getData('phoneNumber');
      String? fetchedMemberId = await StorageService.getData('memberId');
      dynamic fetchedHasMembership = await StorageService.getData(
        'hasMembership',
      );
      String? fetchedMembershipExp = await StorageService.getData(
        'membershipExp',
      );
      String? fetchedMembershipId = await StorageService.getData(
        'membershipId',
      );

      // Parse hasMembership safely
      bool parsedHasMembership = false;
      if (fetchedHasMembership is bool) {
        parsedHasMembership = fetchedHasMembership;
      } else if (fetchedHasMembership is String) {
        parsedHasMembership = fetchedHasMembership == 'true';
      } else {
        parsedHasMembership = false;
      }

      setState(() {
        profilePicture = fetchedProfilePicture;
        lastName = fetchedLastName;
        firstName = fetchedFirstName;
        title = fetchedTitle;
        company = fetchedCompany;
        bio = fetchedBio;
        email = fetchedEmail;
        phoneNumber = fetchedPhoneNumber;
        memberId = fetchedMemberId;
        hasMembership = parsedHasMembership;
        membershipExp = fetchedMembershipExp;
        membershipId = fetchedMembershipId;
      });

      // Check if membership has expired
      if (hasMembership && membershipExp != null && membershipExp!.isNotEmpty) {
        try {
          DateTime expiryDate = DateTime.parse(membershipExp!);
          DateTime now = DateTime.now();
          if (now.isAfter(expiryDate)) {
            // Membership has expired
            setState(() {
              hasMembership = false;
            });
            // Update storage to reflect expired status
            await StorageService.storeData({'hasMembership': false});
            print(
              '[ProfileScreen] Membership expired on $membershipExp, updated hasMembership to false',
            );
          }
        } catch (e) {
          print('[ProfileScreen] Error parsing membership expiry date: $e');
        }
      }

      // Update the controller with the fetched data
      if (fetchedProfilePicture != null) {
        updateUserProfileController.profilePicture.value =
            fetchedProfilePicture;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile data')));
    }
  }

  Future<void> _pickImage() async {
    // Request storage permission
    var status = await Permission.photos.request();
    if (!status.isGranted) {
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);

        File image = File(result.files.single.path!);
        String? uploadedUrl = await utils.uploadPicture(image);

        if (uploadedUrl != null) {
          await StorageService.storeData({'profile_picture': uploadedUrl});
          updateUserProfileController.profilePicture.value = uploadedUrl;

          setState(() {
            profilePicture = uploadedUrl;
            _isUploading = false;
          });

          updateUserProfileController.firstName.value =
              _firstNameController.text;
          updateUserProfileController.lastName.value = _lastNameController.text;
          updateUserProfileController.title.value = _titleController.text;

          if (bio != null) {
            updateUserProfileController.brief.value = bio!;
          }

          if (phoneNumber != null) {
            updateUserProfileController.phoneNumber.value = phoneNumber!;
          }

          if (phoneNumber != null) {
            updateUserProfileController.phoneNumber.value = phoneNumber!;
          }

          updateUserProfileController.updateUser();
        } else {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image')));
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _updateNameAndTitle() async {
    setState(() => _isUpdating = true);

    updateUserProfileController.firstName.value = _firstNameController.text;
    updateUserProfileController.lastName.value = _lastNameController.text;
    updateUserProfileController.title.value = _titleController.text;

    if (bio != null) {
      updateUserProfileController.brief.value = bio!;
    }

    if (profilePicture != null) {
      updateUserProfileController.profilePicture.value = profilePicture!;
    }

    if (phoneNumber != null) {
      updateUserProfileController.phoneNumber.value = phoneNumber!;
    }

    updateUserProfileController.updateUser();

    await StorageService.storeData({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'title': _titleController.text,
    });

    setState(() {
      firstName = _firstNameController.text;
      lastName = _lastNameController.text;
      title = _titleController.text;
      _isUpdating = false;
    });
  }

  Future<void> _submitBioDetails() async {
    setState(() => _isUpdating = true);

    updateUserProfileController.brief.value = _bioController.text;

    if (firstName != null && lastName != null) {
      updateUserProfileController.firstName.value = firstName!;
      updateUserProfileController.lastName.value = lastName!;
    }

    if (title != null) {
      updateUserProfileController.title.value = title!;
    }

    if (profilePicture != null) {
      updateUserProfileController.profilePicture.value = profilePicture!;
    }

    if (phoneNumber != null) {
      updateUserProfileController.phoneNumber.value = phoneNumber!;
    }

    updateUserProfileController.updateUser();

    await StorageService.storeData({'brief': _bioController.text});
    setState(() {
      bio = _bioController.text;
      _isUpdating = false;
    });
  }

  Future<void> _submitContactDetails() async {
    setState(() => _isUpdating = true);

    if (_phoneController.text.isNotEmpty) {
      updateUserProfileController.phoneNumber.value = _phoneController.text;
    }

    if (firstName != null && lastName != null) {
      updateUserProfileController.firstName.value = firstName!;
      updateUserProfileController.lastName.value = lastName!;
    }

    if (title != null) {
      updateUserProfileController.title.value = title!;
    }

    if (profilePicture != null) {
      updateUserProfileController.profilePicture.value = profilePicture!;
    }

    if (bio != null) {
      updateUserProfileController.brief.value = bio!;
    }

    updateUserProfileController.updateUser();

    await StorageService.storeData({
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
    });
    setState(() {
      email = _emailController.text;
      phoneNumber = _phoneController.text;
      _isUpdating = false;
    });
  }

  void _showEditNameAndTitleDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDark;

    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: AlertDialog(
                backgroundColor: isDarkMode ? kBlack : kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_rounded, color: kBlue, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _firstNameController,
                        style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                        decoration: InputDecoration(
                          labelText: "First Name",
                          labelStyle: TextStyle(
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          labelStyle: TextStyle(
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                        decoration: InputDecoration(
                          labelText: "Professional Title",
                          labelStyle: TextStyle(
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              _updateNameAndTitle();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: AlertDialog(
                backgroundColor: isDarkMode ? kBlack : kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warning_rounded, color: kRed, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Are you sure you want to request account deletion? This action cannot be undone and all your data will be permanently removed.',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? kWhite.withOpacity(0.8)
                              : kBlack.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
                actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              requestDeleteAccountController
                                  .requestDeleteAccount(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRed,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Delete Account',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEditBioDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDark;

    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: AlertDialog(
                backgroundColor: isDarkMode ? kBlack : kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, color: kBlue, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Edit Bio',
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8),
                      TextField(
                        controller: _bioController,
                        maxLines: 5,
                        maxLength: 500,
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: "Tell us about yourself",
                          labelStyle: TextStyle(
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                          hintText:
                              "Share your professional background, interests, or goals...",
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? kWhite.withOpacity(0.5)
                                    : kGrey.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              _submitBioDetails();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEditContactDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDark;

    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 800,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: AlertDialog(
                backgroundColor: isDarkMode ? kBlack : kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.contact_phone_rounded,
                        color: kBlue,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Edit Contact Information',
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            labelStyle: TextStyle(
                              color: isDarkMode ? kWhite : kGrey,
                            ),
                            hintText: "Enter your email address",
                            hintStyle: TextStyle(
                              color:
                                  isDarkMode
                                      ? kWhite.withOpacity(0.5)
                                      : kGrey.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: kBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            labelStyle: TextStyle(
                              color: isDarkMode ? kWhite : kGrey,
                            ),
                            hintText: "Enter your phone number",
                            hintStyle: TextStyle(
                              color:
                                  isDarkMode
                                      ? kWhite.withOpacity(0.5)
                                      : kGrey.withOpacity(0.7),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: kBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    isDarkMode ? kGrey : kGrey.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              _submitContactDetails();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _requestRole() async {
    if (selectedRole == null || selectedRole == "Please select") {
      Get.snackbar("Error", "Please select a valid role");
      return;
    }

    await roleRequestController.requestRole(selectedRole!);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    return SafeArea(
      bottom: true,
      child: Scaffold(
        backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TopNavigationbar(title: "Profile"),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Image.asset(
                                      "images/profile_bg.png",
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -40,
                                    left: 20,
                                    child: Stack(
                                      children: [
                                        ProfileAvatar(
                                          radius: 40,
                                          backgroundColor: kLightGrey,
                                          backgroundImage:
                                              profilePicture != null
                                                  ? NetworkImage(
                                                    profilePicture!,
                                                  )
                                                  : null,
                                          borderColor: kBlue,
                                          borderWidth: 1.0,
                                          child:
                                              profilePicture == null
                                                  ? Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: kGrey,
                                                  )
                                                  : null,
                                        ),
                                        // Positioned(
                                        //   bottom: 0,
                                        //   right: 0,
                                        //   child: Container(
                                        //     padding: EdgeInsets.all(5),
                                        //     decoration: BoxDecoration(
                                        //       color: kBlue,
                                        //       shape: BoxShape.circle,
                                        //       border: Border.all(
                                        //         color: kWhite,
                                        //         width: 2,
                                        //       ),
                                        //     ),
                                        //     child: Icon(
                                        //       FontAwesomeIcons.pen,
                                        //       size: 15,
                                        //       color: kWhite,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.all(kSidePadding),
                              child: CustomButton(
                                callBackFunction: _pickImage,
                                label: 'Edit Profile Picture',
                                backgroundColor: kBlue,
                              ),
                            ),
                          ),
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Edit Profile Details row
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Edit Profile Details',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _showEditNameAndTitleDialog,
                                        child: Icon(
                                          FontAwesomeIcons.pen,
                                          size: 16,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // User info
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${firstName ?? ''} ${lastName ?? ''}",
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                          fontWeight: FontWeight.bold,
                                          fontSize: kNormalTextSize,
                                        ),
                                      ),
                                      Text(
                                        title ?? '',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                      Text(
                                        company ?? '',
                                        style: TextStyle(
                                          color: isDarkMode ? kWhite : kGrey,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'My Bio',
                                          style: TextStyle(
                                            fontSize: kNormalTextSize,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? kWhite : kBlack,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          bio ?? '',
                                          style: TextStyle(
                                            color: isDarkMode ? kWhite : kBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _showEditBioDialog,
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: kGrey,
                                      child: Icon(
                                        FontAwesomeIcons.pen,
                                        size: 15,
                                        color: kWhite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          // Contact & Location Section
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Contact & Location',
                                        style: TextStyle(
                                          fontSize: kNormalTextSize,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _showEditContactDialog,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: kGrey,
                                          child: Icon(
                                            FontAwesomeIcons.pen,
                                            size: 15,
                                            color: kWhite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  // Email
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              color: kGrey,
                                              fontSize: kSmallTextSize,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            email ?? 'Not set',
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              fontSize: kNormalTextSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Divider(
                                    color: kGrey.withOpacity(0.2),
                                    height: 1,
                                  ),
                                  SizedBox(height: 15),
                                  // Phone
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Phone',
                                            style: TextStyle(
                                              color: kGrey,
                                              fontSize: kSmallTextSize,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            phoneNumber ?? 'Not set',
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              fontSize: kNormalTextSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dark Mode',
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              fontSize: kNormalTextSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            isDarkMode ? "Light" : "Dark",
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: isDarkMode,
                                        onChanged: (value) {
                                          themeProvider.toggleTheme();
                                        },
                                        activeThumbColor: kBlue,
                                        inactiveThumbColor:
                                            isDarkMode
                                                ? Colors.grey[600]!
                                                : kGrey,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Change Password',
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kBlack,
                                              fontSize: kNormalTextSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Change your password",
                                            style: TextStyle(
                                              color:
                                                  isDarkMode ? kWhite : kGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.changePassword,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.arrow_forward_ios,
                                          color: isDarkMode ? kWhite : kBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: kWhite,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  color: isDarkMode ? kBlack : kWhite,
                                  child: Obx(() {
                                    if (roleRequestController.isLoading.value) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        DictDropdown(
                                          label: "Request For role",
                                          value: selectedRole,
                                          items: roleOptions,
                                          isRequired: true,
                                          onChanged:
                                              (value) => setState(
                                                () => selectedRole = value,
                                              ),
                                        ),
                                        SizedBox(height: 10),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 15.0,
                                          ),
                                          // Adjust padding values as needed
                                          child: CustomButton(
                                            callBackFunction: _requestRole,
                                            label: 'Request',
                                            backgroundColor: kBlue,
                                          ),
                                        ),
                                        SizedBox(height: 30),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            color: isDarkMode ? kBlack : kWhite,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Column(
                                children: [
                                  Text(
                                    "Copyright © ${DateTime.now().year} Dama Kenya",
                                    style: TextStyle(color: kGrey),
                                  ),
                                  Text(
                                    'App Version $_appVersion',
                                    style: TextStyle(color: kGrey),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _showDeleteAccountConfirmation(context);
                                    },
                                    child: Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        color: kRed,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isUploading || _isUpdating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      // Assuming the date is in ISO format or similar
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}

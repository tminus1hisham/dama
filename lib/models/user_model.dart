class UserProfileModel {
  String firstName;
  String middleName;
  String lastName;
  String nationality;
  String county;
  String phoneNumber;
  String profilePicture;
  String title;
  String company;
  String brief;
  String? authType;
  String? password;
  bool? passwordSet;

  UserProfileModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.nationality,
    required this.county,
    required this.phoneNumber,
    required this.profilePicture,
    required this.title,
    required this.company,
    required this.brief,
    this.authType,
    this.password,
    this.passwordSet,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      nationality: json['country'] ?? json['nationality'] ?? '',
      county: json['county'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      brief: json['brief'] ?? '',
      authType: json['authType'],
      password: json['password'],
      passwordSet: json['password_set'],
    );
  }

  factory UserProfileModel.fromLinkedInJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['firstName'] ?? json['given_name'] ?? '',
      middleName: '',
      lastName: json['lastName'] ?? json['family_name'] ?? '',
      nationality: '',
      county: '',
      phoneNumber: json['phoneNumber'] ?? '',
      profilePicture: json['profile_picture'] ?? json['picture'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      brief: json['brief'] ?? '',
      authType: 'linkedin',
      password: json['password'],
      passwordSet: json['password_set'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName.isNotEmpty) data['firstName'] = firstName;
    if (middleName.isNotEmpty) data['middleName'] = middleName;
    if (lastName.isNotEmpty) data['lastName'] = lastName;
    if (nationality.isNotEmpty) data['country'] = nationality;
    if (county.isNotEmpty) data['county'] = county;
    if (phoneNumber.isNotEmpty) data['phone_number'] = phoneNumber;
    if (profilePicture.isNotEmpty) data['profile_picture'] = profilePicture;
    if (title.isNotEmpty) data['title'] = title;
    if (company.isNotEmpty) data['company'] = company;
    if (brief.isNotEmpty) data['brief'] = brief;
    if (authType != null) data['authType'] = authType;
    if (password != null && password!.isNotEmpty) data['password'] = password;
    if (passwordSet != null) data['password_set'] = passwordSet;

    return data;
  }
}

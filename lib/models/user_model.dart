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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      nationality: json['nationality'] ?? '',
      county: json['county'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      brief: json['brief'] ?? '',
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
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName.isNotEmpty) data['firstName'] = firstName;
    if (middleName.isNotEmpty) data['middleName'] = middleName;
    if (lastName.isNotEmpty) data['lastName'] = lastName;
    if (nationality.isNotEmpty) data['nationality'] = nationality;
    if (county.isNotEmpty) data['county'] = county;
    if (phoneNumber.isNotEmpty) data['phone_number'] = phoneNumber;
    if (profilePicture.isNotEmpty) data['profile_picture'] = profilePicture;
    if (title.isNotEmpty) data['title'] = title;
    if (company.isNotEmpty) data['company'] = company;
    if (brief.isNotEmpty) data['brief'] = brief;

    return data;
  }
}

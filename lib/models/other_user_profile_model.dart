class OtherUserDetailsModel {
  final String id;
  final String email;
  final String phoneNumber;
  final bool phoneNumberVerified;
  final String brief;
  final String company;
  final String county;
  final String firstName;
  final String lastName;
  final String middleName;
  final String nationality;
  final String profilePicture;
  final String title;
  final List roles;

  OtherUserDetailsModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.phoneNumberVerified,
    required this.brief,
    required this.company,
    required this.county,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.nationality,
    required this.profilePicture,
    required this.title,
    required this.roles,
  });

  factory OtherUserDetailsModel.fromJson(Map<String, dynamic> json) {
    return OtherUserDetailsModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      phoneNumberVerified: json['phone_number_verified'] ?? false,
      brief: json['brief'] ?? '',
      company: json['company'] ?? '',
      county: json['county'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'] ?? '',
      nationality: json['nationality'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      title: json['title'] ?? '',
      roles: json['roles'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phone_number': phoneNumber,
      'phone_number_verified': phoneNumberVerified,
      'brief': brief,
      'company': company,
      'county': county,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'nationality': nationality,
      'profile_picture': profilePicture,
      'title': title,
      'roles': roles,
    };
  }
}

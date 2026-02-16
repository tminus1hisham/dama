class RegisterModel {
  String firstName;
  String middleName;
  String lastName;
  String email;
  String phone;
  String password;
  String fcmToken;

  RegisterModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.fcmToken,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      fcmToken: json['fcmToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'fcmToken': fcmToken,
    };
  }
}

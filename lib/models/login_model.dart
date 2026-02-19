class LoginModel {
  final String email;
  final String password;
  final String fcmToken;
  final String? authType;

  LoginModel({
    required this.email,
    required this.password,
    required this.fcmToken,
    this.authType,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'fcmToken': fcmToken};
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      email: json['email'],
      password: json['password'],
      fcmToken: json['fcmToken'],
      authType: json['authType'],
    );
  }
}

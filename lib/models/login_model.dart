class LoginModel {
  final String email;
  final String password;
  final String fcmToken;

  LoginModel({
    required this.email,
    required this.password,
    required this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'fcmToken': fcmToken};
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      email: json['email'],
      password: json['password'],
      fcmToken: json['fcmToken'],
    );
  }
}

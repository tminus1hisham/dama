import 'dart:convert';

class SupportModel {
  final String fullName;
  final String email;
  final String message;

  SupportModel({
    required this.fullName,
    required this.email,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'email': email, 'description': message};
  }

  factory SupportModel.fromJson(Map<String, dynamic> json) {
    return SupportModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      message: json['description'] ?? json['message'] ?? '',
    );
  }

  String toRawJson() => json.encode(toJson());

  factory SupportModel.fromRawJson(String str) =>
      SupportModel.fromJson(json.decode(str));
}

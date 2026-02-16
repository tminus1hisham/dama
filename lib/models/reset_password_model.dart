class ResetPasswordModel {
  final String userId;
  final String otp;
  final String newPassword;

  ResetPasswordModel({
    required this.userId,
    required this.otp,
    required this.newPassword,
  });

  factory ResetPasswordModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordModel(
      userId: json['userId'],
      otp: json['otp'],
      newPassword: json['newPassword'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'otp': otp, 'newPassword': newPassword};
  }
}

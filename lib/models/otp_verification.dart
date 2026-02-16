class OtpVerificationModel {
  final String userId;
  final String otp;

  OtpVerificationModel({required this.userId, required this.otp});

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) {
    return OtpVerificationModel(userId: json['userId'], otp: json['otp']);
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'otp': otp};
  }
}

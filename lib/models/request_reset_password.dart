class RequestChangePasswordModel {
  final String phone_number;

  RequestChangePasswordModel({required this.phone_number});

  factory RequestChangePasswordModel.fromJson(Map<String, dynamic> json) {
    return RequestChangePasswordModel(phone_number: json['phone_number']);
  }

  Map<String, dynamic> toJson() {
    return {'phone_number': phone_number};
  }
}

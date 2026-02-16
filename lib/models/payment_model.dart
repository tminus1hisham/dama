class PaymentModel {
  final String objectId;
  final String model;
  final int amountToPay;
  final String phoneNumber;

  PaymentModel({
    required this.objectId,
    required this.model,
    required this.amountToPay,
    required this.phoneNumber,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      objectId: json['object_id'],
      model: json['model'],
      amountToPay: json['amountToPay'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object_id': objectId,
      'model': model,
      'amountToPay': amountToPay,
      'phoneNumber': phoneNumber,
    };
  }
}

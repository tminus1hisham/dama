class VerifyByPhoneModel {
  final String phoneNumber;
  final String eventId;

  VerifyByPhoneModel({required this.phoneNumber, required this.eventId});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'eventId': eventId};
  }

  factory VerifyByPhoneModel.fromJson(Map<String, dynamic> json) {
    return VerifyByPhoneModel(
      phoneNumber: json['phoneNumber'],
      eventId: json['eventId'],
    );
  }
}

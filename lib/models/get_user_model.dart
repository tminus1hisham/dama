class GetUserModel {
  final String id;
  final List<EventQRCode> eventQRCode;

  GetUserModel({
    required this.id,
    required this.eventQRCode,
  });

  factory GetUserModel.fromJson(Map<String, dynamic> json) {
    return GetUserModel(
      id: json['_id'] as String,
      eventQRCode: (json['eventQRCode'] as List<dynamic>?)
          ?.map((e) => EventQRCode.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class EventQRCode {
  final String eventId;
  final String qrCode;

  EventQRCode({
    required this.eventId,
    required this.qrCode,
  });

  factory EventQRCode.fromJson(Map<String, dynamic> json) {
    return EventQRCode(
      eventId: json['eventId']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
    );
  }
}

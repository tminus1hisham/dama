class GetUserModel {
  final String id;
  final List<EventQRCode> eventQRCode;
  final List<String> resources; // Resource IDs the user has purchased

  GetUserModel({
    required this.id,
    required this.eventQRCode,
    required this.resources,
  });

  factory GetUserModel.fromJson(Map<String, dynamic> json) {
    return GetUserModel(
      id: json['_id'] as String,
      eventQRCode:
          (json['eventQRCode'] as List<dynamic>?)
              ?.map((e) => EventQRCode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resources:
          (json['resources'] as List<dynamic>?)
              ?.map(
                (e) =>
                    e is Map<String, dynamic>
                        ? e['_id']?.toString()
                        : e.toString(),
              )
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList() ??
          [],
    );
  }
}

class EventQRCode {
  final String eventId;
  final String qrCode;

  EventQRCode({required this.eventId, required this.qrCode});

  factory EventQRCode.fromJson(Map<String, dynamic> json) {
    return EventQRCode(
      eventId: json['eventId']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
    );
  }
}

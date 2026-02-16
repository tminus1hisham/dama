class VerifyQrCode {
  final String userId;
  final String eventId;
  final String transactionId;
  final int timestamp;

  VerifyQrCode({
    required this.userId,
    required this.eventId,
    required this.transactionId,
    required this.timestamp,
  });

  factory VerifyQrCode.fromJson(Map<String, dynamic> json) {
    return VerifyQrCode(
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      transactionId: json['transactionId'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  // Method to convert an instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'transactionId': transactionId,
      'timestamp': timestamp,
    };
  }
}

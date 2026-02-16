class AttendanceRecord {
  final String sessionId;
  final String userId;
  final String userName;
  final bool present;
  final DateTime? markedAt;
  final String? markedBy; // trainer ID

  AttendanceRecord({
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.present,
    this.markedAt,
    this.markedBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      present: json['present'] ?? false,
      markedAt: json['marked_at'] != null ? DateTime.tryParse(json['marked_at']) : null,
      markedBy: json['marked_by'],
    );
  }
}

class AttendanceResponse {
  final bool success;
  final List<AttendanceRecord> attendance;

  AttendanceResponse({
    required this.success,
    required this.attendance,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] ?? false,
      attendance: (json['attendance'] as List?)
          ?.map((e) => AttendanceRecord.fromJson(e))
          .toList() ?? [],
    );
  }
}
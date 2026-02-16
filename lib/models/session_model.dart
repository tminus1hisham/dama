class TrainingSession {
  final String id;
  final String trainingId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final String? meetingLink;
  final String? meetingPlatform;
  final String? notes;
  final List<SessionResource> resources;
  final List<SessionAttendance> attendance;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingSession({
    required this.id,
    required this.trainingId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.meetingLink,
    this.meetingPlatform,
    this.notes,
    required this.resources,
    required this.attendance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    try {
      final dateStr = json['date'] is String ? json['date'] : '';
      final startTimeStr = json['startTime'] is String ? json['startTime'] : '00:00';
      final endTimeStr = json['endTime'] is String ? json['endTime'] : '00:00';
      final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
      final startTime = _combineDateTime(date, startTimeStr);
      final endTime = _combineDateTime(date, endTimeStr);

      final resourcesJson = json['resources'] as List? ?? [];
      final resources = resourcesJson.map((e) => SessionResource.fromJson(e)).toList();

      final attendanceJson = json['attendance'] as List? ?? [];
      final attendance = attendanceJson.map((e) => SessionAttendance.fromJson(e)).toList();

      return TrainingSession(
        id: json['_id']?.toString() ?? json['sessionNumber']?.toString() ?? '',
        trainingId: '', // Not provided in API, can be set later if needed
        title: json['title'] is String ? json['title'] : '',
        description: json['description'] is String ? json['description'] : '',
        startTime: startTime,
        endTime: endTime,
        status: json['status'] is String ? json['status'] : 'scheduled',
        meetingLink: json['meetingLink'] is String ? json['meetingLink'] : null,
        meetingPlatform: json['meetingPlatform'] is String ? json['meetingPlatform'] : null,
        notes: json['notes'] is String ? json['notes'] : null,
        resources: resources,
        attendance: attendance,
        createdAt: date,
        updatedAt: date,
      );
    } catch (e) {
      // Return a default session if parsing fails
      return TrainingSession(
        id: '',
        trainingId: '',
        title: 'Error parsing session',
        description: 'Failed to parse session data',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        status: 'error',
        meetingLink: null,
        meetingPlatform: null,
        notes: null,
        resources: [],
        attendance: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static DateTime _combineDateTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    return date;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'training_id': trainingId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'meeting_link': meetingLink,
      'meeting_platform': meetingPlatform,
      'notes': notes,
      'resources': resources.map((r) => r.toJson()).toList(),
      'attendance': attendance.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SessionResource {
  final String id;
  final String title;
  final String url;
  final String type;
  final Map<String, dynamic> uploadedBy;
  final DateTime uploadedAt;

  SessionResource({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory SessionResource.fromJson(Map<String, dynamic> json) {
    return SessionResource(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      uploadedBy: json['uploadedBy'] ?? {},
      uploadedAt: DateTime.tryParse(json['uploadedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'url': url,
      'type': type,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class SessionAttendance {
  final String sessionId;
  final String userId;
  final bool present;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int? duration;
  final String? notes;

  SessionAttendance({
    required this.sessionId,
    required this.userId,
    required this.present,
    this.checkInTime,
    this.checkOutTime,
    this.duration,
    this.notes,
  });

  factory SessionAttendance.fromJson(Map<String, dynamic> json) {
    return SessionAttendance(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      present: json['present'] ?? false,
      checkInTime: json['check_in_time'] != null ? DateTime.tryParse(json['check_in_time']) : null,
      checkOutTime: json['check_out_time'] != null ? DateTime.tryParse(json['check_out_time']) : null,
      duration: json['duration'] != null ? json['duration'] as int : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'present': present,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'duration': duration,
      'notes': notes,
    };
  }
}
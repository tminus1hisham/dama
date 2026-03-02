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
  final String? meetingUrl;
  final String? notes;
  final List<SessionResource> resources;
  final List<SessionResource> materials;
  final List<SessionAttendance> attendance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isJoined;
  final String? type;
  final String? duration;
  final String? recordingUrl;

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
    this.meetingUrl,
    this.notes,
    required this.resources,
    this.materials = const [],
    required this.attendance,
    required this.createdAt,
    required this.updatedAt,
    this.isJoined,
    this.type,
    this.duration,
    this.recordingUrl,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    try {
      final dateStr = json['date'] is String ? json['date'] : '';
      final startTimeStr = json['startTime'] is String ? json['startTime'] : '00:00';
      final endTimeStr = json['endTime'] is String ? json['endTime'] : '00:00';

      // Parse full UTC datetime string and convert to local time
      // e.g. "2026-02-22T21:00:00.000Z" → 2026-02-23 00:00:00 in EAT (UTC+3)
      final date = (DateTime.tryParse(dateStr) ?? DateTime.now()).toLocal();

      final startTime = _combineDateTime(date, startTimeStr);
      final endTime = _combineDateTime(date, endTimeStr);

      final resourcesJson = json['resources'] as List? ?? [];
      final resources = resourcesJson.map((e) => SessionResource.fromJson(e as Map<String, dynamic>)).toList();

      final materialsJson = json['materials'] as List? ?? [];
      final materials = materialsJson.map((e) => SessionResource.fromJson(e as Map<String, dynamic>)).toList();

      final attendanceJson = json['attendance'] as List? ?? [];
      final attendance = attendanceJson.map((e) => SessionAttendance.fromJson(e as Map<String, dynamic>)).toList();

      return TrainingSession(
        id: json['_id']?.toString() ?? json['sessionNumber']?.toString() ?? '',
        trainingId: json['trainingId']?.toString() ?? '',
        title: json['title'] is String ? json['title'] : '',
        description: json['description'] is String ? json['description'] : '',
        startTime: startTime,
        endTime: endTime,
        status: json['status'] is String ? json['status'] : 'scheduled',
        meetingLink: json['meetingLink'] is String ? json['meetingLink'] : null,
        meetingPlatform: json['meetingPlatform'] is String ? json['meetingPlatform'] : null,
        meetingUrl: json['meetingUrl'] is String ? json['meetingUrl'] : null,
        notes: json['notes'] is String ? json['notes'] : null,
        resources: resources,
        materials: materials,
        attendance: attendance,
        createdAt: date,
        updatedAt: date,
        isJoined: json['isJoined'] as bool?,
        type: json['type'] as String?,
        duration: json['duration']?.toString(),
        recordingUrl: json['recordingUrl'] is String ? json['recordingUrl'] : null,
      );
    } catch (e) {
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
        meetingUrl: null,
        notes: null,
        resources: [],
        materials: [],
        attendance: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isJoined: null,
        type: null,
        duration: null,
        recordingUrl: null,
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

  TrainingSession copyWith({
    String? id,
    String? trainingId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? meetingLink,
    String? meetingPlatform,
    String? meetingUrl,
    String? notes,
    List<SessionResource>? resources,
    List<SessionResource>? materials,
    List<SessionAttendance>? attendance,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isJoined,
    String? type,
    String? duration,
    String? recordingUrl,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      meetingLink: meetingLink ?? this.meetingLink,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      notes: notes ?? this.notes,
      resources: resources ?? this.resources,
      materials: materials ?? this.materials,
      attendance: attendance ?? this.attendance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isJoined: isJoined ?? this.isJoined,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      recordingUrl: recordingUrl ?? this.recordingUrl,
    );
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
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      uploadedBy: json['uploadedBy'] is Map<String, dynamic> ? json['uploadedBy'] : {},
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
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
      sessionId: json['session_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      present: json['present'] == true,
      checkInTime: json['check_in_time'] != null
          ? DateTime.tryParse(json['check_in_time']?.toString() ?? '')?.toLocal()
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.tryParse(json['check_out_time']?.toString() ?? '')?.toLocal()
          : null,
      duration: json['duration'] is int ? json['duration'] as int : null,
      notes: json['notes']?.toString(),
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

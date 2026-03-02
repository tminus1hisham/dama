import '../models/session_model.dart';

class TrainingResponse {
  final bool success;
  final List<TrainingModel> trainings;

  TrainingResponse({required this.success, required this.trainings});

  factory TrainingResponse.fromJson(Map<String, dynamic> json) {
    return TrainingResponse(
      success: json['success'] ?? false,
      trainings:
          (json['trainings'] as List?)
              ?.map((e) => TrainingModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Trainer {
  final String firstName;
  final String lastName;

  Trainer({required this.firstName, required this.lastName});

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      firstName: json['firstName'] is String ? json['firstName'] : '',
      lastName: json['lastName'] is String ? json['lastName'] : '',
    );
  }
}

class Certificate {
  final bool? issued;
  final String? certificateNumber;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  Certificate({
    this.issued,
    this.certificateNumber,
    this.issuedAt,
    this.expiresAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      issued: json['issued'] as bool?,
      certificateNumber: json['certificateNumber'] as String?,
      issuedAt: json['issuedAt'] != null ? DateTime.tryParse(json['issuedAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
    );
  }
}

class CertificateConfig {
  final bool enabled;
  final String? templateId;
  final List<String>? requirements;

  CertificateConfig({
    this.enabled = false,
    this.templateId,
    this.requirements,
  });

  factory CertificateConfig.fromJson(Map<String, dynamic> json) {
    return CertificateConfig(
      enabled: json['enabled'] as bool? ?? false,
      templateId: json['templateId'] as String?,
      requirements: json['requirements'] != null 
          ? List<String>.from(json['requirements']) 
          : null,
    );
  }
}

class TrainingModel {
  final String id;
  final String title;
  final String description;
  final List<LearningTrack> learningTracks;
  final List<String> targetAudience;
  final List<String> learningOutcomes;
  final List<CourseOutline> courseOutline;
  final List<TrainingSession> sessions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? registrationStatus;
  final int? progress;
  final Trainer? trainer;
  final DateTime? endDate;
  final Map<String, dynamic>? analytics;
  final DateTime? startDate;
  final String? status;
  final Map<String, dynamic>? userData;
  final String? category;
  final Certificate? certificate;
  final CertificateConfig? certificateConfig;

  TrainingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.learningTracks,
    required this.targetAudience,
    required this.learningOutcomes,
    required this.courseOutline,
    required this.sessions,
    required this.createdAt,
    required this.updatedAt,
    this.registrationStatus,
    this.progress,
    this.trainer,
    this.endDate,
    this.analytics,
    this.startDate,
    this.status,
    this.userData,
    this.category,
    this.certificate,
    this.certificateConfig,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['_id'] is String ? json['_id'] : json['id'] is String ? json['id'] : '',
      title: json['title'] is String ? json['title'] : '',
      description: json['description'] is String ? json['description'] : '',
      learningTracks:
          (json['learning_tracks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => LearningTrack.fromJson(e))
              .toList() ??
          [],
      targetAudience: List<String>.from((json['target_audience'] as List?)?.whereType<String>() ?? []),
      learningOutcomes: List<String>.from((json['learning_outcomes'] as List?)?.whereType<String>() ?? []),
      courseOutline:
          (json['course_outline'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CourseOutline.fromJson(e))
              .toList() ??
          [
            CourseOutline(
              id: '1',
              day: 'Day 1',
              time: '9:00 AM - 5:00 PM',
              topic: 'Introduction to the Training',
              description: 'Overview of the training program and objectives.',
            ),
            CourseOutline(
              id: '2',
              day: 'Day 2',
              time: '9:00 AM - 5:00 PM',
              topic: 'Core Concepts',
              description: 'Deep dive into the core concepts of the subject.',
            ),
            CourseOutline(
              id: '3',
              day: 'Day 3',
              time: '9:00 AM - 5:00 PM',
              topic: 'Practical Applications',
              description: 'Hands-on exercises and real-world applications.',
            ),
          ],
      sessions:
          (json['sessions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return TrainingSession.fromJson(e);
                } catch (error) {
                  // Return a default session if parsing fails
                  return TrainingSession(
                    id: e['_id']?.toString() ?? e['sessionNumber']?.toString() ?? '',
                    trainingId: '',
                    title: e['title']?.toString() ?? 'Session',
                    description: e['description']?.toString() ?? '',
                    startTime: DateTime.now(),
                    endTime: DateTime.now(),
                    status: 'scheduled',
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
              })
              .toList() ??
          <TrainingSession>[],
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      registrationStatus: json['registration_status'] is String ? json['registration_status'] : null,
      progress: json['progress'] is int ? json['progress'] : null,
      trainer: json['trainer'] is Map<String, dynamic> 
          ? Trainer.fromJson(json['trainer']) 
          : json['trainer'] is String 
              ? Trainer(firstName: json['trainer'], lastName: '') 
              : null,
      endDate: json['endDate'] != null && json['endDate'] is String ? DateTime.tryParse(json['endDate']) : null,
      analytics: json['analytics'] is Map<String, dynamic> ? json['analytics'] : null,
      startDate: json['startDate'] != null && json['startDate'] is String 
          ? DateTime.tryParse(json['startDate']) 
          : json['date'] != null && json['date'] is String 
              ? DateTime.tryParse(json['date']) 
              : null,
      status: json['status'] is String ? json['status'] : null,
      userData: json['userData'] is Map<String, dynamic> ? json['userData'] : null,
      category: json['category'] is String ? json['category'] : null,
      certificate: json['certificate'] is Map<String, dynamic> ? Certificate.fromJson(json['certificate']) : null,
      certificateConfig: json['certificateConfig'] is Map<String, dynamic> ? CertificateConfig.fromJson(json['certificateConfig']) : null,
    );
  }

  TrainingModel copyWith({
    String? id,
    String? title,
    String? description,
    List<LearningTrack>? learningTracks,
    List<String>? targetAudience,
    List<String>? learningOutcomes,
    List<CourseOutline>? courseOutline,
    List<TrainingSession>? sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? registrationStatus,
    int? progress,
    Trainer? trainer,
    DateTime? endDate,
    Map<String, dynamic>? analytics,
    DateTime? startDate,
    String? status,
    Map<String, dynamic>? userData,
    String? category,
    Certificate? certificate,
    CertificateConfig? certificateConfig,
  }) {
    return TrainingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      learningTracks: learningTracks ?? this.learningTracks,
      targetAudience: targetAudience ?? this.targetAudience,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      courseOutline: courseOutline ?? this.courseOutline,
      sessions: sessions ?? this.sessions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      progress: progress ?? this.progress,
      trainer: trainer ?? this.trainer,
      endDate: endDate ?? this.endDate,
      analytics: analytics ?? this.analytics,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      userData: userData ?? this.userData,
      category: category ?? this.category,
      certificate: certificate ?? this.certificate,
      certificateConfig: certificateConfig ?? this.certificateConfig,
    );
  }
}

class LearningTrack {
  final String id;
  final String type;
  final String schedule;
  final String duration;
  final int price;
  final String currency;
  final String registrationStatus;

  LearningTrack({
    required this.id,
    required this.type,
    required this.schedule,
    required this.duration,
    required this.price,
    required this.currency,
    required this.registrationStatus,
  });

  factory LearningTrack.fromJson(Map<String, dynamic> json) {
    return LearningTrack(
      id: json['_id'] is String ? json['_id'] : '',
      type: json['type'] is String ? json['type'] : '',
      schedule: json['schedule'] is String ? json['schedule'] : '',
      duration: json['duration'] is String ? json['duration'] : '',
      price: json['price'] is int ? json['price'] : 0,
      currency: json['currency'] is String ? json['currency'] : 'KES',
      registrationStatus: json['registration_status'] is String ? json['registration_status'] : '',
    );
  }
}

class CourseOutline {
  final String id;
  final String day;
  final String time;
  final String topic;
  final String description;

  CourseOutline({
    required this.id,
    required this.day,
    required this.time,
    required this.topic,
    required this.description,
  });

  factory CourseOutline.fromJson(Map<String, dynamic> json) {
    return CourseOutline(
      id: json['_id'] is String ? json['_id'] : '',
      day: json['day'] is String ? json['day'] : '',
      time: json['time'] is String ? json['time'] : '',
      topic: json['topic'] is String ? json['topic'] : '',
      description: json['description'] is String ? json['description'] : '',
    );
  }
}

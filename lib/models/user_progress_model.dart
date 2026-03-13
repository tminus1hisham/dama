class UserTrainingProgress {
  final String trainingId;
  final String title;
  final int completedSessions;
  final int totalSessions;
  final double progressPercentage;
  final DateTime? lastAccessed;

  UserTrainingProgress({
    required this.trainingId,
    required this.title,
    required this.completedSessions,
    required this.totalSessions,
    required this.progressPercentage,
    this.lastAccessed,
  });

  factory UserTrainingProgress.fromJson(Map<String, dynamic> json) {
    return UserTrainingProgress(
      trainingId: json['training_id'] ?? '',
      title: json['title'] ?? '',
      completedSessions: json['completed_sessions'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      lastAccessed:
          json['last_accessed'] != null
              ? DateTime.tryParse(json['last_accessed'])
              : null,
    );
  }
}

class UserSessionProgress {
  final String sessionId;
  final String title;
  final bool joined;
  final bool completed;
  final DateTime? joinTime;
  final DateTime? leaveTime;

  UserSessionProgress({
    required this.sessionId,
    required this.title,
    required this.joined,
    required this.completed,
    this.joinTime,
    this.leaveTime,
  });

  factory UserSessionProgress.fromJson(Map<String, dynamic> json) {
    return UserSessionProgress(
      sessionId: json['session_id'] ?? '',
      title: json['title'] ?? '',
      joined: json['joined'] ?? false,
      completed: json['completed'] ?? false,
      joinTime:
          json['join_time'] != null
              ? DateTime.tryParse(json['join_time'])
              : null,
      leaveTime:
          json['leave_time'] != null
              ? DateTime.tryParse(json['leave_time'])
              : null,
    );
  }
}

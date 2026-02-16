import '../models/session_model.dart';

bool isUserJoined(TrainingSession session, String? currentUserId) {
  if (currentUserId == null) return false;
  return session.attendance.any((attendance) => attendance.userId == currentUserId);
}
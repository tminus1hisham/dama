import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';

class SessionsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TrainingSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<TrainingSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSessions(List<TrainingSession> sessions) {
    _sessions = sessions;
    notifyListeners();
  }

  Future<void> loadSessions(String trainingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTrainingSessions(trainingId);
      // API returns {sessions: [...]} directly, not wrapped in success field
      if (response['sessions'] != null) {
        _sessions = List<TrainingSession>.from(
          (response['sessions'] as List).map(
            (x) => TrainingSession.fromJson(x),
          ),
        );
      } else if (response['data'] != null &&
          response['data']['sessions'] != null) {
        // Alternative format: {data: {sessions: [...]}}
        _sessions = List<TrainingSession>.from(
          (response['data']['sessions'] as List).map(
            (x) => TrainingSession.fromJson(x),
          ),
        );
      } else {
        _error = response['message'] ?? 'Failed to load sessions';
      }
    } catch (e) {
      _error = 'Error loading sessions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionsFromCache() async {
    // TODO: Implement cache loading if needed
    // For now, do nothing
  }

  void updateSession(TrainingSession updatedSession) {
    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      notifyListeners();
    }
  }
}

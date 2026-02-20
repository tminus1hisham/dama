import 'package:dama/models/session_model.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/models/user_progress_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:get/get.dart';

class UserProgressController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var todaySessions = <TrainingSession>[].obs;
  var upcomingSessions = <TrainingSession>[].obs;
  var trainingProgress = <UserTrainingProgress>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodaySessions();
  }

  Future<void> fetchTodaySessions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _apiService.getUserTodaySessions();
      todaySessions.assignAll((result['sessions'] as List?)?.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)) ?? []);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUpcomingSessions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _apiService.getUserUpcomingSessions();
      upcomingSessions.assignAll((result['sessions'] as List?)?.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)) ?? []);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTrainingProgress() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Calculate progress based on status fields instead of API endpoint
      final progressList = await _calculateStatusBasedProgress();
      trainingProgress.assignAll(progressList);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserTrainingProgress>> _calculateStatusBasedProgress() async {
    try {
      // Get current user ID
      final currentUserId = await StorageService.getData('userId');

      // Get user's trainings with detailed session information
      final userTrainingsResult = await _apiService.getUserTrainings();
      final trainingsData = userTrainingsResult is List ? userTrainingsResult : userTrainingsResult['trainings'] ?? [];

      List<UserTrainingProgress> progressList = [];

      for (var trainingData in trainingsData) {
        final training = TrainingModel.fromJson(trainingData);

        // Get detailed training data with sessions
        final detailedResult = await _apiService.getUserTrainingDetails(training.id);
        final detailedData = detailedResult['training'] ?? detailedResult['data'] ?? detailedResult;
        final fullTraining = TrainingModel.fromJson(detailedData);

        // Calculate progress based on session statuses
        final sessions = fullTraining.sessions;
        final totalSessions = sessions.length;

        if (totalSessions == 0) {
          progressList.add(UserTrainingProgress(
            trainingId: training.id,
            title: training.title,
            completedSessions: 0,
            totalSessions: 0,
            progressPercentage: 0.0,
            lastAccessed: null,
          ));
          continue;
        }

        // Count completed sessions based on status and attendance
        int completedSessions = 0;

        for (var session in sessions) {
          bool isCompleted = false;

          // Check training status first
          if (fullTraining.status == 'completed' || fullTraining.status == 'cancelled') {
            isCompleted = true;
          } else {
            // Check session status and attendance
            final hasUserAttended = currentUserId != null && session.attendance.any((a) => a.userId == currentUserId);
            isCompleted = hasUserAttended || session.status == 'completed' || session.status == 'cancelled';
          }

          if (isCompleted) {
            completedSessions++;
          }
        }

        // Calculate progress percentage
        final progressPercentage = totalSessions > 0 ? (completedSessions / totalSessions) * 100.0 : 0.0;

        progressList.add(UserTrainingProgress(
          trainingId: training.id,
          title: training.title,
          completedSessions: completedSessions,
          totalSessions: totalSessions,
          progressPercentage: progressPercentage,
          lastAccessed: DateTime.now(), // TODO: Track actual last access time
        ));
      }

      return progressList;
    } catch (e) {
      print('Error calculating status-based progress: $e');
      return [];
    }
  }

  Future<void> refreshTodaySessions() async {
    await fetchTodaySessions();
  }

  Future<void> refreshUpcomingSessions() async {
    await fetchUpcomingSessions();
  }

  Future<void> refreshTrainingProgress() async {
    await fetchTrainingProgress();
  }

  Future<Map<String, dynamic>> joinSession(String trainingId, String sessionId) async {
    try {
      final result = await _apiService.joinSession(trainingId, sessionId);
      if (result['success'] == true) {
        // Refresh today's sessions and training progress to update status
        await fetchTodaySessions();
        await fetchTrainingProgress(); // Refresh progress after joining
      }
      return result;
    } catch (e) {
      errorMessage.value = e.toString();
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> leaveSession(String trainingId, String sessionId) async {
    try {
      final result = await _apiService.leaveSession(trainingId, sessionId);
      if (result['success'] == true) {
        // Refresh today's sessions to update status
        await fetchTodaySessions();
      }
      return result;
    } catch (e) {
      errorMessage.value = e.toString();
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/controller/training_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserTrainingController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var userTrainings = <TrainingModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadEnrolledTrainingIds();
    // fetchUserTrainings(); // Removed as endpoint does not exist
  }

  Future<void> _saveEnrolledTrainingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = userTrainings.map((t) => t.id).toList();
    await prefs.setStringList('enrolled_training_ids', ids);
  }

  Future<void> _loadEnrolledTrainingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('enrolled_training_ids') ?? [];
    // Create basic training models for cached IDs
    final cachedTrainings =
        ids
            .map(
              (id) => TrainingModel(
                id: id,
                title: 'Enrolled Training', // Placeholder
                description: '',
                learningTracks: [],
                targetAudience: [],
                learningOutcomes: [],
                courseOutline: [],
                sessions: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList();
    userTrainings.assignAll(cachedTrainings);
  }

  Future<void> fetchUserTrainings() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('Fetching user trainings...');
      final result = await _apiService.getUserTrainings();
      print('User trainings API response: $result');

      List<dynamic> trainingsList;
      if (result is List) {
        trainingsList = result as List<dynamic>;
      } else if (result['trainings'] is List) {
        trainingsList = result['trainings'] as List<dynamic>;
      } else if (result['data'] is List) {
        trainingsList = result['data'] as List<dynamic>;
      } else {
        trainingsList = [];
      }

      final basicTrainings =
          trainingsList.map((e) => TrainingModel.fromJson(e)).toList();

      // Assume all returned trainings are registered
      final registeredTrainings = basicTrainings;

      print(
        'Parsed ${basicTrainings.length} basic trainings, ${registeredTrainings.length} registered',
      );
      print('Basic training IDs: ${basicTrainings.map((t) => t.id).toList()}');
      print(
        'Registered training IDs: ${registeredTrainings.map((t) => t.id).toList()}',
      );

      // Fetch detailed data for each registered training
      List<TrainingModel> detailedTrainings = [];
      for (var training in registeredTrainings) {
        try {
          print('Fetching details for training: ${training.id}');
          final detailedResult = await _apiService.getUserTrainingDetails(
            training.id,
          );
          final detailedData =
              detailedResult['training'] ??
              detailedResult['data'] ??
              detailedResult;
          final userData =
              detailedResult['userData'] ?? detailedResult['user_data'];
          final detailedModel = TrainingModel.fromJson(detailedData);
          // Preserve the id from basic training since detailed API might not include it
          final mergedModel = TrainingModel(
            id: training.id.isNotEmpty ? training.id : detailedModel.id,
            title: detailedModel.title,
            description: detailedModel.description,
            learningTracks: detailedModel.learningTracks,
            targetAudience: detailedModel.targetAudience,
            learningOutcomes: detailedModel.learningOutcomes,
            courseOutline: detailedModel.courseOutline,
            sessions: detailedModel.sessions,
            createdAt: detailedModel.createdAt,
            updatedAt: detailedModel.updatedAt,
            registrationStatus: detailedModel.registrationStatus,
            progress: detailedModel.progress,
            trainer: detailedModel.trainer,
            endDate: detailedModel.endDate,
            analytics: detailedModel.analytics,
            startDate: detailedModel.startDate,
            status: detailedModel.status,
            userData: userData is Map<String, dynamic> ? userData : null,
          );
          detailedTrainings.add(mergedModel);
        } catch (e) {
          print('Failed to fetch details for training ${training.id}: $e');
          // If detailed fetch fails, use basic data
          detailedTrainings.add(training);
        }
      }

      print('Final user trainings count: ${detailedTrainings.length}');
      print(
        'Final training IDs: ${detailedTrainings.map((t) => t.id).toList()}',
      );
      userTrainings.assignAll(detailedTrainings);
      await _saveEnrolledTrainingIds();
    } catch (e) {
      print('Error fetching user trainings: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshUserTrainings() async {
    errorMessage.value = ''; // Clear any previous errors
    await fetchUserTrainings();
  }

  Future<bool> cancelTrainingRegistration(String trainingId) async {
    try {
      final success = await _apiService.cancelTrainingRegistration(trainingId);
      if (success) {
        // Refresh user trainings to remove the cancelled training
        await fetchUserTrainings();
      }
      return success;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }
}

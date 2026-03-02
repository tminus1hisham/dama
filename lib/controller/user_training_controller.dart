import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
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
  }

  Future<void> _saveEnrolledTrainingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = userTrainings.map((t) => t.id).toList();
    await prefs.setStringList('enrolled_training_ids', ids);
  }

  Future<void> _loadEnrolledTrainingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('enrolled_training_ids') ?? [];
    final cachedTrainings = ids
        .map(
          (id) => TrainingModel(
            id: id,
            title: 'Enrolled Training',
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

      print('Parsed ${basicTrainings.length} basic trainings');

      // Fetch detailed data for each training
      List<TrainingModel> detailedTrainings = [];
      for (var training in basicTrainings) {
        try {
          print('Fetching details for training: ${training.id}');
          final detailedResult =
              await _apiService.getUserTrainingDetails(training.id);

          final detailedData = detailedResult['training'] ??
              detailedResult['data'] ??
              detailedResult;

          // ✅ Extract userData — contains the user's real enrollment status & progress
          final userData = detailedResult['userData'] ??
              detailedResult['user_data'];

          final detailedModel = TrainingModel.fromJson(detailedData);

          // ✅ Read user's enrollment status from userData.enrollment.status
          final enrollment = userData != null
              ? userData['enrollment'] as Map<String, dynamic>?
              : null;

          // ✅ Read user's progress from userData.progress.attendanceRate
          final userProgressData = userData != null
              ? userData['progress'] as Map<String, dynamic>?
              : null;

          final userStatus = enrollment?['status'] as String?;

          // ✅ attendanceRate is num — convert to int to match TrainingModel.progress (int?)
          final userProgressValue =
              (userProgressData?['attendanceRate'] as num?)?.toInt();

          // ✅ Certificate info from userData.certificate
          final certData = userData != null
              ? userData['certificate'] as Map<String, dynamic>?
              : null;

          print(
              'Training ${training.id} → userStatus: $userStatus, userProgress: $userProgressValue');

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
            // ✅ User's attendance rate as progress, fallback to course progress
            progress: userProgressValue ?? detailedModel.progress,
            trainer: detailedModel.trainer,
            endDate: detailedModel.endDate,
            analytics: detailedModel.analytics,
            startDate: detailedModel.startDate,
            // ✅ User's enrollment status, fallback to course status
            status: userStatus ?? detailedModel.status,
            userData: userData is Map<String, dynamic> ? userData : null,
            category: detailedModel.category,
            // ✅ Build Certificate from userData.certificate if available
            certificate: certData != null
                ? Certificate(
                    issued: certData['issued'] == true,
                    certificateNumber:
                        detailedModel.certificate?.certificateNumber ??
                            certData['certificateNumber'] as String?,
                    issuedAt: certData['issuedAt'] != null
                        ? DateTime.tryParse(certData['issuedAt'].toString())
                        : null,
                    expiresAt: certData['expiresAt'] != null
                        ? DateTime.tryParse(certData['expiresAt'].toString())
                        : null,
                  )
                : detailedModel.certificate,
            certificateConfig: detailedModel.certificateConfig,
          );

          detailedTrainings.add(mergedModel);
        } catch (e) {
          print('Failed to fetch details for training ${training.id}: $e');
          // If detailed fetch fails, use basic data
          detailedTrainings.add(training);
        }
      }

      print('Final user trainings count: ${detailedTrainings.length}');
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
    errorMessage.value = '';
    await fetchUserTrainings();
  }

  Future<bool> cancelTrainingRegistration(String trainingId) async {
    try {
      final success =
          await _apiService.cancelTrainingRegistration(trainingId);
      if (success) {
        await fetchUserTrainings();
      }
      return success;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }
}
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class TrainingController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var trainings = <TrainingModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrainings();
  }

  Future<void> fetchTrainings() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _apiService.getTrainings();
      trainings.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTrainings() async {
    await fetchTrainings();
  }
}

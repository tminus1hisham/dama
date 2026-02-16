import 'package:get/get.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/models/rating_model.dart';

class RatingController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var success = false.obs;
  var errorMessage = ''.obs;

  Future<void> submitRating(String resourceID, RatingModel ratingModel) async {
    isLoading.value = true;
    errorMessage.value = '';
    success.value = false;

    try {
      await _apiService.rate(resourceID, ratingModel);
      success.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

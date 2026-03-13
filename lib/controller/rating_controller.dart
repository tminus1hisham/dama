import 'package:get/get.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/models/rating_model.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class RatingController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var success = false.obs;
  var errorMessage = ''.obs;
  var updatedAverageRating = Rxn<double>(); // Store the updated rating from API

  /// Submit rating and return the new average rating if available
  Future<double?> submitRating(
    String resourceID,
    RatingModel ratingModel,
  ) async {
    isLoading.value = true;
    errorMessage.value = '';
    success.value = false;
    updatedAverageRating.value = null;

    try {
      debugPrint(
        '[RatingController] Starting rating submission for resource: $resourceID',
      );
      final response = await _apiService.rate(resourceID, ratingModel);
      success.value = true;

      // Try to extract the updated average rating from response
      if (response != null) {
        debugPrint('[RatingController] API Response: $response');

        // Try different possible response formats
        final data = response['data'] ?? response;
        final newRating =
            data['averageRating'] ??
            data['average_rating'] ??
            data['rating'] ??
            data['resource']?['averageRating'] ??
            data['resource']?['average_rating'] ??
            data['newAverageRating'] ??
            data['new_average_rating'];

        if (newRating != null) {
          updatedAverageRating.value =
              (newRating is num)
                  ? newRating.toDouble()
                  : double.tryParse(newRating.toString());
          debugPrint(
            '[RatingController] Updated rating: ${updatedAverageRating.value}',
          );
        } else {
          debugPrint(
            '[RatingController] WARNING: No averageRating found in API response. '
            'Backend may not be returning the updated rating. Response keys: ${data.keys.toList()}',
          );
        }
      } else {
        debugPrint('[RatingController] WARNING: API response was null');
      }

      return updatedAverageRating.value;
    } catch (e) {
      debugPrint('[RatingController] Exception during rating submission: $e');
      String message = e.toString().replaceFirst('Exception: ', '');

      // Provide user-friendly error messages
      if (message.contains('Unauthorized') ||
          message.contains('authentication') ||
          message.contains('Session expired')) {
        errorMessage.value = 'Session expired. Please log in again.';
        // Force logout and redirect to login
        await _handleAuthenticationFailure();
      } else if (message.contains('Network')) {
        errorMessage.value = 'Network error. Please check your connection.';
      } else {
        errorMessage.value =
            message.isNotEmpty ? message : 'Failed to submit rating';
      }

      debugPrint(
        '[RatingController] Final error message: ${errorMessage.value}',
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear tokens and redirect to login when authentication fails
  Future<void> _handleAuthenticationFailure() async {
    try {
      debugPrint(
        '[RatingController] Handling authentication failure - clearing tokens and redirecting',
      );
      // Clear stored tokens
      await StorageService.removeData('access_token');
      await StorageService.removeData('refresh_token');
      await StorageService.removeData('userId');
      debugPrint('[RatingController] Tokens cleared');

      // Redirect to login
      Get.offAllNamed(AppRoutes.login);
      debugPrint('[RatingController] Redirected to login');
    } catch (e) {
      debugPrint('[RatingController] Error during auth failure handling: $e');
    }
  }
}

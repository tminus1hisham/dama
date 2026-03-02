import 'package:get/get.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/models/rating_model.dart';
import 'package:flutter/foundation.dart';

class RatingController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var success = false.obs;
  var errorMessage = ''.obs;
  var updatedAverageRating = Rxn<double>();  // Store the updated rating from API

  /// Submit rating and return the new average rating if available
  Future<double?> submitRating(String resourceID, RatingModel ratingModel) async {
    isLoading.value = true;
    errorMessage.value = '';
    success.value = false;
    updatedAverageRating.value = null;

    try {
      final response = await _apiService.rate(resourceID, ratingModel);
      success.value = true;
      
      // Try to extract the updated average rating from response
      if (response != null) {
        debugPrint('[RatingController] API Response: $response');
        
        // Try different possible response formats
        final data = response['data'] ?? response;
        final newRating = data['averageRating'] ?? 
                          data['average_rating'] ?? 
                          data['rating'] ??
                          data['resource']?['averageRating'] ??
                          data['resource']?['average_rating'] ??
                          data['newAverageRating'] ??
                          data['new_average_rating'];
        
        if (newRating != null) {
          updatedAverageRating.value = (newRating is num) 
              ? newRating.toDouble() 
              : double.tryParse(newRating.toString());
          debugPrint('[RatingController] Updated rating: ${updatedAverageRating.value}');
        } else {
          debugPrint('[RatingController] WARNING: No averageRating found in API response. '
                     'Backend may not be returning the updated rating. Response keys: ${data.keys.toList()}');
        }
      } else {
        debugPrint('[RatingController] WARNING: API response was null');
      }
      
      return updatedAverageRating.value;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:dama/models/verify_by_phone_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class VerifyByPhoneController extends GetxController {
  var isLoading = false.obs;
  var verificationResult = ''.obs;

  Future<int?> verifyByPhone(VerifyByPhoneModel request) async {
    try {
      isLoading.value = true;
      verificationResult.value = '';

      final statusCode = await ApiService().verifyByPhone(request);
      if (statusCode == 200) {
        verificationResult.value = "Verification successful!";
      } else if (statusCode == 400) {
        verificationResult.value = "Already verified!";
      } else {
        verificationResult.value = "Verification failed!";
      }
      return statusCode;
    } catch (e) {
      verificationResult.value = "Network error!";
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}

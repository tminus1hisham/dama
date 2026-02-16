import 'dart:convert';

import 'package:dama/models/verify_qr_code_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class VerifyQrCodeController extends GetxController {
  var isLoading = false.obs;
  var verificationResult = ''.obs;

  Future<int?> verifyQrCodeFromJsonString(String jsonString) async {
    try {
      isLoading.value = true;
      verificationResult.value = '';

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final verifyModel = VerifyQrCode.fromJson(jsonMap);

      final statusCode = await ApiService().verifyQrCode(verifyModel);
      return statusCode;
    } catch (e) {
      verificationResult.value = 'Invalid QR code or network error';
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}

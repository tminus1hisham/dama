import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dama/models/conversation_model.dart';
import 'package:dama/services/api_service.dart';

class ConversationsController extends GetxController {
  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxBool isLoading = false.obs;
  final ApiService _apiService = ApiService();

  Future<void> fetchUserConversations(String userId) async {
    isLoading.value = true;
    try {
      final data = await _apiService.fetchConversations(userId);

      if (data != null && data['conversations'] != null) {
        final convList = data['conversations'] as List;

        conversations.assignAll(
          convList.map((e) => ConversationModel.fromJson(e)).toList(),
        );
      }
    } catch (e, stackTrace) {
      // Don't show snackbar here - it causes issues if context isn't ready
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> startConversation(String user1, String user2) async {
    try {
      return await _apiService.startConversation(user1, user2);
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to start conversation",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return null;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final success = await _apiService.deleteConversation(conversationId);
      if (success) {
        conversations.removeWhere((c) => c.id == conversationId);
      }
      return success;
    } catch (e) {
      Get.snackbar(
        margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to delete conversation",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return false;
    }
  }
}
